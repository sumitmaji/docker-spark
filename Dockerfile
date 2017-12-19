FROM sumit/hadoop
MAINTAINER Sumit Kumar Maji

RUN apt-get update \
        && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes --no-install-recommends \
        zip unzip \
	python-setuptools \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget --no-check-certificate https://bootstrap.pypa.io/ez_setup.py &&\
python ez_setup.py --insecure

WORKDIR /usr/local/
ARG REPOSITORY_HOST

#Install Scala, Spark & livy
RUN wget "$REPOSITORY_HOST"/repo/scala-2.11.8.tgz &&\
tar -xzvf /usr/local/scala-2.11.8.tgz &&\
mv /usr/local/scala-2.11.8 /usr/local/scala &&\
rm -rf /usr/local/scala-2.11.8.tgz &&\
chown -R root:hadoop /usr/local/scala &&\
wget "$REPOSITORY_HOST"/repo/spark-2.2.0-bin-hadoop2.7.tgz &&\
tar -xzvf /usr/local/spark-2.2.0-bin-hadoop2.7.tgz &&\
mv /usr/local/spark-2.2.0-bin-hadoop2.7 /usr/local/spark &&\
rm -rf /usr/local/spark-2.2.0-bin-hadoop2.7.tgz &&\
chown -R root:hadoop /usr/local/spark &&\
wget "$REPOSITORY_HOST"/repo/livy-spark-2.0.0.tar.gz &&\
tar -xzvf /usr/local/livy-spark-2.0.0.tar.gz &&\
rm -rf /usr/local/livy-spark-2.0.0.tar.gz &&\
chown -R root:hadoop /usr/local/livy


ENV SPARK_HOME /usr/local/spark
ENV SCALA_HOME /usr/local/scala
ENV PATH $PATH:$SCALA_HOME/bin
ENV PATH $PATH:/usr/local/spark/bin
ENV _JAVA_OPTIONS -Xmx2048m

#ADD config/hive-site.xml /usr/local/spark/conf/hive-site.xml
#ADD config/spark-defaults.conf /usr/local/spark/conf/spark-defaults.conf
#ADD config/spark-thrift-sparkconf.conf /usr/local/spark/conf/spark-thrift-sparkconf.conf

#RUN scala -version
RUN mkdir -p /utility/spark
ADD utility/bootstrap.sh /utility/spark/bootstrap.sh
RUN chmod +x /utility/spark/bootstrap.sh
RUN chown root:root /utility/spark/bootstrap.sh

#Expose livy server port
EXPOSE 8998
ENTRYPOINT ["/utility/spark/bootstrap.sh"]

