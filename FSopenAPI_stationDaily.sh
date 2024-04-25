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
#                                                              #
# run this script to historical KPI from your plant.           #
# Include API-Username and Password a.k.a systemCode           #
# in FSopenAPI.conf                                            #
################################################################

# read config
. ./FSopenAPI.conf

# Initialize flags
writetodatabase=false
verbose=false

# Function to display help message
display_help() {
    echo ""
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -s     Inject into MySQL (optional)"
    echo "         Add Login Credentials in conf"
    echo "  -v     verbose output (optional)"
    echo "  -h     display this help page"
    exit 0
}
# Check if the script is started with the -h flag
if [[ "$1" == "-h" ]]; then
    display_help
fi

# Check parameters
while getopts ":svh" opt; do
  case $opt in
    h)
      display_help
      ;;
    s)
      writetodatabase=true
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

# Function to convert timestamp to human-readable time
timestamp_to_readable() {
    local timestamp_ms="$1"
    local timestamp_sec=$((timestamp_ms / 1000))
    date -d "@$timestamp_sec" "+%Y-%m-%d %H:%M:%S"
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

# retrieve dailyKPI, assuming only one Plant
# Get the current hour timestamp, reset minutes and seconds to zero and calculate in milliseconds
current_hour_timestamp=$(date -d "now" +%s)
current_hour_timestamp=$(date -d @$current_hour_timestamp +"%Y-%m-%d %H:00:00")
current_hour_timestamp_ms=$(date -d "$current_hour_timestamp" +%s%3N)

returnhist=$(curl -s -X POST  "${dailyURL}" \
     -H "Content-Type: application/json" \
     -H "XSRF-Token: ${token}" \
     -d "{\"stationCodes\": \"${plant_code}\",\"collectTime\": \"${current_hour_timestamp_ms}\"}")

log_verbose "daily KPI Station output:"
echo "${returnhist}"
echo ""

#write to Database if flag is set
log_verbose "WriteToDatabase Flag is set to: ${writetodatabase}"
if [[ "$writetodatabase" == "true" ]]; then
	# Parse JSON data and construct MySQL query
	log_verbose "Parse JSON data and construct MySQL query"

	query="INSERT INTO ${mysql_table_prefix}kpidaily (collectTime, stationCode, radiation_intensity, power_profit, theory_power, ongrid_power, inverter_power) VALUES "
	while IFS= read -r line; do
	    collectTime=$(echo "$line" | jq -r '.collectTime')
            collectTimeReadable=$(timestamp_to_readable "$collectTime")
	    stationCode=$(echo "$line" | jq -r '.stationCode')
	    radiation_intensity=$(echo "$line" | jq -r '.dataItemMap.radiation_intensity')
	    power_profit=$(echo "$line" | jq -r '.dataItemMap.power_profit')
	    theory_power=$(echo "$line" | jq -r '.dataItemMap.theory_power')
	    ongrid_power=$(echo "$line" | jq -r '.dataItemMap.ongrid_power')
	    inverter_power=$(echo "$line" | jq -r '.dataItemMap.inverter_power')
	    query+="('$collectTimeReadable', '$stationCode', $radiation_intensity, $power_profit, $theory_power, $ongrid_power, $inverter_power),"
	done < <(echo "$returnhist" | jq -c '.data[]')

	# Remove the trailing comma and space
	query="${query%,}"

	# Use "ON DUPLICATE KEY UPDATE" to update existing entries
	query+=" ON DUPLICATE KEY UPDATE 
        	    radiation_intensity = VALUES(radiation_intensity),
	            power_profit = VALUES(power_profit),
        	    theory_power = VALUES(theory_power),
	            ongrid_power = VALUES(ongrid_power),
        	    inverter_power = VALUES(inverter_power);"

	# Execute MySQL query
	log_verbose "run MySQL-Client and execute INSERT-query"
	mysql --silent -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" -e "$query"
fi


# close session
closesession=$(curl -s -X POST  "${logoutURL}" \
     -H "Content-Type: application/json" \
     -d "{\"xsrfToken\": \"${token}\"}")

log_verbose "Logout Result:"
log_verbose "${closesession}"


