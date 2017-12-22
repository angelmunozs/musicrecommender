# Script to deploy development environment for this project.

# ==============================================================================================================
# Parameters
# ==============================================================================================================

# Versions to download
SPARK_VERSION=2.2.0
SCALA_VERSION=2.11.12
IDEA_VERSION=2017.2.5
# Name of the project container folder
PROJECTS_LOCATION=~/www
# Software installation folder
INSTALLS_DIR=~/opt
# Data directory
DATA_DIR=$PROJECTS_LOCATION/musicrecommender/data
# Libs location
LIBS_LOCATION=$PROJECTS_LOCATION/musicrecommender/libs
# Data mirror
DATA_MIRROR=http://samplecleaner.com
# Data files
DATA_FILES=(
	"artist_alias.txt"
	"artist_data.txt"
	"user_artist_data.txt"
)
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
# Green tick
ICON_SUCCESS="$GREEN✔$NC"
ICON_ERROR="$RED✖$NC"

# ==============================================================================================================
# Aux functions
# ==============================================================================================================

# Function for logging an info message
# Parameters:
# - $1: Log message
log_info () {
	echo -e "[info] $1"
}

# Function for logging a success message
# Parameters:
# - $1: Log message
log_success () {
	line
	echo -e "$ICON_SUCCESS $1"
	line
}

# Function for logging a success message
# Parameters:
# - $1: Log message
log_error () {
	line
	echo -e "$ICON_ERROR $1"
	line
	exit 1
}

# Function for printing a '=' character till the end of line
line () {
	for i in $(seq 1 $(stty size | cut -d' ' -f2)); do 
		echo -n "="
	done
	echo ""
}

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
if [ ! -d musicrecommender ]; then
	git clone https://github.com/angelmunozs/musicrecommender
	log_success "Code for musicrecommender from @angelmunozs copied to $PROJECTS_LOCATION/musicrecommender."
else
	cd musicrecommender
	git pull
	cd ..
	log_success "Code for musicrecommender from @angelmunozs in $PROJECTS_LOCATION/musicrecommender updated."
fi

# Change directory
cd $INSTALLS_DIR

# Download and install Oracle JDK
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java8-installer
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
log_success "Oracle JDK 8 sucessfully installed in $JAVA_HOME."

# Download and install Apache Spark
if [ ! -d spark-$SPARK_VERSION-bin-hadoop2.7 ]; then
	wget http://apache.rediris.es/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
	tar -zxvf spark-$SPARK_VERSION-bin-hadoop2.7.tgz
	rm spark-$SPARK_VERSION-bin-hadoop2.7.tgz
	ln -sf spark-$SPARK_VERSION-bin-hadoop2.7 spark
	export SPARK_HOME=$INSTALLS_DIR/spark-$SPARK_VERSION-bin-hadoop2.7
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
cd $DATA_DIR

# Download Audioscrobbler data from desired mirror
for DATA_FILE in "${DATA_FILES[@]}"
do
	if [ ! -f $DATA_FILE ]; then
		wget $DATA_MIRROR/$DATA_FILE
		log_success "Downloaded file $DATA_FILE into $DATA_DIR"
	fi
done

# Open IntelliJ IDEA in background
log_success "Opening IntelliJ IDEA development tool."
$INSTALLS_DIR/idea/bin/idea.sh
