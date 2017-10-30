# Script to deploy development environment for this project.

# ==============================================================================================================
# Parameters
# ==============================================================================================================

# Name of the project container folder
PROJECTS_LOCATION=~/www
# Software installation folder
INSTALLS_DIR=~/opt
# Data directory
DATA_DIR=~/data
# Libs location
LIBS_LOCATION=~/www/musicrecommender/libs

# ==============================================================================================================
# Aux functions
# ==============================================================================================================

# Function for logging
# Parameters:
# - $1: Log type
# - $2: Log message
log () {
	echo ""
	tput setaf 4
	echo "[$1] $2"
	tput sgr0
	echo ""
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
sudo apt-get install git

# 2. Make directory project location (if not present yet)
if [ ! -d $PROJECTS_LOCATION ]; then
	mkdir $PROJECTS_LOCATION
fi

# Change directory
cd $PROJECTS_LOCATION

# 3. Download recommender project (or git pull if present)
if [ ! -d musicrecommender-reference ]; then
	git clone git@github.com:sryza/aas.git
	mv aaa musicrecommender-reference
	log info "Code for music recommender from @sryza copied to $PROJECTS_LOCATION/musicrecommender-reference."
else
	cd musicrecommender-reference
	git pull
	cd ..
	log info "Code for music recommender from @sryza in $PROJECTS_LOCATION/musicrecommender-reference updated."
fi

# 4. Download custom project (or git pull if present)
if [ ! -d musicrecommender ]; then
	git clone git@github.com:angelmunozs/musicrecommender.git
	log info "Code for music recommender from @angelmunozs copied to $PROJECTS_LOCATION/musicrecommender."
else
	cd musicrecommender
	git pull
	cd ..
	log info "Code for music recommender from @angelmunozs in $PROJECTS_LOCATION/musicrecommender updated."
fi

# Change directory
cd $INSTALLS_DIR

# 5. Download IntelliJ IDEA 2.5 if not present and create alias in .bashrc
if [ ! -d $INSTALLS_DIR/idea-IC-172.4343.14 ]; then
	wget https://download.jetbrains.com/idea/ideaIC-2017.2.5.tar.gz
	tar -zxvf ideaIC-2017.2.5.tar.gz
	rm ideaIC-2017.2.5.tar.gz
	ln -sf idea-IC-172.4343.14 idea
	log info "IntelliJ IDEA downloaded and installed in $INSTALLS_DIR/idea-IC-172.4343.14."
fi

# 6. Install Apache Spark
if [ ! -d $INSTALLS_DIR/idea-IC-172.4343.14 ]; then
	wget http://apache.rediris.es/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz
	tar -zxvf spark-2.2.0-bin-hadoop2.7.tgz
	rm spark-2.2.0-bin-hadoop2.7.tgz
	ln -s spark-2.2.0-bin-hadoop2.7 spark
	log info "Apache Spark downloaded and installed in $INSTALLS_DIR/spark-2.2.0-bin-hadoop2.7."
fi

# 7. Install Scala plugin for IDEA
cp -r $LIBS_LOCATIONlibs/Scala ./idea/plugins
log info "Plugin Scala for IntelliJ IDEA installed succesfully"

# Change directory
cd $DATA_DIR

# 8. Download Audioscrobbler data
# TODO (http://www-etud.iro.umontreal.ca/~bergstrj/audioscrobbler_data.html seems to be down)

# 9. Open IntelliJ IDEA in background
$INSTALLS_DIR/idea/bin/idea.sh &
log info "Opening IntelliJ IDEA development tool."
