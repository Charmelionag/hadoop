FROM ubuntu
MAINTAINER Iurie Muradu "muradu.iurie.1986@gmail.com"

# Installs and copies
RUN apt update && apt install -y wget ssh vim openjdk-8-jdk iputils-ping
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-2.6.5/hadoop-2.6.5.tar.gz
RUN tar -xzvf hadoop-2.6.5.tar.gz
RUN mv hadoop-2.6.5 /root/hadoop
RUN rm hadoop-2.6.5.tar.gz
COPY hadoop_key /root/.ssh/id_rsa
COPY hadoop_key.pub /root/.ssh/id_rsa.pub

# Keygen and passwordless connection
RUN touch /root/.ssh/authorized_keys && cat /root/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN echo "Host localhost\n\
\tHostName 127.0.0.1\n\
\tStrictHostKeyChecking no\n\
\nHost 0.0.0.0\n\
\tHostName 0.0.0.0\n\
\tStrictHostKeyChecking no\n\
\nHost namenode\n\
\tHostName 172.18.0.10\n\
\tStrictHostKeyChecking no\n\
\nHost datanode01\n\
\tHostName 172.18.11\n\
\tStrictHostKeyChecking no\n\
\nHost datanode02\n\
\tHostName 172.18.0.12\n\
\tStrictHostKeyChecking no" | tee /root/.ssh/config
RUN sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Configurations
# System
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" | tee -a /root/.bashrc
RUN /bin/bash -c "source /root/.bashrc"
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" | tee -a /root/.bashrc
RUN echo "export HADOOP_HOME=/root/hadoop\n\
export HADOOP_INSTALL=\$HADOOP_HOME\n\
export HADOOP_MAPRED_HOME=\$HADOOP_HOME\n\
export HADOOP_COMMON_HOME=\$HADOOP_HOME\n\
export HADOOP_HDFS_HOME=\$HADOOP_HOME\n\
export YARN_HOME=\$HADOOP_HOME\n\
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native\n\
export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_HOME/lib/native\"\n\
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin" | tee -a /root/.bashrc
RUN /bin/bash -c "source /root/.bashrc"
RUN cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

# Configurations
# Java 
RUN sed -i "s|export HADOOP_CONF_DIR=.*|export HADOOP_CONF_DIR=\${HADOOP_CONF_DIR:-\"/root/hadoop/etc/hadoop\"}|" /root/hadoop/etc/hadoop/hadoop-env.sh
RUN sed -i "s/^export JAVA_HOME.*/export JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-amd64/" /root/hadoop/etc/hadoop/hadoop-env.sh

# core-site.xml
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>fs.defaultFS</name>\n\
\t\t<value>hdfs://namenode:9000</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>hadoop.tmp.dir</name>\n\
\t\t<value>/root/hadooptmpdata</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/core-site.xml
RUN mkdir -p /root/hadooptmpdata

# hdfs-site.xml
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>dfs.replication</name>\n\
\t\t<value>1</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>dfs.namenode.dir</name>\n\
\t\t<value>file:///root/hdfs/namenode</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>dfs.datanode.dir</name>\n\
\t\t<value>file:///root/hdfs/datanode</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/hdfs-site.xml
RUN mkdir -p /root/hadoop/hdfs/namenode && mkdir /root/hadoop/hdfs/datanode

# mapred-site.xml
RUN cp /root/hadoop/etc/hadoop/mapred-site.xml.template /root/hadoop/etc/hadoop/mapred-site.xml
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>mapreduce.framework.name</name>\n\
\t\t<value>yarn</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>yarn.app.mapreduce.am.env</name>\n\
\t\t<value>HADOOP_MAPRED_HOME=\$HADOOP_HOME</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>mapreduce.map.env</name>\n\
\t\t<value>HADOOP_MAPRED_HOME=\$HADOOP_HOME</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>mapreduce.reduce.env</name>\n\
\t\t<value>HADOOP_MAPRED_HOME=\$HADOOP_HOME</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/mapred-site.xml

# yarn-site.xml
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>mapreduceyarn.nodemanager.aux-services</name>\n\
\t\t<value>mapreduce_shuffle</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>yarn.resourcemanager.hostname</name>\n\
\t\t<value>172.18.0.11</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/yarn-site.xml
RUN touch /root/hadoop/etc/hadoop/workers && echo "datanode01\ndatanode02" | tee /root/hadoop/etc/hadoop/workers

# slaves
RUN echo "namenode\ndatanode01\ndatanode02" > /root/hadoop/etc/hadoop/slaves

COPY deploy.master /root/deploy.sh

# Ports
EXPOSE 50070 8088 

CMD /root/deploy.sh
