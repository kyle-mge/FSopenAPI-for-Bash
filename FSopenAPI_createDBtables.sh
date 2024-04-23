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

# Table creation query
create_table_query="CREATE TABLE IF NOT EXISTS ${tablehourly} (
    collectTime DATETIME NOT NULL,
    stationCode VARCHAR(255) NOT NULL,
    radiation_intensity FLOAT,
    power_profit FLOAT,
    theory_power FLOAT,
    ongrid_power FLOAT,
    inverter_power FLOAT,
    PRIMARY KEY (collectTime, stationCode)
);"

# Execute MySQL query to create table
createhourly=$(mysql --silent -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" -e "$create_table_query")


# Query to check if the table exists
check_table_query="SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$mysql_database' AND TABLE_NAME='${tablehourly}';"
table_count=$(mysql --silent -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" -e "$check_table_query")

# Check if the table count is greater than 0
if [ "$table_count" -gt 0 ]; then
    echo "Creation successful!"
    echo "Table ${tablehourly} exists."
else
    echo "Creation failed!!!"
    echo "Table ${table_name} does not exist."
    echo "Check MySQL-Database and Login Credentials!"
fi
