# FSopenAPI
Read Data through Huawei FusionSolar openAPI

# Prologue
This Scriptset reads Data via the openAPI-Interface from Huawei FusionSolar.

# Configuration
## Edit the FSopenAPI.conf with your specific Data
Update the Login-credentials and enter your Username and Systemcode (aka Password).
In standard usage, the Scripts request data from the European-FusionSolar-Servers, in case, you registered your FusionSolar-Account on any other FusionSolar-Server, update the URL in the FSopenAPI.conf-File accordingly (e.g. to "https://sg5.fusionsolar.huawei.com/thirdData" if you registered your account on the Middle-East & Africa-Server).
Normally there's no need to adjust any other Variables according to the URL's

## Retrieve XSRF-Token and update in FSopenAPI.conf
At the very first usage after adding your Login-Credentials, run "./FSopenAPI_getToken.sh". In case you can access your Plant with the available Login-Credentials, you will be shown the XSRF-Token as output of the Script.
Add this Token in the FSopenAPI.conf, as this will be needed for gathering the Data from your Plant.

# Usage
## Realtime Data
Run the Script "./FSopenAPI_RealtimeKPI.sh" to get realtime Data from your Plant. The data usually is updated every 5 minutes. According to the openAPI-Documentation, request-freqency should not exceed one minute. You might block your openAPI-Account!

## Historical Data
Use the Scripts "./FSopenAPI_histHourly.sh", "./FSopenAPI_histDaily.sh", "./FSopenAPI_histMonthly.sh" or "./FSopenAPI_histYearly.sh" to retrieve historical Data on hourly/ daily/ monthly/ yearly basis.

## Output
All Scripts output the results as delivered by openAPI in json-Format for further usage like storing in a Database, handing over to Smart-Home-Systems etc.
