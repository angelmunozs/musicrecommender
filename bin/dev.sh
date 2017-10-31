# Script to deploy development environment for this project.

# ==============================================================================================================
# Parameters
# ==============================================================================================================

# Name of the project container folder
PROJECTS_LOCATION=~/www
# Software installation folder
INSTALLS_DIR=~/opt
# Data directory
DATA_DIR=~/www/musicrecommender/data
# Libs location
LIBS_LOCATION=~/www/musicrecommender/libs
# Data mirror
DATA_MIRROR=http://samplecleaner.com
# Data files
DATA_FILES = (
	"artist_alias.txt"
	"artist_data.txt"
	"user_artist_data.txt"
)

# ==============================================================================================================
# Aux functions
# ==============================================================================================================

# Function for logging
# Parameters:
# - $1: Log type
# - $2: Log message
log () {
	tput setaf 2
	echo "[$1] $2"
	tput sgr0
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
	log info "Code for music recommender from @angelmunozs copied to $PROJECTS_LOCATION/musicrecommender."
else
	cd musicrecommender
	git pull
	cd ..
	log info "Code for music recommender from @angelmunozs in $PROJECTS_LOCATION/musicrecommender updated."
fi

# Change directory
cd $INSTALLS_DIR

# 4. Download IntelliJ IDEA 2.5 if not present and create alias in .bashrc
if [ ! -d $INSTALLS_DIR/idea-IC-172.4343.14 ]; then
	wget https://download.jetbrains.com/idea/ideaIC-2017.2.5.tar.gz
	tar -zxvf ideaIC-2017.2.5.tar.gz
	rm ideaIC-2017.2.5.tar.gz
	ln -sf idea-IC-172.4343.14 idea
	log info "IntelliJ IDEA downloaded and installed in $INSTALLS_DIR/idea-IC-172.4343.14."
fi

# 5. Install Apache Spark
if [ ! -d $INSTALLS_DIR/spark-2.2.0-bin-hadoop2.7 ]; then
	wget http://apache.rediris.es/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz
	tar -zxvf spark-2.2.0-bin-hadoop2.7.tgz
	rm spark-2.2.0-bin-hadoop2.7.tgz
	ln -sf spark-2.2.0-bin-hadoop2.7 spark
	log info "Apache Spark downloaded and installed in $INSTALLS_DIR/spark-2.2.0-bin-hadoop2.7."
fi

# 6. Install Scala plugin for IDEA
cp -r $LIBS_LOCATION/Scala ./idea/plugins
log info "Plugin Scala for IntelliJ IDEA installed succesfully"

# Change directory
cd $DATA_DIR

# 7. Download Audioscrobbler data from desired mirror
for $DATA_FILE in "${DATA_FILES[@]}"
do
	if [ ! -f $DATA_FILE ]; then
		wget $DATA_MIRROR/$DATA_FILE
		log info "Downloaded file $DATA_FILE into $DATA_DIR"
	fi
done

# 8. Open IntelliJ IDEA in background
log info "Opening IntelliJ IDEA development tool."
$INSTALLS_DIR/idea/bin/idea.sh
