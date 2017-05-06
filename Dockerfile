FROM sumit/hadoop:latest
MAINTAINER Sumit Kumar Maji

ADD . /container/

#Scala Environemtn Setup
ENV SCALA_HOME /usr/local/scala
ENV PATH $PATH:$SCALA_HOME/bin

ENV PATH $PATH:/usr/local/spark/bin

RUN /container/setup.sh

CMD /usr/sbin/sshd -D

