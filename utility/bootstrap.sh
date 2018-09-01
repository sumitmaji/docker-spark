#!/bin/bash

[[ "TRACE" ]] && set -x

# Directory to find config artifacts
CONFIG_DIR="/tmp/spark-config"

mkdir -p /root/hdfs/sparknode
chwon -R root:hadoop /root/hdfs

source ${CONFIG_DIR}/config

: ${HADOOP_PREFIX:=/usr/local/hadoop}
: ${DOMAIN_NAME:=cloud.com}
: ${DOMAIN_REALM:=$DOMAIN_NAME}
: ${ENABLE_KERBEROS:=false}
: ${REALM:=$(echo $DOMAIN_NAME | tr 'a-z' 'A-Z')}
: ${HADOOP_INSTALL:=/usr/local/hadoop}
: ${SPARK_HOME:=/usr/local/spark}
# Copy config files from volume mount

for f in slaves core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml httpfs-site.xml; do
  if [[ -e ${CONFIG_DIR}/$f ]]; then
    cp ${CONFIG_DIR}/$f $HADOOP_PREFIX/etc/hadoop/$f
  else
    echo "ERROR: Could not find $f in $CONFIG_DIR"
    exit 1
  fi
done

cp ${CONFIG_DIR}/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf

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
  export HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop
  export YARN_CONF_DIR=$HADOOP_PREFIX/etc/hadoop

  echo 'export SCALA_HOME=/usr/local/scala' >>/etc/bash.bashrc
  echo 'export PATH=$PATH:$SCALA_HOME/bin' >>/etc/bash.bashrc
  echo 'export PATH=$PATH:/usr/local/spark/bin' >>/etc/bash.bashrc
  echo 'export SPARK_HOME=/usr/local/spark' >>/etc/bash.bashrc
  echo 'export _JAVA_OPTIONS=-Xmx2048m' >>/etc/bash.bashrc
  #echo 'export HADOOP_CONF_DIR="$HADOOP_PREFIX"/etc/hadoop' >>/etc/bash.bashrc
  echo 'export YARN_CONF_DIR=$HADOOP_PREFIX/etc/hadoop' >>/etc/bash.bashrc

  echo 'export JAVA_HOME=/usr/local/jdk' >>/etc/bash.bashrc
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >>/etc/bash.bashrc
  echo 'export HADOOP_INSTALL=/usr/local/hadoop' >>/etc/bash.bashrc
  echo 'export PATH=$PATH:$HADOOP_INSTALL/bin' >>/etc/bash.bashrc
  echo 'export PATH=$PATH:$HADOOP_INSTALL/sbin' >>/etc/bash.bashrc
  echo 'export HADOOP_MAPRED_HOME=$HADOOP_INSTALL' >>/etc/bash.bashrc
  echo 'export HADOOP_COMMON_HOME=$HADOOP_INSTALL' >>/etc/bash.bashrc
  echo 'export HADOOP_HDFS_HOME=$HADOOP_INSTALL' >>/etc/bash.bashrc
  echo 'export YARN_HOME=$HADOOP_INSTALL' >>/etc/bash.bashrc
  echo 'export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_INSTALL/lib/native' >>/etc/bash.bashrc
  echo 'export HADOOP_OPTS="-Djava.library.path=$HADOOP_INSTALL/lib/native"' >>/etc/bash.bashrc
  echo 'export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop' >>/etc/bash.bashrc
  echo 'export LD_LIBRARY_PATH=/usr/local/lib:$HADOOP_INSTALL/lib/native:$LD_LIBRARY_PATH' >>/etc/bash.bashrc

  echo 'echo "1. Run => /usr/local/livy/bin/livy-server start"' >>/etc/bash.bashrc
  cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh
  chmod +x $SPARK_HOME/conf/spark-env.sh

  echo -e "export SPARK_LOG_DIR=/var/log/spark\n \
  export SPARK_PID_DIR=/var/run/spark" >>$SPARK_HOME/conf/spark-env.sh

  cp /usr/local/livy/conf/livy.conf.template /usr/local/livy/conf/livy.conf

  if [ "$ENABLE_KERBEROS" == 'true' ]; then
    echo -e "SPARK_HISTORY_OPTS=\"-Dspark.history.kerberos.enabled=true \
-Dspark.history.kerberos.principal=spark/$(hostname -f)@$REALM \
-Dspark.history.kerberos.keytab=/etc/security/keytabs/spark.keytab\"\n" >>$SPARK_HOME/conf/spark-env.sh

    echo "livy.server.auth.kerberos.keytab /etc/security/keytabs/livy.keytab
livy.server.auth.kerberos.principal HTTP/_HOST@$REALM
livy.server.auth.type kerberos
livy.server.launch.kerberos.keytab /etc/security/keytabs/livy.keytab
livy.server.launch.kerberos.principal livy/_HOST@$REALM" >>/usr/local/livy/conf/livy.conf
    kerberizeNameNodeSerice
    kerberizeSecondaryNamenodeService
    kerberizeDataNodeService
    kerberizeYarnService
    kerberizeHttpfsService
    sedFile /usr/local/hadoop/etc/hadoop/core-site.xml
    sedFile /usr/local/hadoop/etc/hadoop/hdfs-site.xml
    sedFile /usr/local/hadoop/etc/hadoop/mapred-site.xml
    sedFile /usr/local/hadoop/etc/hadoop/yarn-site.xml
    sedFile /usr/local/hadoop/etc/hadoop/httpfs-site.xml

  fi

  mkdir -p /var/log/spark
  mkdir -p /var/run/spark
  chown -R root:hadoop /var/log/spark
  chown -R root:hadoop /var/run/spark
}

kerberizeHttpfsService() {
  /bin/bash /tmp/spark-config/kerberizeHttpfs.sh /usr/local/hadoop/etc/hadoop/httpfs-site.xml
}

enableSslService() {
  /bin/bash /tmp/spark-config/enableSSL.sh /usr/local/hadoop/etc/hadoop/core-site.xml
  /bin/bash /tmp/spark-config/enableSSL.sh /usr/local/hadoop/etc/hadoop/hdfs-site.xml
  /bin/bash /tmp/spark-config/enableSSL.sh /usr/local/hadoop/etc/hadoop/mapred-site.xml
  #On secure datanodes, user to run the datanode as after dropping privileges
}

kerberizeNameNodeSerice() {

  /bin/bash /tmp/spark-config/kerberizeNamenode.sh /usr/local/hadoop/etc/hadoop/core-site.xml
  /bin/bash /tmp/spark-config/kerberizeNamenode.sh /usr/local/hadoop/etc/hadoop/hdfs-site.xml
}

kerberizeSecondaryNamenodeService() {
  /bin/bash /tmp/spark-config/kerberizeSecondarynode.sh /usr/local/hadoop/etc/hadoop/hdfs-site.xml
}

kerberizeDataNodeService() {
  /bin/bash /tmp/spark-config/kerberizeDatanode.sh /usr/local/hadoop/etc/hadoop/hdfs-site.xml
}

kerberizeYarnService() {
  /bin/bash /tmp/spark-config/kerberizeYarn.sh /usr/local/hadoop/etc/hadoop/mapred-site.xml
  /bin/bash /tmp/spark-config/kerberizeYarn.sh /usr/local/hadoop/etc/hadoop/yarn-site.xml
  echo 'yarn.nodemanager.linux-container-executor.group=hadoop
      banned.users=bin
      min.user.id=500
      allowed.system.users=hduser' >$HADOOP_INSTALL/etc/hadoop/container-executor.cfg
  chmod 050 /usr/local/hadoop/bin/container-executor
  chmod u+s /usr/local/hadoop/bin/container-executor
  chmod g+s /usr/local/hadoop/bin/container-executor
  ls -ltr "$HADOOP_INSTALL"/bin/
  su - root -c "$HADOOP_INSTALL/bin/container-executor"
}

sedFile() {
  filename=$1
  PRIV1=1006
  PRIV2=1019
  if [ "$ENABLE_HADOOP_SSL" == 'true' ]; then
    PRIV1=50020
    PRIV2=50010
  fi
  #sed -i "s/\$NAME_SERVER/$NAME_SERVER/" $filename
  #sed -i "s/\$HDFS_MASTER/$HDFS_MASTER/" $filename value is read directly from helm
  sed -i "s/\$PRIV1/$PRIV1/" $filename
  sed -i "s/\$PRIV2/$PRIV2/" $filename
  sed -i "s/\$REALM/$REALM/" $filename
  #sed -i "s/_HOST/$(hostname -f)/g" $filename
  #sed -i "s/HOSTNAME/$HDFS_MASTER/" $filename
  sed -i "s/DOMAIN_JKS/$keyfile/" $filename
  sed -i "s/JKS_KEY_PASSWORD/$KEY_PWD/" $filename
}

initializePrincipal() {
  kadmin -p root/admin -w admin -q "addprinc -randkey spark/$(hostname -f)@$REALM"

  kadmin -p root/admin -w admin -q "xst -k spark.keytab spark/$(hostname -f)@$REALM"

  kadmin -p root/admin -w admin -q "addprinc -randkey livy/$(hostname -f)@$REALM"
  kadmin -p root/admin -w admin -q "addprinc -randkey HTTP/$(hostname -f)@$REALM"
  kadmin -p root/admin -w admin -q "xst -k livy.keytab livy/$(hostname -f)@$REALM HTTP/$(hostname -f)@$REALM"

  mkdir -p /etc/security/keytabs
  mv spark.keytab /etc/security/keytabs
  chmod 400 /etc/security/keytabs/spark.keytab
  chown root:hadoop /etc/security/keytabs/spark.keytab
  mv livy.keytab /etc/security/keytabs
  chmod 400 /etc/security/keytabs/livy.keytab
  chown root:hadoop /etc/security/keytabs/livy.keytab

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
  #startLivyServer
  su - root -c "$HADOOP_INSTALL/etc/hadoop/hadoop-env.sh"
  kinit -k -t /etc/security/keytabs/spark.keytab spark/$(hostname -f)
  su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -mkdir -p /user/spark"
  su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chown spark:spark /user/spark"
  su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chown spark:spark /user/spark"
  su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -mkdir /spark-history"
  su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chown -R spark:hadoop /spark-history"
  su - root -c "$HADOOP_INSTALL/bin/hdfs dfs -chmod -R 777 /spark-history"
}

main() {
  if [ ! -f /spark_initialized ]; then
    sed -i '/ENABLE_KUBERNETES/d' /config
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
