FROM master.cloud.com:5000/hadoop
MAINTAINER Sumit Kumar Maji

RUN apt-get update \
        && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes --no-install-recommends \
        zip unzip \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


ADD . /container/
WORKDIR /usr/local/
ARG REPOSITORY_HOST

#Scala Environment Setup
ENV SCALA_HOME /usr/local/scala
ENV PATH $PATH:$SCALA_HOME/bin

ENV PATH $PATH:/usr/local/spark/bin

RUN /container/setup.sh

#Expose livy server port
EXPOSE 8998

CMD /usr/sbin/sshd -D

