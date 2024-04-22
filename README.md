# FSopenAPI
Read Data through Huawei FusionSolar openAPI

# Prologue
This Scriptset reads Data via the openAPI-Interface from Huawei FusionSolar.

# Configuration
## Edit the FSopenAPI.conf with your specific Data
Update the Login-credentials and enter your Username and Systemcode (aka Password). You need to create a Northbound API-Account first through Fusionsolar. Ask your Installer, if you do not have Administrator-Rights for your plant.
In standard usage, the Scripts request data from the European-FusionSolar-Servers, in case, you registered your FusionSolar-Account on any other FusionSolar-Server, update the URL in the FSopenAPI.conf-File accordingly (e.g. to "https://sg5.fusionsolar.huawei.com/thirdData" if you registered your account on the Middle-East & Africa-Server).
Normally there's no need to adjust any other Variables according to the URL's.

The Scripts are designed to read one plant only! It's not designed to read multiple plants with single requests!

# Usage
## Realtime Data
Run the Script ```"./FSopenAPI_RealtimeKPI.sh"``` to get realtime Data from your Plant. The data usually is updated every 5 minutes. According to the openAPI-Documentation, request-freqency should not exceed one minute. You might block your openAPI-Account!
For testing purposes, run the Script with ```"./FSopenAPI_RealtimeKPI.sh -v"``` to get verbose output.

## Historical Data
Use the Scripts ```"./FSopenAPI_histHourly.sh"```, ```"./FSopenAPI_histDaily.sh"```, ```"./FSopenAPI_histMonthly.sh"``` or ```"./FSopenAPI_histYearly.sh"``` to retrieve historical Data on hourly/ daily/ monthly/ yearly basis.

## Output
All Scripts output the results as delivered by openAPI in json-Format for further usage like storing in a Database, handing over to Smart-Home-Systems etc.
