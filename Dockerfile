FROM ubuntu:18.04
USER root

ARG DEBIAN_FRONTEND=noninteractive
ARG spark_version="3.2.1"
ARG hadoop_version="3.2"
ARG spark_checksum="145ADACF189FECF05FBA3A69841D2804DD66546B11D14FC181AC49D89F3CB5E4FECD9B25F56F0AF767155419CD430838FB651992AEB37D3A6F91E7E009D1F9AE"
ARG openjdk_version="11"
ARG python_version="3.9"

####### update linux #######
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
    "openjdk-${openjdk_version}-jre-headless" \
    software-properties-common \
    gcc python-dev libkrb5-dev npm \
    curl wget vim git maven sudo scala \
    ca-certificates-java

####### install nodejs 12 (req for sparkmagic) #######
RUN apt install -y dirmngr apt-transport-https lsb-release ca-certificates
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
RUN apt install -y nodejs

####### install desired python and set symlink #######
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt install -y python${python_version} \
        python${python_version}-dev python${python_version}-venv && \
        rm /usr/bin/python3 && ln -s $(which python${python_version}) /usr/bin/python3

####### install python libs #######
ADD docker/requirements.txt /root/
RUN apt install -y python3-pip python3-setuptools && \
    pip3 install --upgrade pip setuptools && \
    pip3 install -r /root/requirements.txt

####### install sparkmagic #######
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
    jupyter labextension install "@jupyter-widgets/jupyterlab-manager" && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkkernel && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/pysparkkernel && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkrkernel && \
    jupyter serverextension enable --py sparkmagic

####### install Spark #######
WORKDIR /usr/local
RUN wget -q "https://archive.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop${hadoop_version}.tgz"
RUN echo ${spark_checksum} *spark-${spark_version}-bin-hadoop${hadoop_version}.tgz | sha512sum -c -
RUN tar xzf spark-${spark_version}-bin-hadoop${hadoop_version}.tgz
RUN mv spark-${spark_version}-bin-hadoop${hadoop_version} spark
RUN rm -r spark-${spark_version}-bin-hadoop${hadoop_version}.tgz

WORKDIR /usr/local/spark/jars
RUN wget -q "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${spark_version}/hadoop-aws-${spark_version}.jar" && \
    wget -q "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.166/aws-java-sdk-bundle-1.12.166.jar" && \
    wget -q "https://repo1.maven.org/maven2/io/delta/delta-core_2.12/1.1.0/delta-core_2.12-1.1.0.jar" && \
    wget -q "https://repo1.maven.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar" && \
    rm guava-*.jar && wget -q "https://repo1.maven.org/maven2/com/google/guava/guava/31.0.1-jre/guava-31.0.1-jre.jar"

ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin" \
    PYSPARK_PYTHON=/usr/bin/python3

# add test files
#ADD docker/vimas_merchant_address_20200825_003122.csv.gz /tmp/test.csv.gz
WORKDIR /usr/local/jupyter-notebooks
ADD notebooks .

EXPOSE 8888
EXPOSE 8080
EXPOSE 4040

ADD docker/bootstrap.sh /root/
RUN chmod +x /root/bootstrap.sh
ENTRYPOINT ["/root/bootstrap.sh"]
