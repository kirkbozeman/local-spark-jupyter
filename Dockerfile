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

#    apt-get upgrade -y && \

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
    "openjdk-${openjdk_version}-jre-headless" \
    software-properties-common \
    curl wget vim git scala \
    ca-certificates-java

# install python
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt install -y python${python_version} \
        python${python_version}-dev python${python_version}-venv

# delete symlink to 3.6 and set to 3.X
RUN rm /usr/bin/python3 && \
    ln -s $(which python${python_version}) /usr/bin/python3

# install python libs
ADD docker/requirements.txt /root/
RUN apt install -y python3-pip python3-setuptools && \
    pip3 install --upgrade pip && \
    pip3 install -r /root/requirements.txt

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
ADD docker/test_nb.ipynb /local/usr/jupyter-notebooks/test_nb.ipynb

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
