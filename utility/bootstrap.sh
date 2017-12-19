#!/bin/bash

[[ "TRACE" ]] && set -x

: ${HDFS:=hdfs-master}
: ${HIVE:=hive}
: ${SPARK:=spark}
: ${OOZIE:=oozie}

 ip_addr=`/sbin/ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

startSsh() {
 echo -e "Starting SSHD service"
 /usr/sbin/sshd
}

setEnvVariable() {
 fqdn=$(hostname -f)
 export SCALA_HOME="/usr/local/scala"
 export PATH="$PATH:$SCALA_HOME/bin"
 export PATH="$PATH:/usr/local/spark/bin" 
 export SPARK_HOME=/usr/local/spark 
 
 echo 'export SCALA_HOME=/usr/local/scala' >> /etc/bash.bashrc
 echo 'export PATH=$PATH:$SCALA_HOME/bin' >> /etc/bash.bashrc
 echo 'export PATH=$PATH:/usr/local/spark/bin' >> /etc/bash.bashrc
 echo 'export SPARK_HOME=/usr/local/spark' >> /etc/bash.bashrc
 echo 'export _JAVA_OPTIONS=-Xmx2048m' >> /etc/bash.bashrc

 echo 'echo "1. Run => /usr/local/livy/bin/livy-server start"' >> /etc/bash.bashrc
 cp /usr/local/spark/conf/spark-env.sh.template /usr/local/spark/conf/spark-env.sh
 chmod +x /usr/local/spark/conf/spark-env.sh
echo -e "SPARK_HISTORY_OPTS=\"-Dspark.history.kerberos.enabled=true \
-Dspark.history.kerberos.principal=spark/$fqdn@CLOUD.COM \
-Dspark.history.kerberos.keytab=/etc/security/keytabs/spark.keytab\"\n \
export SPARK_LOG_DIR=/var/log/spark\n \
export SPARK_PID_DIR=/var/run/spark" >> /usr/local/spark/conf/spark-env.sh

mkdir -p /var/log/spark
mkdir -p /var/run/spark

 cp /usr/local/livy/conf/livy.conf.template /usr/local/livy/conf/livy.conf
echo "livy.server.auth.kerberos.keytab /etc/security/keytabs/livy.keytab
livy.server.auth.kerberos.principal HTTP/_HOST@CLOUD.COM
livy.server.auth.type kerberos
livy.server.launch.kerberos.keytab /etc/security/keytabs/livy.keytab
livy.server.launch.kerberos.principal livy/_HOST@CLOUD.COM" >> /usr/local/livy/conf/livy.conf
}

changeOwner() {
 chown -R root:hadoop /usr/local/hive
}

initializePrincipal() {
 kadmin -p root/admin -w admin -q "addprinc -randkey spark/$(hostname -f)@CLOUD.COM"
 
 kadmin -p root/admin -w admin -q "xst -k spark.keytab spark/$(hostname -f)@CLOUD.COM"
 
 kadmin -p root/admin -w admin -q "addprinc -randkey livy/$(hostname -f)@CLOUD.COM"
 kadmin -p root/admin -w admin -q "addprinc -randkey HTTP/$(hostname -f)@CLOUD.COM"
 kadmin -p root/admin -w admin -q "xst -k livy.keytab livy/$(hostname -f)@CLOUD.COM HTTP/$(hostname -f)@CLOUD.COM"



 mkdir -p /etc/security/keytabs
 mv spark.keytab /etc/security/keytabs
 chmod 400 /etc/security/keytabs/spark.keytab
 chown root:hadoop /etc/security/keytabs/spark.keytab
 mv livy.keytab /etc/security/keytabs
 chmod 400 /etc/security/keytabs/livy.keytab
 chown root:hadoop /etc/security/keytabs/livy.keytab

kinit -k -t /etc/security/keytabs/spark.keytab spark/$(hostname -f)
su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -mkdir -p /user/spark"
su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chown spark:spark /user/spark"
su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chown spark:spark /user/spark"
su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -mkdir /spark-history"
su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chown -R spark:hadoop /spark-history"
su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chmod -R 777 /spark-history" 

}


startLivyServer() {
 /usr/local/livy/bin/livy-server start
}

deamon() {
  while true; do sleep 1000; done
}

bashPrompt() {
 /bin/bash
}

sshPromt() {
 /usr/sbin/sshd -D
}

initialize() {
 startLivyServer
}

main() {
 if [ ! -f /spark_initialized ]; then
    /utility/ldap/bootstrap.sh
    startSsh
    initializePrincipal
    #changeOwner
    setEnvVariable
    initialize
    touch /spark_initialized
  else
    startSsh
    initialize
  fi
  if [[ $1 == "-d" ]]; then
   deamon
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
