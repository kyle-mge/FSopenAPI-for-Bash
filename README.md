# Prologue
This Scriptset reads Data via the openAPI-Interface from Huawei FusionSolar.


# Configuration
## Install Prerequisites
The Scriptset needs cURL, jq and mysql. To install simply run

```sudo apt install curl jq mysql-client```

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
If you plan to store your Data in a MySQL-Database, run the Script ```"./FSopenAPI_createDBtables.sh"``` once to create the necessary tables.


# Usage
For testing purposes, run the Scripts with the flag ```"./FSopenAPI_<Script>.sh -v"``` to get verbose output.

## In General
Run the scripts on a linux-system (tested with Ubuntu) automated with crontab or through a Home-Automation-System like openhab. The output is a/ multiple JSON-String(s) for further storing and/ or visualising data.

## Realtime Data
Run the Script ```"./FSopenAPI_RealtimeKPI.sh"``` to get realtime Data from your Plant. The data usually is updated every 5 minutes. According to the openAPI-Documentation, request-freqency should not exceed one minute. You might block your openAPI-Account!

The Script ```"./FSopenAPI_deviceRealKPI.sh"``` needs to get started with the flag ```-d``` and one or several Integer-Values. Multiple values need to be seperated by comma (,). According to the Huawei Documentation of the interface, the following values are possible (only if installed!):

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

Further information to be found at https://support.huawei.com/enterprise/en/doc/EDOC1100261860/c2b572a8/device-list-interface

## Historical Data
### Historical Station Data - Hourly
Run the Script ```"./FSopenAPI_stationHourly.sh"``` to gather hourly data from your plant. Data will be at least OnGrid-Power and Inverter-Power summarized per hour. Use the optional flag  ```-s``` to inject your data directly into MySQL-Database (read "Configuration" first!). As the API is providing the data from the whole day, it is possible to run the script just once at the end of the day. Be aware of running the script in maximum every hour as you might block your Account!

## Output
All Scripts output the results as delivered by openAPI in json-Format for further usage like storing in a Database, handing over to Smart-Home-Systems etc.


## Work in progress
Use the Scripts ```"./FSopenAPI_histDaily.sh"```, ```"./FSopenAPI_histMonthly.sh"``` or ```"./FSopenAPI_histYearly.sh"``` to retrieve historical Data on hourly/ daily/ monthly/ yearly basis.
