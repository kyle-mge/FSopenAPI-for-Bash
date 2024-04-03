#!/bin/bash
################################################################
# Matthias Grobe                                               #
# April 2024, version 1.0                                      #
# changelog                                                    #
#                                                              #
# version 1.0:                                                 #
# - Creation of the FSopenAPI-Scripts                          #
#                                                              #
#                                                              #
################################################################
# FSopenAPI_getToken.sh                                        #
#                                                              #
# run this script once to retrieve the XSRF-Token              #
# paste the Token in the FSopenAPI.conf in the Token-Section.  #
# Without the token, you won't be able to gather data          #
# from your plant.                                             #
################################################################

. ./FSopenAPI.conf
loginURL="${URL}${URLlogin}"

echo ""
echo "Fusionsolar openAPI-Tool"
echo "Matthias Grobe"
echo "version 1.0, April 2024"
echo ""
echo "Requesting Token from ${loginURL}:"
echo ""

returnjson=$(curl -X POST "${loginURL}" \
     -H "Content-Type: application/json" \
     -d "{\"userName\": \"${userName}\",\"systemCode\": \"${systemCode}\"}")

if jq -e . >/dev/null 2>&1 <<<"${returnjson}"; then
    echo ""
    echo "Parsed JSON successfully and got something other than false/null"

    success=$(jq -n --argjson data "${returnjson}" '$data.success')
    token=$(jq -n --argjson data "${returnjson}" '$data.token')

    echo ""
    echo "Result:"
    echo ""
    echo "json-raw: ${returnjson}"
    echo "Success: ${success}"
    echo "XSRF-Token: ${token}"
    echo ""
    echo "If the Result is other than true and/ or XSRF-Token is empty or Null, check Credentials in FSopenAPI.conf and/or Message from json-raw!"
    echo "paste XSRF-Token in FSopenAPI.conf to gather the desired data."
    echo ""

else
    echo "Failed to parse JSON, or got false/null"
    echo "Check Credentials and URL" 
fi

