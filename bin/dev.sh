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

# Install git
sudo apt-get update
sudo apt-get install -y git

# Make directories (if not present yet)
if [ ! -d $PROJECTS_LOCATION ]; then
	mkdir $PROJECTS_LOCATION
fi
if [ ! -d $INSTALLS_DIR ]; then
	mkdir $INSTALLS_DIR
fi

# Change directory
cd $PROJECTS_LOCATION

# Download custom project (or git pull if present)
if [ ! -d $PROJETC_NAME ]; then
	git clone https://github.com/angelmunozs/$PROJETC_NAME
	log_success "Code for $PROJETC_NAME from @angelmunozs copied to $PROJECTS_LOCATION/$PROJETC_NAME."
else
	cd $PROJETC_NAME
	git pull
	cd ..
	log_success "Code for $PROJETC_NAME from @angelmunozs in $PROJECTS_LOCATION/$PROJETC_NAME updated."
fi

# Change directory
cd $INSTALLS_DIR

# Download and install Oracle JDK
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java8-installer
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
log_success "Oracle JDK 8 sucessfully installed in $JAVA_HOME."

# Download and install Spark
if [ ! -d spark-$SPARK_VERSION-bin-hadoop2.7 ]; then
    wget http://apache.rediris.es/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
  	tar -zxvf spark-$SPARK_VERSION-bin-hadoop2.7.tgz
  	rm spark-$SPARK_VERSION-bin-hadoop2.7.tgz
  	ln -sf spark-$SPARK_VERSION-bin-hadoop2.7 spark
  	export SPARK_HOME=$INSTALLS_DIR/spark-$SPARK_VERSION-bin-hadoop2.7
    log_success "Apache Spark downloaded and installed in $SPARK_HOME."
    # Export default Spark conf
    echo "spark.driver.memory    8g" > $SPARK_HOME/conf/spark-defaults.conf
    echo "spark.driver.cores     4" >> $SPARK_HOME/conf/spark-defaults.conf
    echo "spark.executor.memory  8g" >> $SPARK_HOME/conf/spark-defaults.conf
    echo "spark.executor.cores   4" >> $SPARK_HOME/conf/spark-defaults.conf
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

# Download IntelliJ IDEA 2.5 if not present
if [ ! -d idea-IC-172.4343.14 ]; then
	wget https://download.jetbrains.com/idea/ideaIC-$IDEA_VERSION.tar.gz
	tar -zxvf ideaIC-$IDEA_VERSION.tar.gz
	rm ideaIC-$IDEA_VERSION.tar.gz
	ln -sf idea-IC-172.4343.14 idea
	export IDEA_HOME=$INSTALLS_DIR/idea-IC-172.4343.14
	log_success "IntelliJ IDEA downloaded and installed in $IDEA_HOME."
fi

# Change directory
cd $LOCAL_DATA_DIR

# Download Audioscrobbler data from desired mirror
for DATA_FILE in "${DATA_FILES[@]}"
do
	if [ ! -f $DATA_FILE ]; then
		wget $DATA_MIRROR/$DATA_FILE
		log_success "Downloaded file $DATA_FILE into $LOCAL_DATA_DIR"
	fi
done

# Open IntelliJ IDEA in background
log_success "Opening IntelliJ IDEA development tool."
$INSTALLS_DIR/idea/bin/idea.sh
