#!/bin/bash


#Install Scala
wget "$REPOSITORY_HOST"/repo/scala-2.10.4.tgz
tar -xzvf /usr/local/scala-2.10.4.tgz
mv /usr/local/scala-2.10.4 /usr/local/scala
rm -rf /usr/local/scala-2.10.4.tgz
chown -R hduser:hadoop /usr/local/scala

#Scala Environemtn Setup
export SCALA_HOME="/usr/local/scala"
export PATH="$PATH:$SCALA_HOME/bin"

echo 'export SCALA_HOME=/usr/local/scala' >> /home/hduser/.bashrc
echo 'export PATH=$PATH:$SCALA_HOME/bin' >> /home/hduser/.bashrc
#RUN scala -version


#Install Spark
wget "$REPOSITORY_HOST"/repo/spark-1.6.1-bin-hadoop2.4.tgz
tar -xzvf /usr/local/spark-1.6.1-bin-hadoop2.4.tgz
mv /usr/local/spark-1.6.1-bin-hadoop2.4 /usr/local/spark
rm -rf /usr/local/spark-1.6.1-bin-hadoop2.4.tgz
chown -R hduser:hadoop /usr/local/spark
echo 'export SPARK_HOME=/usr/local/spark' >> /home/hduser/.bashrc
export SPARK_HOME=/usr/local/spark

#install livy
wget "$REPOSITORY_HOST"/repo/livy-0.4.0-incubating-bin.zip
unzip /usr/local/livy-0.4.0-incubating-bin.zip
mv /usr/local/livy-0.4.0-incubating-bin /usr/local/livy
rm -rf /usr/local/livy-0.4.0-incubating-bin.zip
chown -R hduser:hadoop /usr/local/livy

export PATH="$PATH:/usr/local/spark/bin"

echo 'export PATH=$PATH:/usr/local/spark/bin' >> /home/hduser/.bashrc
echo 'echo "1. Run => /usr/local/livy/bin/livy-server start"' >> /home/hduser/.bashrc
