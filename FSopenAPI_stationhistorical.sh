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
# run this script to retrieve historical KPI from your plant.  #
# Include API-Username and Password a.k.a systemCode           #
# in FSopenAPI.conf                                            #
################################################################

# read config
script_dir=$(dirname "$0")
. "$script_dir/FSopenAPI.conf"

# Initialize flags
writetodatabase=false
collecttimeindividual=false
verbose=false

# Function to display help message
display_help() {
    echo ""
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -s        Inject into MySQL (optional)"
    echo "            Add Login Credentials in FSopenAPI.conf"
    echo "  -i <Int>  Interval (mandatory)"
    echo "            1 = hourly"
    echo "            2 = daily"
    echo "            3 = monthly"
    echo "            4 = yearly"
    echo ""
    echo "            provide multiple values comma-separated (,)"
    echo ""
    echo "  -d        Enter Date of Data to retrieved (optional)"
    echo "            Format to be used YYYY-MM-DD (even when requesting monthly or yearly data!)"
    echo ""
    echo "  -v        verbose output (optional)"
    echo "  -h        display this help page"
    exit 0
}
# Check if the script is started with the -h flag
if [[ "$1" == "-h" ]]; then
    display_help
fi

# Check parameters
while getopts ":i:d:svh" opt; do
  case $opt in
    h)
      display_help
      ;;
    i)
      interval=$OPTARG
      ;;
    d)
      collecttimeindividual="$OPTARG"
      ;;
    s)
      writetodatabase=true
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
if [ -z "${interval}" ]; then
    echo "Error: Missing integer value(s) for -i flag." >&2
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

# retrieve historical KPI, assuming only one Plant
# Get the current hour timestamp, reset minutes and seconds to zero and calculate in milliseconds
current_hour_timestamp=$(date -d "now" +%s)
current_hour_timestamp=$(date -d @$current_hour_timestamp +"%Y-%m-%d %H:00:00")
current_hour_timestamp_ms=$(date -d "$current_hour_timestamp" +%s%3N)

log_verbose ""
log_verbose "Set collectTime:"

if [[ "$collecttimeindividual" == "false" ]]; then
	collecttime=$current_hour_timestamp_ms
	log_verbose "Use actual date: ${current_hour_timestamp}, in Milliseconds/ Epochtime: ${collecttime}"
else
	collecttimeindividual_ms=$(date -d "$collecttimeindividual" +%s%3N)
	collecttime=$collecttimeindividual_ms
	log_verbose "Use historical date: ${collecttimeindividual}, in Milliseconds/ Epochtime: ${collecttime}"
fi

# Split the comma-separated list of integers
IFS=',' read -ra values_array <<< "$interval"

# loop through deviceTypeID's and get RealtimeKPI per Device
for value in "${values_array[@]}"; do
	case $value in
	1)
		URL="${hourlyURL}"
		table="${mysql_table_prefix}kpihourly"
		intervalstring="hourly"
		;;
	2)
		URL="${dailyURL}"
		table="${mysql_table_prefix}kpidaily"
		intervalstring="daily"
		;;

	3)
		URL="${monthlyURL}"
		table="${mysql_table_prefix}kpimonthly"
		intervalstring="monthly"
		;;
	4)
		URL="${yearlyURL}"
		table="${mysql_table_prefix}kpiyearly"
		intervalstring="yearly"
		;;
	esac

	returnhist=$(curl -s -X POST  "${URL}" \
	     -H "Content-Type: application/json" \
	     -H "XSRF-Token: ${token}" \
	     -d "{\"stationCodes\": \"${plant_code}\",\"collectTime\": \"${collecttime}\"}")

	log_verbose "${intervalstring} KPI Station output:"
	echo "${returnhist}"
	echo ""

	#write to Database if flag is set
	log_verbose "WriteToDatabase Flag is set to: ${writetodatabase}"
	log_verbose "True  = continuing with writing to Database"
	log_verbose "False = no further execution needed. Logging out"
	if [[ "$writetodatabase" == "true" ]]; then
		log_verbose "Parse JSON data and construct MySQL query"
		if [[ "$interval" == 1 ]]; then
			query="INSERT INTO $table (collectTime, stationCode, radiation_intensity, power_profit, theory_power, ongrid_power, inverter_power) VALUES "
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
		else
			query="INSERT INTO $table (collectTime,stationCode,inverter_power,selfUsePower,power_profit,perpower_ratio,reduction_total_co2,chargeCap,selfProvide,dischargeCap,installed_capacity,use_power,reduction_total_coal,ongrid_power,buyPower) VALUES "
			while IFS= read -r line; do
		            #Extract fields from JSON
			    collectTime=$(echo "$line" | jq -r '.collectTime')
			    #construct readable timestamp
		            collectTimeReadable=$(timestamp_to_readable "$collectTime")
			    stationCode=$(echo "$line" | jq -r '.stationCode')
			    inverter_power=$(echo "$line" | jq -r '.dataItemMap.inverter_power')
			    selfUsePower=$(echo "$line" | jq -r '.dataItemMap.selfUsePower')
			    power_profit=$(echo "$line" | jq -r '.dataItemMap.power_profit')
			    perpower_ratio=$(echo "$line" | jq -r '.dataItemMap.perpower_ratio')
			    reduction_total_co2=$(echo "$line" | jq -r '.dataItemMap.reduction_total_co2')
			    chargeCap=$(echo "$line" | jq -r '.dataItemMap.chargeCap')
			    selfProvide=$(echo "$line" | jq -r '.dataItemMap.selfProvide')
			    dischargeCap=$(echo "$line" | jq -r '.dataItemMap.dischargeCap')
			    installed_capacity=$(echo "$line" | jq -r '.dataItemMap.installed_capacity')
			    use_power=$(echo "$line" | jq -r '.dataItemMap.use_power')
			    reduction_total_coal=$(echo "$line" | jq -r '.dataItemMap.reduction_total_coal')
			    ongrid_power=$(echo "$line" | jq -r '.dataItemMap.ongrid_power')
			    buyPower=$(echo "$line" | jq -r '.dataItemMap.buyPower')
			    query+="('$collectTimeReadable', '$stationCode', $inverter_power, $selfUsePower, $power_profit, $perpower_ratio, $reduction_total_co2, $chargeCap, $selfProvide, $dischargeCap, $installed_capacity, $use_power, $reduction_total_coal, $ongrid_power, $buyPower),"

			done < <(echo "$returnhist" | jq -c '.data[]')

			# Remove the trailing comma and space
			query="${query%,}"

			# Use "ON DUPLICATE KEY UPDATE" to update existing entries
			query+=" ON DUPLICATE KEY UPDATE 
			    inverter_power = VALUES(inverter_power),
			    selfUsePower = VALUES(selfUsePower),
			    power_profit =VALUES(power_profit),
			    perpower_ratio = VALUES(perpower_ratio),
			    reduction_total_co2 = VALUES(reduction_total_co2),
		  	    chargeCap = VALUES(chargeCap),
			    selfProvide = VALUES(selfProvide),
			    dischargeCap = VALUES(dischargeCap),
			    installed_capacity = VALUES(installed_capacity),
			    use_power = VALUES(use_power),
			    reduction_total_coal = VALUES(reduction_total_coal),
			    ongrid_power = VALUES(ongrid_power),
			    buyPower = VALUES(buyPower);"

		fi

		# Execute MySQL query
		log_verbose "run MySQL-Client and execute INSERT-query"
		mysql --silent -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" -e "$query"
	fi
done

# close session
closesession=$(curl -s -X POST  "${logoutURL}" \
     -H "Content-Type: application/json" \
     -d "{\"xsrfToken\": \"${token}\"}")

log_verbose "Logout Result:"
log_verbose "${closesession}"


