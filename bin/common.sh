# ==============================================================================================================
# Common parameters
# ==============================================================================================================

# Name of the project container folder
PROJECTS_LOCATION=~/www
# Software installation folder
INSTALLS_DIR=/opt

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
