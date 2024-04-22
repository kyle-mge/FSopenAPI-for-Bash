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
. ./FSopenAPI.conf
loginURL="${URL}${URLlogin}"
logoutURL="${URL}${URLlogout}"
stationURL="${URL}${URLStation}"
devlistURL="${URL}${URLdevlist}"
devrealkpiURL="${URL}${URLdevrealkpi}"
realtimeURL="${URL}${URLrealtime}"

# Initialize verbose flag
verbose=false

# Check if the '-v' flag is provided
while getopts ":v" opt; do
  case $opt in
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

# get Device List, assuming only one Plant and get devDN from SmartMeter/ power sensor
returndevlist=$(curl -s -X POST  "${devlistURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"stationCodes\": \"${plant_code}\"}")

deviceDN=$(echo "${returndevlist}" | jq -r '.data[] | select(.devTypeId == 47) | .devDn')
log_verbose "GetDeviceList output:"
log_verbose "${returndevlist}"
log_verbose "DeviceDN of Device: ${deviceDN} (power sensor)"
log_verbose ""

# retrieve Device RealtimeKPI, assuming only one Plant
returndevrealtime=$(curl -s -X POST  "${devrealkpiURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"sns\":\"${deviceDN}\",\"devTypeID\":\"47\"}")

log_verbose "Realtime Device output (power sensor):"
echo "${returndevrealtime}"
echo ""


# get Device List, assuming only one Plant and get devDN from StringInverter
returndevlist=$(curl -s -X POST  "${devlistURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"stationCodes\": \"${plant_code}\"}")

deviceDN=$(echo "${returndevlist}" | jq -r '.data[] | select(.devTypeId == 1) | .devDn')
log_verbose "GetDeviceList output:"
log_verbose "${returndevlist}"
log_verbose "DeviceDN of Device: ${deviceDN} (string inverter)"
log_verbose ""


# retrieve Device RealtimeKPI, assuming only one Plant
returndevrealtime=$(curl -s -X POST  "${devrealkpiURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"sns\":\"${deviceDN}\",\"devTypeID\":\"1\"}")

log_verbose "Realtime Device output (StringInverter):"
echo "${returndevrealtime}"
echo ""

# close session
closesession=$(curl -s -X POST  "${logoutURL}" \
     -H "Content-Type: application/json" \
     -d "{\"xsrfToken\": \"${token}\"}")

log_verbose "Logout Result:"
log_verbose "${closesession}"


