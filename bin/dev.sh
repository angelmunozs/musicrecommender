# Script to deploy development environment for this project.

# ==============================================================================================================
# Parameters
# ==============================================================================================================

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
	echo -e "$ICON_SUCCESS $1"
}

# Function for logging a success message
# Parameters:
# - $1: Log message
log_error () {
	echo -e "$ICON_ERROR $1"
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

# 1. Install git
sudo apt-get update
sudo apt-get install -y git

# 2. Make directories (if not present yet)
if [ ! -d $PROJECTS_LOCATION ]; then
	mkdir $PROJECTS_LOCATION
fi
if [ ! -d $INSTALLS_DIR ]; then
	mkdir $INSTALLS_DIR
fi

# Change directory
cd $PROJECTS_LOCATION

# 3. Download custom project (or git pull if present)
if [ ! -d musicrecommender ]; then
	git clone https://github.com/angelmunozs/musicrecommender
	log_info "Code for musicrecommender from @angelmunozs copied to $PROJECTS_LOCATION/musicrecommender."
else
	cd musicrecommender
	git pull
	cd ..
	log_info "Code for musicrecommender from @angelmunozs in $PROJECTS_LOCATION/musicrecommender updated."
fi

# Change directory
cd $INSTALLS_DIR

# 4. Download IntelliJ IDEA 2.5 if not present and create alias in .bashrc
if [ ! -d $INSTALLS_DIR/idea-IC-172.4343.14 ]; then
	wget https://download.jetbrains.com/idea/ideaIC-2017.2.5.tar.gz
	tar -zxvf ideaIC-2017.2.5.tar.gz
	rm ideaIC-2017.2.5.tar.gz
	ln -sf idea-IC-172.4343.14 idea
	log_info "IntelliJ IDEA downloaded and installed in $INSTALLS_DIR/idea-IC-172.4343.14."
fi

# 5. Install Apache Spark
if [ ! -d $INSTALLS_DIR/spark-2.2.0-bin-hadoop2.7 ]; then
	wget http://apache.rediris.es/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz
	tar -zxvf spark-2.2.0-bin-hadoop2.7.tgz
	rm spark-2.2.0-bin-hadoop2.7.tgz
	ln -sf spark-2.2.0-bin-hadoop2.7 spark
	log_info "Apache Spark downloaded and installed in $INSTALLS_DIR/spark-2.2.0-bin-hadoop2.7."
fi

# 6. Install Scala plugin for IDEA
if [ ! -d ./idea/plugins/Scala ]; then
	cp -r $LIBS_LOCATION/Scala ./idea/plugins
	log_info "Plugin Scala for IntelliJ IDEA installed succesfully"
fi

# Change directory
cd $DATA_DIR

# 7. Download Audioscrobbler data from desired mirror
for DATA_FILE in "${DATA_FILES[@]}"
do
	if [ ! -f $DATA_FILE ]; then
		wget $DATA_MIRROR/$DATA_FILE
		log_info "Downloaded file $DATA_FILE into $DATA_DIR"
	fi
done

# 8. Open IntelliJ IDEA in background
log_info "Opening IntelliJ IDEA development tool."
$INSTALLS_DIR/idea/bin/idea.sh
