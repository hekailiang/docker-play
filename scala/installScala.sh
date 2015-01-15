#!/bin/sh
 
# one way (older scala version will be installed)
# sudo apt-get install scala
 
#2nd way
sudo apt-get remove scala-library scala
wget http://www.scala-lang.org/files/archive/scala-2.11.4.deb
sudo dpkg -i scala-2.11.4.deb
sudo apt-get update
sudo apt-get install scala
 
# sbt installation
# remove sbt:>  sudo apt-get purge sbt.
 
wget http://dl.bintray.com/sbt/debian/sbt-0.13.6.deb
sudo dpkg -i sbt-0.13.6.deb 
sudo apt-get update
sudo apt-get install sbt