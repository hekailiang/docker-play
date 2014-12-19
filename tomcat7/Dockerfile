FROM hekailiang/base
MAINTAINER Henry He <hekailiang@gmail.com>

RUN apt-get -y install tomcat7
RUN echo "JAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /etc/default/tomcat7
RUN echo "TOMCAT_HOME=/var/lib/tomcat7" >> ~/.bashrc

ADD run.sh /var/lib/tomcat7/run.sh
RUN chmod +x /var/lib/tomcat7/run.sh

EXPOSE 8080
ENTRYPOINT ["/var/lib/tomcat7/run.sh"]
