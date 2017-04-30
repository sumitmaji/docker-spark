FROM sumit/hadoop:latest
MAINTAINER Sumit Kumar Maji

RUN apt-get update && apt-get install -y git

#Install Scala
COPY scala-2.10.4.tgz /usr/local/scala-2.10.4.tgz
RUN tar -xzvf /usr/local/scala-2.10.4.tgz -C /usr/local/
RUN mv /usr/local/scala-2.10.4 /usr/local/scala
RUN rm -rf /usr/local/scala-2.10.4.tgz
RUN chown -R hduser:hadoop /usr/local/scala

#Scala Environemtn Setup
ENV SCALA_HOME /usr/local/scala
ENV PATH $PATH:$SCALA_HOME/bin

RUN echo 'export SCALA_HOME=/usr/local/scala' >> /home/hduser/.bashrc
RUN echo 'export PATH=$PATH:$SCALA_HOME/bin' >> /home/hduser/.bashrc
#RUN scala -version


#Install Spark
COPY spark-1.6.1-bin-hadoop2.4.tgz /usr/local/spark-1.6.1-bin-hadoop2.4.tgz
RUN tar -xzvf /usr/local/spark-1.6.1-bin-hadoop2.4.tgz -C /usr/local/
RUN mv /usr/local/spark-1.6.1-bin-hadoop2.4 /usr/local/spark
RUN rm -rf /usr/local/spark-1.6.1-bin-hadoop2.4.tgz
RUN chown -R hduser:hadoop /usr/local/spark

ENV PATH $PATH:/usr/local/spark/bin

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown hduser:hadoop /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh
RUN su - hduser -c "echo 'export BOOTSTRAP=/etc/bootstrap.sh' >> /home/hduser/.bashrc"

RUN apt-get update & apt-get install -y net-tools


CMD /usr/sbin/sshd -D

