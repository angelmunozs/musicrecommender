# Create a pseudo-distributed hadoop 2.7.1
# Based on sequenceiq/hadoop-docker
# Modified by @angelmunozs

FROM sequenceiq/hadoop-docker
MAINTAINER angelmunozs

USER root

# Make empty directories
RUN mkdir -p /datasets
RUN mkdir -p /checkpoint

# Add datasets to /datasets
ADD data/artist_alias.txt /datasets
ADD data/artist_data.txt /datasets
ADD data/user_artist_data.txt /datasets

# Add empty file to /checkpoint
RUN touch /checkpoint/keep

# Add directory /user/data to HDFS
RUN service sshd start && \
    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    $HADOOP_PREFIX/sbin/start-dfs.sh && \
    $HADOOP_PREFIX/bin/hdfs dfsadmin -safemode leave && \
    $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/data

# Add content to previously created HDFS directory
RUN service sshd start && \
    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    $HADOOP_PREFIX/sbin/start-dfs.sh && \
    $HADOOP_PREFIX/bin/hdfs dfsadmin -safemode leave && \
    $HADOOP_PREFIX/bin/hdfs dfs -put /datasets/* /user/data

# Add directory /user/tmp to HDFS
RUN service sshd start && \
    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    $HADOOP_PREFIX/sbin/start-dfs.sh && \
    $HADOOP_PREFIX/bin/hdfs dfsadmin -safemode leave && \
    $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/tmp

# Add content to previously created HDFS directory
RUN service sshd start && \
    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    $HADOOP_PREFIX/sbin/start-dfs.sh && \
    $HADOOP_PREFIX/bin/hdfs dfsadmin -safemode leave && \
    $HADOOP_PREFIX/bin/hdfs dfs -put /checkpoint/* /user/tmp