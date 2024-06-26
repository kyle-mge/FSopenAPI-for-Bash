# Prologue
This Scriptset reads Data via the openAPI/ Northbound-Interface from Huawei FusionSolar. It only needs a linux bash, cURL and jq. No need to install Python or other languages.

# Disclaimer
- I did not nor do I plan to implement any functions to catch errors while requesting the data. If the API is not responding, credentials aren't working/ are blocked etc., the scripts will not catch any data or might crash.
- If Huawei decides to change structures or add/ remove datafields, the queries will might crash. SQL-Queries are more or less hardcoded based on the data provided by the API and my plant (SUN2000 8KTL-M1).
- I do not garantuee any functionality, safety or security (Passwords might be easily gathered, so be wise in using accounts with least amount of access rights, secure the .conf-File against 
unauthorized access, etc.). Primarily I created these scripts for my needs.
- Last but not least: if you're keen on contributing in the development, feel free to contact me.

# Configuration
## Install Prerequisites
The Scriptset needs cURL, jq and mysql (mysql is only needed if you want to directly store the data in a MySQL-Database). To install simply run

```sudo apt install curl jq mysql-client```.

Please be aware that I won't explain how to set up the MySQL-Database-Server. There's plenty of instructions and how-to's in the internet. I assume that- if you want to store your data in MySQL, that you have a MySQL-Server already up and running.

## Edit the FSopenAPI.conf with your specific Data
Update the Login-credentials and enter your Username and Systemcode (aka Password). You need to create a Northbound API-Account first through Fusionsolar. Ask your Installer, if you do not have Administrator-Rights for your plant.

```bash
userName="<your_northbound_api_username>"
systemCode="<your_northbound_api_password"
```

In standard usage, the Scripts request data from the European-FusionSolar-Servers, in case, you registered your FusionSolar-Account on any other FusionSolar-Server, update the URL in the FSopenAPI.conf-File accordingly (e.g. to "https://sg5.fusionsolar.huawei.com/thirdData" if you registered your account on the Middle-East & Africa-Server).
Normally there's no need to adjust any other Variables according to the URL's.

The Scripts are designed to read one plant only! It's not designed to read multiple plants with single requests!

Add your MySQL-Server Login Credentials if you plan to inject your Data directly into a MySQL-Database as follows:

```bash
mysql_host="<mysql_host>"
mysql_user="<mysql_user>"
mysql_password="<mysql_password>"
mysql_database="<´mysql_database>"
mysql_table_prefix="FSopenAPI_"
```

## Create Database Tables (optional)
If you plan to store your Data in a MySQL-Database, run the Script ```"./FSopenAPI_createDBtables.sh"``` once to create the necessary tables. It will create tables for storing the historical station/ plant Data for hourly, daily, monthly and yearly Data.


# Usage
## In General
For testing purposes, run the Scripts with the flag ```-v``` to get verbose output.

Run the scripts on a linux-system (tested with Ubuntu) automated with crontab or through a Smart-Home-System like OpenHAB. The output is a/ multiple JSON-String(s) for further storing and/ or visualising data.

## Realtime Data
Run the Script ```"./FSopenAPI_RealtimeKPI.sh"``` to get realtime Data from your Plant. The data usually is updated every 5 minutes. According to the openAPI-Documentation, request-freqency should not exceed one minute. You might block your openAPI-Account!

The Script ```"./FSopenAPI_deviceRealKPI.sh"``` needs to get started with the flag ```-d``` and one or several Integer-Values. Multiple values need to be seperated by comma (,). According to the Huawei Documentation of the interface, the following values are possible (only if installed!):

```
1: string inverter
2: SmartLogger
8: STS
10: EMI
13: protocol converter
16: general device
17: grid meter
22: PID
37: Pinnet data logger
38: residential inverter
39: battery
40: backup box
41: ESS
45: PLC
46: optimizer
47: power sensor
62: Dongle
63: distributed SmartLogger
70: safety box
```

#### Example: 

Run ```./FSopenAPI_deviceRealKPI.sh -d 1,39,47``` to gather data from your inverter, the battery and the power sensor.

Further information to be found in the Huawei Documentation at https://support.huawei.com/enterprise/en/doc/EDOC1100261860/c2b572a8/device-list-interface

## Historical Data
### Historical Station Data
Run the Script ```"./FSopenAPI_stationhistorical.sh"``` to gather hourly, daily, monthly and/ or yearly data from your plant. Data will be at least OnGrid-Power and Inverter-Power summarized per hour and way more information for the daily/ monthly/ yearly requests. Use the optional flag  ```-s``` to inject your data directly into MySQL-Database (read "Configuration" first!). As the API is providing the data from the whole day, it is possible to run the script just once at the end of the day. Be aware of running the script in maximum every hour as you might block your Account!

Use the flag ```-i``` and add one ore multiple Integer values as follows. Multiple values need to be seperated by comma (,).
```
1: request hourly historical Data
2: request daily historical Data
3: request monthly historical Data
4: request yearly historical Data
```

Use ```-d``` followed by the Date in the format YYYY-MM-DD to pull data from the given date. If you pull monthly or yearly data, still use the full date (including the day), otherwise you wont't get any data as the date will be invalid for the script. 
Hint: if you requesting yearly or monthly historical data, it doesn't matter whether you request from the beginning or end of the month/ year. The historical data will be the same.

Extend the ```-d``` flag with an ```-e``` flag and use ```-d``` as start date and ```-e``` Flag as end date. The standard range is one day and you'll pull a request for every single day between ```-d``` and ```-e```. ATTENTION: still use small ranges per request, as you'll might block yor API-Account. 
Hint: as requesting the daily historical data, the API always answers with the data for the whole month. To reduce requests for historical data, use ```-d``` and ```-e``` with the flag ```-m``` as a multiplicator in days. Example: use ```-d 2024-01-01 -e 2024-05-01 -m 31``` to send 5 requests where the answers include the daily historical data from whole months for January in first request until May in fifth request.

#### Examples:
```./FSopenAPI_stationhistorical.sh -s -i 2``` to gather the daily historical data and store in Database

```./FSopenAPI_stationhistorical.sh -s -i 2 -d 2024-01-01``` to gather the daily historical data from January 1st of 2024 and store in Database

```./FSopenAPI_stationhistorical.sh -i 2,3``` to gather the daily and monthly historical data but do not store in Database and only output the data as json-Strings.

Be aware: If Data is already available in the database, the existing entry will be updated!

## Output
All Scripts output the results as delivered by openAPI in json-Format for further usage like storing in a Database, handing over to Smart-Home-Systems etc.


# Work in progress
- long term: historical data from Devices + store in Database
