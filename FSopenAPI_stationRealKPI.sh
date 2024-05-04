#!/bin/bash
################################################################
# Matthias Grobe                                               #
# https://github.com/kyle-mge/FSopenAPI                        #
# April 2024, version 1.0                                      #
# changelog                                                    #
#                                                              #
# version 1.0:                                                 #
# - Creation of the FSopenAPI-Scripts                          #
#                                                              #
#                                                              #
################################################################
# FSopenAPI_stationRealKPI.sh                                  #
#                                                              #
# run this script to retrieve Realtime KPI from your plant.    #
# Include API-Username and Password a.k.a systemCode           #
# in FSopenAPI.conf                                            #
################################################################

# read config
script_dir=$(dirname "$0")
. "$script_dir/FSopenAPI.conf"

# Initialize verbose flag
verbose=false

# Function to display help message
display_help() {
    echo ""
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -v     verbose output (optional)"
    echo "  -h     display this help page"
    exit 0
}
# Check if the script is started with the -h flag
if [[ "$1" == "-h" ]]; then
    display_help
fi


# Check parameters
while getopts ":vh" opt; do
  case $opt in
    h)
      display_help
      ;;
    v)
      verbose=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Shift command line arguments to process non-option arguments
shift $((OPTIND -1))

# Function to echo only if verbose mode is enabled
log_verbose() {
  if [ "$verbose" = true ]; then
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1"
  fi
}
# Function to echo always verbose mode and silent
log_always() {
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1"
}




log_verbose ""
log_verbose "Fusionsolar openAPI-Tool"
log_verbose "Matthias Grobe"
log_verbose "version 1.0, April 2024"
log_verbose ""
log_verbose "Requesting Token from ${loginURL}..."

# retrieve xsrf-token through cURL-Request
returntoken=$(curl -s -D - -o /dev/null  "${loginURL}" \
     -H "Content-Type: application/json" \
     -d "{\"userName\": \"${userName}\",\"systemCode\": \"${systemCode}\"}") 

# output cURL-Header-Response and extract XSRF-Token
log_verbose "cURL output:"
log_verbose "${returntoken}"
log_verbose "_____________________________________________________________________"
log_verbose "extract Token:"
token=$(echo "${returntoken}" | grep "xsrf-token" | awk -F ':' '{print $2}')
log_verbose "XSRF-Token: ${token}"
log_verbose ""
tokenlength=$(echo "${token}" | wc -c)
log_verbose "Token-Length/ qty of Characters: ${tokenlength}"

if (( tokenlength < 80 )); then
	echo "Tokenlength not valid"
	echo "Check cURL-Output from Login"
	echo "and Login-Credentials!"
	echo "Stopping further Script-Execution!"
	exit 1
fi

log_verbose "_____________________________________________________________________"
log_verbose " get PlantCode..."
log_verbose ""
# retrieve plantCode, assuming only one Plant
returnplant=$(curl -s -X POST  "${stationURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"pageNo\": \"1\"}")

log_verbose "Station output:"
log_verbose "${returnplant}"
log_verbose ""
plant_code=$(echo "${returnplant}" | jq -r '.data.list[0].plantCode')
log_verbose "plantCode: ${plant_code}"
log_verbose ""

# retrieve RealtimeKPI, assuming only one Plant
returnrealtime=$(curl -s -X POST  "${realtimeURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"stationCodes\": \"${plant_code}\"}")

log_verbose "Realtime Station output:"
echo "${returnrealtime}"
echo ""

# close session
closesession=$(curl -s -X POST  "${logoutURL}" \
     -H "Content-Type: application/json" \
     -d "{\"xsrfToken\": \"${token}\"}")

log_verbose "Logout Result:"
log_verbose "${closesession}"


