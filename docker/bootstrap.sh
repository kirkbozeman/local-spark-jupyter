#!/bin/bash

$SPARK_HOME/sbin/start-master.sh

# run jupyter
# send to 8890 to avoid clashes with local on 8888
# mount local home as default dir
jupyter lab --ip=0.0.0.0 --port=8890 --NotebookApp.token='' \
    --NotebookApp.password='' --allow-root --notebook-dir=/local/usr/jupyter-notebooks