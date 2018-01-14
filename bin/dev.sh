#!/usr/bin/env bash
# Script to deploy development environment for this project.

# ==============================================================================================================
# Dependencies
# ==============================================================================================================

# Common parameters and functions
source bin/common.sh

# ==============================================================================================================
# Parameters
# ==============================================================================================================

# Data mirror
DATA_MIRROR=http://samplecleaner.com
# Data files
DATA_FILES=(
	"artist_alias.txt"
	"artist_data.txt"
	"user_artist_data.txt"
)

# ==============================================================================================================
# Main
# ==============================================================================================================

# Make directories (if not present yet)
if [ ! -d $INSTALLS_DIR ]; then
	mkdir $INSTALLS_DIR
fi

# Change directory
cd $INSTALLS_DIR

# Download and install Oracle JDK
if [ ! -d /usr/lib/jvm/jdk1.8.0_144 ]; then
	sudo add-apt-repository ppa:webupd8team/java
	sudo apt-get update
	sudo apt-get install -y oracle-java8-installer
	export JAVA_HOME=/usr/lib/jvm/java-8-oracle
	log_success "Oracle JDK 8 sucessfully installed in $JAVA_HOME."
fi

# Download and install Spark
if [ ! -d spark-$SPARK_VERSION-bin-hadoop2.7 ]; then
    wget http://apache.rediris.es/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
  	tar -zxvf spark-$SPARK_VERSION-bin-hadoop2.7.tgz
  	rm spark-$SPARK_VERSION-bin-hadoop2.7.tgz
  	ln -sf spark-$SPARK_VERSION-bin-hadoop2.7 spark
  	export SPARK_HOME=$INSTALLS_DIR/spark-$SPARK_VERSION-bin-hadoop2.7
  	cp conf/common/* $SPARK_HOME/conf
    log_success "Apache Spark downloaded and installed in $SPARK_HOME."
fi

# Download and install Scala
if [ ! -d scala-$SCALA_VERSION ]; then
	wget https://downloads.lightbend.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz
	tar -zxvf scala-$SCALA_VERSION.tgz
	rm scala-$SCALA_VERSION.tgz
	ln -sf scala-$SCALA_VERSION scala
	export SCALA_HOME=$INSTALLS_DIR/scala-$SCALA_VERSION
	log_success "Scala downloaded and installed in $SCALA_HOME"
fi

# Download and install SBT
if [ ! -d scala-$SBT_VERSION ]; then
	wget https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz
	tar -zxvf sbt-$SBT_VERSION.tgz
	rm sbt-$SBT_VERSION.tgz
	ln -sf sbt-$SBT_VERSION sbt
	export SBT_HOME=$INSTALLS_DIR/sbt-$SBT_VERSION
	log_success "Scala downloaded and installed in $SCALA_HOME"
fi

# Change directory
mkdir -p $LOCAL_DATA_DIR
cd $LOCAL_DATA_DIR

# Download Audioscrobbler data from desired mirror
for DATA_FILE in "${DATA_FILES[@]}"
do
	if [ ! -f $DATA_FILE ]; then
		wget $DATA_MIRROR/$DATA_FILE
		log_success "Downloaded file $DATA_FILE into $LOCAL_DATA_DIR"
	fi
done

# Giver R+W premissions for all users to data/*
sudo chmod 666 $LOCAL_DATA_DIR/*
