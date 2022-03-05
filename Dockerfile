#FROM ubuntu:18.04
#FROM openjdk:11
#FROM openjdk:11.0.14.1-jdk-bullseye
FROM openjdk:8

USER root
ENV SHELL=/bin/bash

ARG DEBIAN_FRONTEND=noninteractive
ARG hadoop_version="3.2.1"
ARG spark_version="3.2.1"
ARG spark_hadoop_version="3.2"
#ARG spark_checksum="145ADACF189FECF05FBA3A69841D2804DD66546B11D14FC181AC49D89F3CB5E4FECD9B25F56F0AF767155419CD430838FB651992AEB37D3A6F91E7E009D1F9AE"
ARG spark_checksum="0923B887BFFE9CE984B41E730A0059D563D0EE429F4E8C74BE2DF98D0B441919EFF4CC3C43D79B131D3B914139DF4833AEE75280889643690E8C14A287552B40"
ARG openjdk_version="11"
ARG python_version="3.9"
ARG livy_version="0.7.1"

####### update linux #######
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
    software-properties-common \
    gcc python-dev libkrb5-dev npm \
    curl wget vim git unzip sudo scala \
    openssh-client openssh-server

#    ca-certificates-java maven \
#    openjdk-${openjdk_version}-jdk
#ENV JAVA_HOME=/usr/bin/java
#    "openjdk-${openjdk_version}-jre-headless" default-jre \

#ADD docker/hadoop/ssh_config /root/.ssh/config
#RUN chmod 600 /root/.ssh/config && \
#    chown root:root /root/.ssh/config
#RUN /etc/init.d/ssh start

#RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
#  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
#  chmod 0600 ~/.ssh/authorized_keys

####### install nodejs 12 (req for sparkmagic) #######
RUN apt install -y dirmngr apt-transport-https lsb-release ca-certificates && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash && \
    apt install -y nodejs

####### install desired python and set symlink #######
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt install -y python${python_version} \
        python${python_version}-dev python${python_version}-venv && \
        rm /usr/bin/python3 && ln -s $(which python${python_version}) /usr/bin/python3

####### install python libs #######
ADD docker/requirements.txt /root/
RUN apt install -y python3-pip python3-setuptools && \
    pip3 install --upgrade pip setuptools requests cython && \
    pip3 install -r /root/requirements.txt

WORKDIR /usr/local

####### install hadoop #######

ARG hadoop_user=hadoop_user1

#RUN addgroup hadoop && adduser --ingroup hadoop hadoop_user1
#RUN adduser --disabled-password --gecos '' $hadoop_user
#USER $hadoop_user
#RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \

RUN ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N "" && \
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 0600 ~/.ssh/authorized_keys

#USER root

RUN wget -q "https://archive.apache.org/dist/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz"
RUN tar xzf hadoop-${hadoop_version}.tar.gz
RUN mv hadoop-${hadoop_version} hadoop
RUN rm -r hadoop-${hadoop_version}.tar.gz

#RUN chown -R $hadoop_user /usr/local

#ENV JAVA_HOME= $(dirname $(readlink -f $(which javac)))
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH="$PATH:$HADOOP_HOME/bin"
ENV PATH="$PATH:$HADOOP_HOME/sbin"
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

ADD /docker/hadoop/. $HADOOP_HOME/etc/hadoop/
RUN eval "sed -i '54 i export JAVA_HOME=${JAVA_HOME}' $HADOOP_HOME/etc/hadoop/hadoop-env.sh"


RUN mkdir $HADOOP_HOME/logs
#RUN hdfs dfs -mkdir /user && \
#    hdfs dfs -mkdir /user/root  # will root work ???

#RUN mkdir -p /usr/local/hadoop_space
#RUN mkdir -p /usr/local/hadoop_space/hdfs/namenode
#RUN mkdir -p /usr/local/hadoop_space/hdfs/datanode
#RUN yes | hdfs namenode -format
#RUN start-dfs.sh

####### install Spark #######
#RUN wget -q "https://archive.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop${spark_hadoop_version}.tgz"
#RUN echo ${spark_checksum} *spark-${spark_version}-bin-hadoop${spark_hadoop_version}.tgz | sha512sum -c -
#RUN tar xzf spark-${spark_version}-bin-hadoop${spark_hadoop_version}.tgz
#RUN mv spark-${spark_version}-bin-hadoop${spark_hadoop_version} spark
#RUN rm -r spark-${spark_version}-bin-hadoop${spark_hadoop_version}.tgz

RUN wget -q "https://dlcdn.apache.org/spark/spark-${spark_version}/spark-${spark_version}-bin-without-hadoop.tgz"
RUN echo ${spark_checksum} *spark-${spark_version}-bin-without-hadoop.tgz | sha512sum -c -
RUN tar xzf spark-${spark_version}-bin-without-hadoop.tgz
RUN mv spark-${spark_version}-bin-without-hadoop spark
RUN rm -r spark-${spark_version}-bin-without-hadoop.tgz

ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PYSPARK_PYTHON=/usr/bin/python3
#    PATH="${PATH}:${SPARK_HOME}/bin" \
ENV PATH "$PATH:$SPARK_HOME/bin"
ADD docker/spark/spark-defaults.conf $SPARK_HOME/conf
ADD docker/spark/spark-env.sh $SPARK_HOME/conf

RUN mkdir $SPARK_HOME/logs
RUN mkdir $SPARK_HOME/spark-events

WORKDIR $SPARK_HOME/jars
RUN wget -q "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${hadoop_version}/hadoop-aws-${hadoop_version}.jar" && \
    wget -q "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.166/aws-java-sdk-bundle-1.12.166.jar" && \
    wget -q "https://repo1.maven.org/maven2/io/delta/delta-core_2.12/1.1.0/delta-core_2.12-1.1.0.jar" && \
    wget -q "https://repo1.maven.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar" && \
    wget -q "https://repo1.maven.org/maven2/io/minio/spark-select_2.11/2.1/spark-select_2.11-2.1.jar" && \
    wget -q "https://repo1.maven.org/maven2/com/google/guava/guava/31.0.1-jre/guava-31.0.1-jre.jar" && \
    wget -q "https://repo1.maven.org/maven2/log4j/log4j/1.2.17/log4j-1.2.17.jar"
#    rm guava-*.jar && wget -q "https://repo1.maven.org/maven2/com/google/guava/guava/31.0.1-jre/guava-31.0.1-jre.jar"  # rm not needed

#RUN eval "sed -i -e '\$export SPARK_DIST_CLASSPATH=\$(hadoop classpath)' ${SPARK_HOME}/conf/spark-env.sh"


####### install livy #######
WORKDIR $SPARK_HOME/livy
ENV LIVY_HOME="${SPARK_HOME}/livy/apache-livy-${livy_version}-incubating-bin/"
RUN wget "https://dlcdn.apache.org/incubator/livy/${livy_version}-incubating/apache-livy-${livy_version}-incubating-bin.zip" && \
    unzip "apache-livy-${livy_version}-incubating-bin.zip" && \
    rm "apache-livy-${livy_version}-incubating-bin.zip"
RUN mkdir $LIVY_HOME/logs
ADD docker/livy.conf "${LIVY_HOME}/conf/"

####### install sparkmagic #######
RUN jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkkernel && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/pysparkkernel && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkrkernel && \
    jupyter serverextension enable --py sparkmagic

# add test files
#ADD docker/vimas_merchant_address_20200825_003122.csv.gz /tmp/test.csv.gz
WORKDIR /usr/local/jupyter-notebooks
ADD notebooks .

ADD docker/bootstrap.sh /root/
RUN chmod +x /root/bootstrap.sh
ENTRYPOINT ["/root/bootstrap.sh"]
