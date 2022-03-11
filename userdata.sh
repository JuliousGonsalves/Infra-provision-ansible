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

