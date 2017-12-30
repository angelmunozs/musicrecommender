FROM debian:jessie
MAINTAINER Getty Images "https://github.com/gettyimages"

RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG es_ES.UTF-8
ENV LANGUAGE es_ES:en
ENV LC_ALL es_ES.UTF-8

RUN apt-get update \
 && apt-get install -y curl unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# JAVA
ARG JAVA_MAJOR_VERSION=8
ARG JAVA_UPDATE_VERSION=131
ARG JAVA_BUILD_NUMBER=11
ENV JAVA_HOME /usr/jdk1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}
ENV PATH $PATH:$JAVA_HOME/bin
RUN curl -sL --retry 3 --insecure \
  --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMBER}/d54c1d3a095b4ff2b6607d096fa80163/server-jre-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $JAVA_HOME /usr/java \
  && rm -rf $JAVA_HOME/man

# HADOOP
ENV HADOOP_VERSION 2.7.3
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# SPARK
ENV SPARK_VERSION 2.2.0
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "http://d3kbcqa49mib13.cloudfront.net/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

# SCALA
ENV SCALA_SHORT_VERSION 2.11
ENV SCALA_VERSION ${SCALA_SHORT_VERSION}.12
ENV SCALA_HOME=/usr/scala-${SCALA_VERSION}
ENV PATH $PATH:${SCALA_HOME}/bin
RUN curl -sL --retry 3 \
  "https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && rm -rf $SCALA_HOME/doc \
 && chown -R root:root $SCALA_HOME

# SBT
ENV SBT_VERSION 1.0.4
ENV SBT_HOME=/usr/sbt
ENV PATH $PATH:${SBT_HOME}/bin
RUN curl -sL --retry 3 \
  "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && chown -R root:root $SBT_HOME

# Add projcet files
ENV PROJECT_HOME /tmp/musicrecommender
ADD data ${PROJECT_HOME}/data
ADD project ${PROJECT_HOME}/project
ADD src ${PROJECT_HOME}/src
ADD build.sbt ${PROJECT_HOME}/build.sbt

# Create configuration file from which the Scala script will read properties
ENV PROPS_FILE config.properties
RUN echo "DATA_HOME=${DATA_HOME}" > ${PROJECT_HOME}/${PROPS_FILE}

# Compile and package with sbt
WORKDIR ${PROJECT_HOME}
RUN sbt compile
RUN sbt package
RUN ls -al ${PROJECT_HOME}/target/scala-${SCALA_SHORT_VERSION}

# Execute recommender with sbt
ENV JAR_NAME musicrecommender_${SCALA_SHORT_VERSION}-0.1.jar
ENV SPARK_MASTER_IP 192.168.1.61
RUN /usr/spark-${SPARK_VERSION}/bin/spark-submit \
  --class RunRecommender \
  --master spark://0.0.0.0:7077 \
  ${PROJECT_HOME}/target/scala-${SCALA_SHORT_VERSION}/${JAR_NAME}
