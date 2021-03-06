#!/bin/bash

# start ssh
/etc/init.d/ssh start

# start hadoop
yes | hdfs namenode -format
start-dfs.sh
#start-all.sh

hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/root  # will root work ???

# just example files
hdfs dfs -mkdir input
hdfs dfs -put $HADOOP_HOME/etc/hadoop/*.xml input

# start yarn
start-yarn.sh

# start spark
$SPARK_HOME/sbin/start-master.sh
$SPARK_HOME/sbin/start-history-server.sh

# start livy
# needs to run to see logs directly in YARN UI
$LIVY_HOME/bin/livy-server start

# run jupyter
jupyter lab --ip=0.0.0.0 --port=8888 --NotebookApp.token='' \
    --NotebookApp.password='' --allow-root --notebook-dir=/usr/local/jupyter-notebooks