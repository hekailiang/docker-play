#!/bin/sh
service tomcat7 restart
tail -f /var/log/tomcat7/catalina.out
