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
. ./FSopenAPI.conf

tablehourly="${mysql_table_prefix}kpihourly"
tabledaily="${mysql_table_prefix}kpidaily"
tablemonthly="${mysql_table_prefix}kpimonthly"
tableyearly="${mysql_table_prefix}kpiyearly"
tables="${tablehourly},${tabledaily},${tablemonthly},${tableyearly}"

# Split the comma-separated list of integers
IFS=',' read -ra values_array <<< "$tables"

# loop through tables and create table if not exist
for value in "${values_array[@]}"; do
	echo ""
	echo "Create ${value}..."
	echo ""
	# Table creation query
	create_table_query="CREATE TABLE IF NOT EXISTS ${value} (collectTime DATETIME NOT NULL,stationCode VARCHAR(255) NOT NULL,radiation_intensity FLOAT,power_profit FLOAT,theory_power FLOAT,ongrid_power FLOAT,inverter_power FLOAT,PRIMARY KEY (collectTime, stationCode));"

	# Execute MySQL query to create table
	create=$(mysql -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" -e "$create_table_query")

	# Query to check if the table exists
	echo "Check table creation"
	echo ""
	check_table_query="SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$mysql_database' AND TABLE_NAME='${value}';"
	table_count=$(mysql --silent -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" -e "$check_table_query")

	echo "Table Count: ${table_count}"

	# Check if the table count is greater than 0
	if [ "$table_count" -gt 0 ]; then
	    echo "Creation successful!"
	    echo "Table ${value} exists."
	else
	    echo "Creation failed!!!"
	    echo "Table ${value} does not exist."
	    echo "Check MySQL-Database and Login Credentials!"
	fi
	echo "___________________________________________________________"
done
