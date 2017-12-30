# Base image
FROM debian:jessie
MAINTAINER Getty Images "https://github.com/gettyimages"

# ======================================================================================================================
# Initial configuration for container
# ======================================================================================================================

# Locale to use
ENV LOCALE es_ES

# Locale configuration
RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "${LOCALE}.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Locale configuration
ENV LANG ${LOCALE}.UTF-8
ENV LANGUAGE ${LOCALE}:es
ENV LC_ALL ${LOCALE}.UTF-8

# Install basic packages: curl, unzip
RUN apt-get update \
 && apt-get install -y curl unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ======================================================================================================================
# Install JDK 8
# ======================================================================================================================

# Args for the installation
ARG JAVA_MAJOR_VERSION=8
ARG JAVA_UPDATE_VERSION=131
ARG JAVA_BUILD_NUMBER=11

# Set JAVA_HOME environment variable
ENV JAVA_HOME /usr/jdk1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}
# Append Java binaries to PATH
ENV PATH $PATH:$JAVA_HOME/bin

# Get JDK 8 from mirror, unpack, create symlink and remove docs
RUN curl -sL --retry 3 --insecure \
  --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMBER}/d54c1d3a095b4ff2b6607d096fa80163/server-jre-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $JAVA_HOME /usr/java \
  && rm -rf $JAVA_HOME/man

# ======================================================================================================================
# Install Hadoop
# ======================================================================================================================

# Set HADOOP_VRESION environment variable
ENV HADOOP_VERSION 2.7.3
# Set HADOOP_HOME environment variable
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
# Set HADOOP_CONF_DIR environment variable
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
# Append Hadoop binaries to PATH
ENV PATH $PATH:$HADOOP_HOME/bin

# Get Hadoop from mirror, unpack, remove docs and update ownership
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# ======================================================================================================================
# Install Spark
# ======================================================================================================================

# Set SPARK_VERSION environment variable
ENV SPARK_VERSION 2.2.0
# Set SPARK_PACKAGE environment variable
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
# Set SPARK_HOME environment variable
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
# Set SPARK_DIST_CLASSPATH environment variable, to let Java compile
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
# Append Spark binaries to PATH
ENV PATH $PATH:${SPARK_HOME}/bin

# Add properties for log4j to customize logging level
ADD conf/general/log4j.properties ${SPARK_HOME}/conf/log4j.properties

# Get Spark from mirror, unpack, move to correct directory and update ownership
RUN curl -sL --retry 3 \
  "http://d3kbcqa49mib13.cloudfront.net/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

# ======================================================================================================================
# Install Scala
# ======================================================================================================================

# Set SCALA_SHORT_VERSION environment variable
ENV SCALA_SHORT_VERSION 2.11
# Set SCALA_VERSION environment variable, which extends SCALA_SHORT_VERSION
ENV SCALA_VERSION ${SCALA_SHORT_VERSION}.12
# Set SCALA_HOME environment variable
ENV SCALA_HOME=/usr/scala-${SCALA_VERSION}
# Append Scala binaries to PATH
ENV PATH $PATH:${SCALA_HOME}/bin

# Get Scala from mirror, unpack, remove docs and update ownership
RUN curl -sL --retry 3 \
  "https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && rm -rf $SCALA_HOME/doc \
 && chown -R root:root $SCALA_HOME

# ======================================================================================================================
# Install SBT
# ======================================================================================================================

# Set SBT_VERSION environment variable
ENV SBT_VERSION 1.0.4
# Set SBT_HOME environment variable
ENV SBT_HOME=/usr/sbt
# Append SBT binaries to PATH
ENV PATH $PATH:${SBT_HOME}/bin

# Get SBT from mirror, unpack and update ownership
RUN curl -sL --retry 3 \
  "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && chown -R root:root $SBT_HOME

# ======================================================================================================================
# Add project files
# ======================================================================================================================

# Set PROJECT_HOMR environment variable
ENV PROJECT_HOME /tmp/musicrecommender

# Copy Audioscrobbler data
ADD data ${PROJECT_HOME}/data
# Copy SBT project data for compilation
ADD project ${PROJECT_HOME}/project
# Copy source code to let SBT compile
ADD src ${PROJECT_HOME}/src
# Copy SBT build properties for compilation
ADD build.sbt ${PROJECT_HOME}/build.sbt

# Create configuration file from which the Scala script will read properties
ENV PROPS_FILE config.properties
RUN echo "DATA_HOME=${PROJECT_HOME}/data" > ${PROJECT_HOME}/${PROPS_FILE}

# Compile and package with SBT
WORKDIR ${PROJECT_HOME}
RUN sbt compile
RUN sbt package

# Execute recommender with SBT
ENV JAR_NAME musicrecommender_${SCALA_SHORT_VERSION}-0.1.jar
RUN /usr/spark-${SPARK_VERSION}/bin/spark-submit \
  --class RunRecommender \
  --master spark://0.0.0.0:7077 \
  ${PROJECT_HOME}/target/scala-${SCALA_SHORT_VERSION}/${JAR_NAME}
