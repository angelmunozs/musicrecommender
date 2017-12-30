# ==============================================================================================================
# Common parameters
# ==============================================================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Green tick
ICON_SUCCESS="$GREEN✔$NC"
ICON_ERROR="$RED✖$NC"

# ==============================================================================================================
# Common functions
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
