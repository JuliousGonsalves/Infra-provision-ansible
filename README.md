## Description

Here we are going to provision an aws infrastructure using Ansible and host a simple html site.
By using ansible, we will creare ssh-key pair, Security groups and Ec2-instance.
Html site will be added using user data.

## Preparing the Master server

#### Installing ansible
~~~sh
amazon-linux-extras install ansible2 -y

ansible --version  
~~~
#### If amazon.aws collection  is not included in ansible-core , You can install the module by following command
~~~sh
ansible-galaxy collection install amazon.aws
~~~
##### Note: The above amazon.aws module will only work if the server met the following conditions,

python >= 3.6, 
boto3 >= 1.15.0, 
botocore >= 1.18.0

#### Using below commands you can add the needed packages.
~~~sh
yum install python3 -y

yum install python3-pip -y

pip3 install boto &> /dev/null

pip3 install boto3 &> /dev/null
~~~ 
We will need to add a programtic access so that the python modules can make api calls to aws. You can use aws profile instead of providing aws access and secret key into the playbook.

#### Configuring AWS profile in the instance
~~~sh
aws configure --profile <profile name>
AWS Access Key ID [None]: 
AWS Secret Access Key [None]: 
Default region name [None]: 
Default output format [None]: 
~~~  
We have successfully configured the basic requirements in the master server, Now lest create the ansible playbook for the infra provisioning and site hosting.
  
#### Inventory - hosts
~~~sh  
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
~~~ 
##### Note : amazon.aws module need python3 as interpreter.

#### User data - userdata.sh
~~~sh  
#!/bin/bash

yum install httpd php -y

cd /var/www/html

wget https://www.tooplate.com/zip-templates/2123_simply_amazed.zip

unzip 2123_simply_amazed.zip

cd 2123_simply_amazed/

mv * ../

cd ../

chown apache. * -R

rm -rf 2123_simply_amazed 2123_simply_amazed.zip
  
service httpd restart

chkconfig httpd on
~~~
##### Note: From tooplate.com , you can download free html sites. 


#### Playbook - ec2-provision-html.yml
~~~sh   
---

- name: "AWS infrastructure creation using Ansible"
  hosts: localhost
  vars:
    aws_profile: "<profile-name>"
    region: "ap-south-1"
    project: "<add the project name>"
    instance_type : "t2.micro"
    ami_id: "ami-0e0ff68cb8e9a188a"

  tasks:
    - name: "Creating ec2-key pair"
      amazon.aws.ec2_key:
        profile: "{{aws_profile}}"
        region: "{{region}}"
        name: "{{project}}"
        state: present
        tags:
          Name: "{{project}}"
          project: "{{project}}"

      register: key_status

    - name: "making a copy of private key in local machine"
      when: key_status.changed == true
      copy:
        content: "{{key_status.key.private_key}}"
        dest: "{{project}}.pem"
        mode: 0400

    - name: "Security group for webserver to allow 80.443"
      amazon.aws.ec2_group:
        name: "{{project}}-webserver"
        description: "SG to allow ports 80,443 for webserver"
        profile: "{{aws_profile}}"
        region: "{{region}}"
        rules:
          - proto: tcp
            from_port: 80
            to_port: 80
            cidr_ip: 0.0.0.0/0
            rule_desc: allow all on port 80
          - proto: tcp
            from_port: 443
            to_port: 443
            cidr_ip: 0.0.0.0/0
            rule_desc: allow all on port 443


        tags:
          Name: "{{project}}-webserver"
          project: "{{project}}"

      register: webserver

    - name: "Security group for webserver to allow 22 for ssh"
      amazon.aws.ec2_group:
        name: "{{project}}-ssh"
        description: "SG to allow ports 22 for webserver"
        profile: "{{aws_profile}}"
        region: "{{region}}"
        rules:
          - proto: tcp
            from_port: 22
            to_port: 22
            cidr_ip: 0.0.0.0/0
            rule_desc: allow all on port 22

        tags:
          Name: "{{project}}-ssh"
          project: "{{project}}"

      register: ssh
  
    - name: "Creating Ec-2 Instance for webserver"
      amazon.aws.ec2:
        profile: "{{aws_profile}}"
        region: "{{region}}"
        key_name: "{{key_status.key.name}}"
        instance_type: "{{instance_type}}"
        image: "{{ami_id}}"
        user_data: "{{ lookup('file', 'userdata.sh') }}"
        group_id:
          - "{{ webserver.group_id }}"
          - "{{ ssh.group_id }}"
        wait: yes
        instance_tags:
          Name: "{{project}}-webserver"
          project: "{{project}}"

        count_tag:
          project: "{{project}}"
        exact_count: 1
~~~
  
### Syntax check
~~~sh  
ansible-playbook -i hosts ec2-provision-html.yml --syntax-check
~~~
### Running the Playbook
~~~sh   
ansible-playbook -i hosts ec2-provision-html.yml 
~~~

## Conclusion
 
A Html site is will be added in the provioned ec2-instance.

#### Playbook run output

![result](https://user-images.githubusercontent.com/98936958/157897374-c8a04d28-2b9b-4a5b-a644-46996f4c4d11.PNG)

#### HTML Website

![output](https://user-images.githubusercontent.com/98936958/157893383-5d8e3e0c-cb2e-49d1-85fa-5a84dc095693.PNG)


