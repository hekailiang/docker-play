FROM hekailiang/jdk7
MAINTAINER Henry He <hekailiang@gmail.com>

RUN add-apt-repository -y ppa:cwchien/gradle
RUN apt-get update && apt-get -y install git gradle maven supervisor curl dialog nano wget 
RUN apt-get install -y scala #groovy