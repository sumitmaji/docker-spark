#!/bin/bash


#Install Scala
tar -xzvf /container/scala-2.10.4.tgz -C /usr/local/
mv /usr/local/scala-2.10.4 /usr/local/scala
rm -rf /container/scala-2.10.4.tgz
chown -R hduser:hadoop /usr/local/scala

#Scala Environemtn Setup
export SCALA_HOME="/usr/local/scala"
export PATH="$PATH:$SCALA_HOME/bin"

echo 'export SCALA_HOME=/usr/local/scala' >> /home/hduser/.bashrc
echo 'export PATH=$PATH:$SCALA_HOME/bin' >> /home/hduser/.bashrc
#RUN scala -version


#Install Spark
tar -xzvf /container/spark-1.6.1-bin-hadoop2.4.tgz -C /usr/local/
mv /usr/local/spark-1.6.1-bin-hadoop2.4 /usr/local/spark
rm -rf /container/spark-1.6.1-bin-hadoop2.4.tgz
chown -R hduser:hadoop /usr/local/spark

export PATH="$PATH:/usr/local/spark/bin"

echo 'export PATH=$PATH:/usr/local/spark/bin' >> /home/hduser/.bashrc
