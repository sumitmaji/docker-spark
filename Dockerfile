FROM sumit/hadoop
MAINTAINER Sumit Kumar Maji

RUN apt-get update \
        && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes --no-install-recommends \
        zip unzip \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


WORKDIR /usr/local/
ARG REPOSITORY_HOST

#Install Scala, Spark & livy
RUN wget "$REPOSITORY_HOST"/repo/scala-2.10.4.tgz &&\
tar -xzvf /usr/local/scala-2.10.4.tgz &&\
mv /usr/local/scala-2.10.4 /usr/local/scala &&\
rm -rf /usr/local/scala-2.10.4.tgz &&\
chown -R root:hadoop /usr/local/scala &&\
wget "$REPOSITORY_HOST"/repo/spark-1.6.1-bin-hadoop2.4.tgz &&\
tar -xzvf /usr/local/spark-1.6.1-bin-hadoop2.4.tgz &&\
mv /usr/local/spark-1.6.1-bin-hadoop2.4 /usr/local/spark &&\
rm -rf /usr/local/spark-1.6.1-bin-hadoop2.4.tgz &&\
chown -R root:hadoop /usr/local/spark &&\
wget "$REPOSITORY_HOST"/repo/livy-0.4.0-incubating-bin.zip &&\
unzip /usr/local/livy-0.4.0-incubating-bin.zip &&\
mv /usr/local/livy-0.4.0-incubating-bin /usr/local/livy &&\
rm -rf /usr/local/livy-0.4.0-incubating-bin.zip &&\
chown -R root:hadoop /usr/local/livy

ENV SPARK_HOME /usr/local/spark
ENV SCALA_HOME /usr/local/scala
ENV PATH $PATH:$SCALA_HOME/bin
ENV PATH $PATH:/usr/local/spark/bin

#RUN scala -version
RUN mkdir -p /utility/spark
ADD utility/bootstrap.sh /utility/spark/bootstrap.sh
RUN chmod +x /utility/spark/bootstrap.sh
RUN chown root:root /utility/spark/bootstrap.sh

#Expose livy server port
EXPOSE 8998
ENTRYPOINT ["/utility/spark/bootstrap.sh"]

