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
# FSopenAPI_dongleRealKPI.sh                                   #
#                                                              #
# run this script to retrieve Realtime KPI from your plant.    #
# This Script collects the Data from the Dongle                #
# Include API-Username and Password a.k.a systemCode           #
# in FSopenAPI.conf                                            #
################################################################

# read config
script_dir=$(dirname "$0")
. "$script_dir/FSopenAPI.conf"

# Function to display help message
display_help() {
    echo ""
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -d <int>  DeviceID as Integer value. (mandatory)"
    echo "             1 = string inverter"
    echo "             2 = smart logger"
    echo "            39 = battery"
    echo "            40 = backup box"
    echo "            47 = power sensor"
    echo "            62 = Dongle"
    echo ""
    echo "            provide multiple values comma-separated (,)"
    echo "            for further DeviceIDs refer to Huawei Documentation"
    echo ""
    echo "  -v        verbose output (optional)"
    echo "  -h        this help page"
    exit 0
}


# Initialize verbose flag
verbose=false
device=1

# Check if the script is started with the -h flag
if [[ "$1" == "-h" ]]; then
    display_help
fi

# Command-Line Options
while getopts ":d:vh" opt; do
  case $opt in
    h)
      display_help
      ;;
    d)
      deviceid=$OPTARG
      ;;
    v)
      verbose=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_help
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      display_help
      ;;
  esac
done
shift $((OPTIND -1))

# Check if -d flag is provided and integer value is present
if [ -z "${deviceid}" ]; then
    echo "Error: Missing integer value(s) for -d flag." >&2
    display_help
fi

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

# get Device List, assuming only one Plant
returndevlist=$(curl -s -X POST  "${devlistURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"stationCodes\": \"${plant_code}\"}")

log_verbose "GetDeviceList output:"
log_verbose "${returndevlist}"

# Split the comma-separated list of integers
IFS=',' read -ra values_array <<< "$deviceid"

# loop through deviceTypeID's and get RealtimeKPI per Device
for value in "${values_array[@]}"; do
	deviceDN=""
	deviceName=""
	log_verbose "DeviceID to be processed: ${value}"
	deviceDN=$(echo "${returndevlist}" | jq -r --arg devid "$value" '.data[] | select(.devTypeId == ($devid | tonumber)) | .devDn')
	deviceName=$(echo "${returndevlist}" | jq -r --arg devid "$value" '.data[] | select(.devTypeId == ($devid | tonumber)) | .devName')
	log_verbose "DeviceName of Device: ${deviceName}"
	log_verbose "DeviceDN of Device: ${deviceDN}"
	log_verbose ""

	# retrieve Device RealtimeKPI, assuming only one Plant
	returndevrealtime=$(curl -s -X POST  "${devrealkpiURL}" \
	     -H "Content-Type: application/json" \
	     -H "XSRF-Token: ${token}" \
	     -d "{\"devIds\":\"${deviceDN}\",\"devTypeId\":\"${value}\"}")

	log_verbose "Realtime Device output:"
	echo "${returndevrealtime}"
	echo ""
done

# close session
closesession=$(curl -s -X POST  "${logoutURL}" \
     -H "Content-Type: application/json" \
     -d "{\"xsrfToken\": \"${token}\"}")

log_verbose "Logout Result:"
log_verbose "${closesession}"


