FROM ubuntu:18.04
#FROM python:3.10-slim-buster
#FROM alpine:3.10

USER root

# Spark dependencies
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
ARG spark_version="3.2.0"
ARG hadoop_version="3.2"
ARG spark_checksum="EBE51A449EBD070BE7D3570931044070E53C23076ABAD233B3C51D45A7C99326CF55805EE0D573E6EB7D6A67CFEF1963CD77D6DC07DD2FD70FD60DA9D1F79E5E"
ARG openjdk_version="11"

ENV APACHE_SPARK_VERSION="${spark_version}" \
    HADOOP_VERSION="${hadoop_version}"

RUN apt-get update -y && \
    apt-get install -y \
    "openjdk-${openjdk_version}-jre-headless" \
    software-properties-common \
    curl wget vim git scala \
    ca-certificates-java \
    build-essential libssl-dev libffi-dev python3-dev \
    python3 python3-pip && \
    pip3 install --upgrade pip  # MUST upgrade pip

ADD docker/requirements.txt /root/
RUN pip3 install -r /root/requirements.txt


#    build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev \

#    && \
#    apt-get clean && rm -rf /var/lib/apt/lists/*


# Spark installation from local tgz
#ADD docker/spark-3.2.0-bin-hadoop3.2.tgz /tmp/
#RUN cp -a /tmp/spark-3.2.0-bin-hadoop3.2/. /usr/local/spark/ && \
#    rm -r /tmp/spark-3.2.0-bin-hadoop3.2


# Spark installation
WORKDIR /usr/local
RUN wget -q "https://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"
RUN echo ${spark_checksum} *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | sha512sum -c -
RUN tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN mv spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark
RUN rm -r spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# install python 3.8
#RUN add-apt-repository ppa:deadsnakes/ppa -y
#RUN apt install -y python3.8 \
#        python3-pip python3-setuptools \
#        python3-numpy python3-matplotlib python3-scipy python3-pandas python3-simpy

ADD docker/vimas_merchant_address_20200825_003122.csv.gz /tmp/test.csv.gz

WORKDIR /usr/local

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin" \
    PYSPARK_PYTHON=/usr/bin/python3

#RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark && \
#    # Add a link in the before_notebook hook in order to source automatically PYTHONPATH
#    mkdir -p /usr/local/bin/before-notebook.d && \
#    ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

ENTRYPOINT ["tail", "-f", "/dev/null"]

# start me up
#COPY docker/start-jupyter.sh /root/
#RUN chmod +x /root/start-jupyter.sh
#ENTRYPOINT ["/root/start-jupyter.sh"]
#EXPOSE 8890

