# Copyright (c) 2016, CodiLime Inc.

FROM ubuntu:16.04

ARG SPARK_VERSION
ARG HADOOP_VERSION

# Install packages (R-related build deps removed)
RUN apt-get update && \
    apt-get install -y build-essential openjdk-8-jre wget curl bzip2 openssh-server openssh-client libsm6 && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

# Setup passwordless SSH
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# Install Spark
ENV SPARK_PACKAGE spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION
ENV SPARK_HOME /opt/spark-$SPARK_VERSION
ENV PATH $PATH:$SPARK_HOME/bin
RUN wget -q -O - \
  "https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/$SPARK_PACKAGE.tgz" \
  | gunzip \
  | tar x -C /tmp/ \
  && mv /tmp/$SPARK_PACKAGE $SPARK_HOME \
  && rm -rf $SPARK_HOME/examples $SPARK_HOME/ec2 \
  && rm -rf $SPARK_HOME/lib/spark-examples*.jar

# Install conda
RUN wget -q -O /tmp/Miniconda2-4.3.27.1-Linux-x86_64.sh \
    https://repo.continuum.io/miniconda/Miniconda2-4.3.27.1-Linux-x86_64.sh && \
    bash /tmp/Miniconda2-4.3.27.1-Linux-x86_64.sh -f -b -p /opt/conda && \
    rm /tmp/Miniconda2-4.3.27.1-Linux-x86_64.sh && \
# Install python packages
# Install tornado in version 4.1
# jupyter_client/ioloop/restarter.py (jupyter_client < 5.1) needs tornado in that version
    /opt/conda/bin/conda install --yes \
    'tornado=4.1' 'ipykernel=4.3.1' 'jupyter_client=4.3.0' 'pandas=0.16*' 'matplotlib=1.4*' \
    'scipy=0.15*' 'seaborn=0.6*' 'scikit-learn=0.16*' 'libgfortran=1' && \
    /opt/conda/bin/conda clean --all --yes




ENV PATH $PATH:/opt/conda/bin

COPY startup.sh /opt/
RUN chown root.root /opt/startup.sh && chmod 700 /opt/startup.sh

ENTRYPOINT [ "/opt/startup.sh" ]
CMD [ "-d" ]
