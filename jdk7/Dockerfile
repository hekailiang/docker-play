FROM ubuntu:14.04
MAINTAINER Henry He <hekailiang@gmail.com>

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get update && apt-get install -y -q software-properties-common python-software-properties
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update && apt-get -y upgrade

RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java7-installer && apt-get clean
RUN update-alternatives --display java

RUN echo "JAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /etc/environment