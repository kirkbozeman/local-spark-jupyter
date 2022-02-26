#!/bin/bash

# start spark
$SPARK_HOME/sbin/start-master.sh

# run jupyter
jupyter lab --ip=0.0.0.0 --port=8890 --NotebookApp.token='' \
    --NotebookApp.password='' --allow-root --notebook-dir=/usr/local/jupyter-notebooks