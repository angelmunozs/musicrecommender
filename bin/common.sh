#!/bin/bash
# ==============================================================================================================
# Common parameters
# ==============================================================================================================

# Project parameters
PROJECT_NAME=musicrecommender
PROJECT_VERSION=1.0

# Software parameters
SCALA_SHORT_VERSION=2.11
SCALA_VERSION=$SCALA_SHORT_VERSION.12
SPARK_VERSION=2.2.0
SBT_VERSION=1.0.4

# Name of the project container folder
PROJECTS_LOCATION=~/www
# Software installation folder
INSTALLS_DIR=/opt
# Where the local data is stored
LOCAL_DATA_DIR=$PROJECTS_LOCATION/$PROJECT_NAME/data

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Green tick
ICON_SUCCESS="$GREEN""✔""$NC"
ICON_ERROR="$RED""✖""$NC"
ICON_INFO="$YELLOW""ℹ""️$NC"

# ==============================================================================================================
# Regenerate build.sbt
# ==============================================================================================================

echo "name := \"$PROJECT_NAME\"" > build.sbt
echo "version := \"$PROJECT_VERSION\"" >> build.sbt
echo "scalaVersion := \"$SCALA_VERSION\"" >> build.sbt
echo "" >> build.sbt
echo "// Options" >> build.sbt
echo "connectInput in run := true" >> build.sbt
echo "" >> build.sbt
echo "// Dependencies" >> build.sbt
echo "libraryDependencies += \"org.scala-lang\" % \"scala-library\" % \"$SCALA_VERSION\"" >> build.sbt
echo "libraryDependencies += \"org.scala-lang\" % \"scalap\" % \"$SCALA_VERSION\"" >> build.sbt
echo "libraryDependencies += \"org.scala-lang\" % \"scala-compiler\" % \"$SCALA_VERSION\"" >> build.sbt
echo "libraryDependencies += \"org.apache.spark\" %% \"spark-core\" % \"$SPARK_VERSION\"" >> build.sbt
echo "libraryDependencies += \"org.apache.spark\" %% \"spark-mllib\" % \"$SPARK_VERSION\"" >> build.sbt
echo "libraryDependencies += \"org.apache.spark\" %% \"spark-sql\" % \"$SPARK_VERSION\"" >> build.sbt

# ==============================================================================================================
# Common functions
# ==============================================================================================================

# Function for logging an info message
# Parameters:
# - $1: Log message
log_info () {
    line
	echo -e "$ICON_INFO $1"
	line
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
}

# Function for printing a '=' character till the end of line
line () {
	for i in $(seq 1 $(stty size | cut -d' ' -f2)); do 
		echo -n "="
	done
	echo ""
}
