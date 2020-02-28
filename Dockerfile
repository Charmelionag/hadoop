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
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin" | tee -a .bashrc
ENV PATH="${PATH}:/root/hadoop/sbin:/root/hadoop/bin"
RUN cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

# Configurations
# Hadoop
RUN sed -i "s|export HADOOP_CONF_DIR=.*|export HADOOP_CONF_DIR=\${HADOOP_CONF_DIR:-\"/root/hadoop/etc/hadoop\"}|" /root/hadoop/etc/hadoop/hadoop-env.sh
RUN sed -i "s/^export JAVA_HOME.*/export JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-amd64/" /root/hadoop/etc/hadoop/hadoop-env.sh
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>fs.defaultFS</name>\n\
\t\t<value>hdfs://localhost:9000</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>hadoop.tmp.dir</name>\n\
\t\t<value>/root/hadooptmpdata</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/core-site.xml
RUN mkdir -p /root/hadooptmpdata
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>dfs.replication</name>\n\
\t\t<value>1</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>dfs.name.dir</name>\n\
\t\t<value>file:///root/hdfs/namenode</value>\n\
\t</property>\n\
\t<property>\n\
\t\t<name>dfs.data.dir</name>\n\
\t\t<value>file:///root/hdfs/datanode</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/hdfs-site.xml
RUN mkdir -p /root/hadoop/hdfs/namenode && mkdir /root/hadoop/hdfs/datanode
RUN cp /root/hadoop/etc/hadoop/mapred-site.xml.template /root/hadoop/etc/hadoop/mapred-site.xml
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>mapreduce.framework.name</name>\n\
\t\t<value>yarn</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/mapred-site.xml
RUN echo "<configuration>\n\
\t<property>\n\
\t\t<name>mapreduceyarn.nodemanager.aux-services</name>\n\
\t\t<value>mapreduce_shuffle</value>\n\
\t</property>\n\
</configuration>" | tee /root/hadoop/etc/hadoop/yarn-site.xml

# Deployment file
RUN echo '#!/bin/bash' > /root/deploy.sh
RUN echo 'service ssh start' >> /root/deploy.sh
RUN echo 'eval $(ssh-agent -s)' >> /root/deploy.sh
RUN echo 'ssh-add /root/.ssh/id_rsa' >> /root/deploy.sh
RUN echo 'echo -e "127.0.0.1\tlocalhost\n172.18.0.10\tnamenode\n172.18.0.11\tdatanode01\n172.18.0.12\tdatanode02" | tee /etc/hosts' >> /root/deploy.sh
RUN echo "sleep 3\n\
ssh-keyscan -H localhost >> ~/.ssh/known_hosts\n\
ssh-keyscan -H namenode >> ~/.ssh/known_hosts\n\
ssh-keyscan -H datanode01 >> ~/.ssh/known_hosts\n\
ssh-keyscan -H datanode02 >> ~/.ssh/known_hosts\n\
hdfs namenode -format\n\
start-dfs.sh\n\
start-yarn.sh\n\
ping 0.0.0.0 > /dev/null" >> /root/deploy.sh && chmod +x /root/deploy.sh

# Ports
EXPOSE 50070 8088

CMD /root/deploy.sh
