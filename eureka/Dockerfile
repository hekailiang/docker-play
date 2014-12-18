FROM hekailiang/jdk7
MAINTAINER Henry He <hekailiang@gmail.com>

RUN add-apt-repository -y ppa:cwchien/gradle

# install tomcat:7/git/gradle
RUN apt-get update && apt-get -y install tomcat7 git gradle
RUN echo "JAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /etc/default/tomcat7

# clone the eureka project
RUN git clone https://github.com/Netflix/eureka

# switch into eureka to run gradle
WORKDIR eureka

# build the eureka project
RUN ./gradlew clean build

# copy the war to the tomcat directory
RUN cp /eureka/eureka-server/build/libs/eureka-server-*.war /var/lib/tomcat7/webapps/eureka-server.war 

# start tomcat
EXPOSE 8080
CMD service tomcat7 start && tail -f /var/log/tomcat7/catalina.out
