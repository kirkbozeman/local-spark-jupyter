FROM ubuntu:18.04
#FROM ubuntu:20.04
#FROM python:3.10-slim-buster
#FROM alpine:3.10

USER root

ARG DEBIAN_FRONTEND=noninteractive
ARG spark_version="3.2.0"
ARG hadoop_version="3.2"
ARG spark_checksum="EBE51A449EBD070BE7D3570931044070E53C23076ABAD233B3C51D45A7C99326CF55805EE0D573E6EB7D6A67CFEF1963CD77D6DC07DD2FD70FD60DA9D1F79E5E"
ARG openjdk_version="11"
ARG python_version="3.9"

ENV APACHE_SPARK_VERSION="${spark_version}" \
    HADOOP_VERSION="${hadoop_version}"

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
    "openjdk-${openjdk_version}-jre-headless" \
    software-properties-common \
    gcc python-dev libkrb5-dev npm \
    curl wget vim git scala maven \
    ca-certificates-java

# install nodejs 12 (req for sparkmagic)
RUN apt install -y dirmngr apt-transport-https lsb-release ca-certificates
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
RUN apt install -y nodejs

# install desired python and set symlink
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt install -y python${python_version} \
        python${python_version}-dev python${python_version}-venv && \
        rm /usr/bin/python3 && ln -s $(which python${python_version}) /usr/bin/python3

# install python libs
ADD docker/requirements.txt /root/
RUN apt install -y python3-pip python3-setuptools && \
    pip3 install --upgrade pip setuptools && \
    pip3 install -r /root/requirements.txt
#    pip install -r /root/requirements.txt


# install sparkmagic
#ARG sparkmagic_kernel_path=/usr/local/lib/python3.9/dist-packages
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
    jupyter labextension install "@jupyter-widgets/jupyterlab-manager" && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkkernel && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/pysparkkernel && \
    jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkrkernel && \
    jupyter serverextension enable --py sparkmagic

#ADD sparkmagic/example_config.json /local/usr/jupyter-notebooks/.sparkmagic/config.json


# Spark installation from local tgz
#ADD docker/spark-3.2.0-bin-hadoop3.2.tgz /tmp/
#RUN cp -a /tmp/spark-3.2.0-bin-hadoop3.2/. /usr/local/spark/ && \
#    rm -r /tmp/spark-3.2.0-bin-hadoop3.2

WORKDIR /usr/local

# Spark installation
RUN wget -q "https://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"
RUN echo ${spark_checksum} *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | sha512sum -c -
RUN tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN mv spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark
RUN rm -r spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# add test files
ADD docker/vimas_merchant_address_20200825_003122.csv.gz /tmp/test.csv.gz
ADD notebooks /usr/local/jupyter-notebooks

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin" \
    PYSPARK_PYTHON=/usr/bin/python3

EXPOSE 8890
EXPOSE 8080

COPY docker/bootstrap.sh /root/
RUN chmod +x /root/bootstrap.sh
ENTRYPOINT ["/root/bootstrap.sh"]

#ENTRYPOINT ["tail", "-f", "/dev/null"]
