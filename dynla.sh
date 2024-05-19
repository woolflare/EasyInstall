#!/bin/bash

response=$(curl -s -X POST "https://p.ip.vg/?url=https://github.com/login/device/code" \
-H "Accept: application/json" \
-d "client_id=Ov23lixTcMeZpkmqNiWJ" \
-d "scope=user,repo")

device_code=$(echo $response | grep -o '"device_code":"[^"]*"' | sed -e 's/^"device_code":"//' -e 's/"$//')
user_code=$(echo $response | grep -o '"user_code":"[^"]*"' | sed -e 's/^"user_code":"//' -e 's/"$//')
verification_uri=$(echo $response | grep -o '"verification_uri":"[^"]*"' | sed -e 's/^"verification_uri":"//' -e 's/"$//')
expires_in=$(echo $response | grep -o '"expires_in":[0-9]*' | sed -e 's/^"expires_in"://')
interval=$(echo $response | grep -o '"interval":[0-9]*' | sed -e 's/^"interval"://')

echo "
 ______   __   __  __    _        ___      _______ 
|      | |  | |  ||  |  | |      |   |    |   _   |
|  _    ||  |_|  ||   |_| |      |   |    |  |_|  |
| | |   ||       ||       |      |   |    |       |
| |_|   ||_     _||  _    | ___  |   |___ |       |
|       |  |   |  | | |   ||   | |       ||   _   |
|______|   |___|  |_|  |__||___| |_______||__| |__|
"
echo "Open the following URL in your browser\033"
echo ""
echo "\033[34m$verification_uri\033[0m"
echo ""
echo "and enter the user code\033"
echo ""
echo "\033[32m$user_code\033[0m"
echo ""
echo "to complete the login."

echo "Waiting for user to complete login..."

while [ -z "$token" ]; do
    sleep $interval
    token_response=$(curl -s -X POST "https://p.ip.vg/?url=https://github.com/login/oauth/access_token" \
    -H "Accept: application/json" \
    -d "client_id=Ov23lixTcMeZpkmqNiWJ" \
    -d "device_code=${device_code}" \
    -d "grant_type=urn:ietf:params:oauth:grant-type:device_code")

    token=$(echo $token_response | grep -o '"access_token":"[^"]*"' | sed -e 's/^"access_token":"//' -e 's/"$//')
    error=$(echo $token_response | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')

    if [ -n "$token" ]; then
        break
    elif [ "$error" != "" ]; then
        if [ "$error" != "authorization_pending" ]; then
            error_description=$(echo $token_response | grep -o '"error_description":"[^"]*"' | sed -e 's/^"error_description":"//' -e 's/"$//')
            echo "Authorization error: $error"
            echo "Error description: $error_description"
            exit 1
        else
            echo "Waiting for authorization... (retry in $interval seconds)"
        fi
    else
        echo "No valid access token obtained, continuing to try..."
    fi
done

echo "Login successful"
echo "========"

while true; do
    echo "\033[36mChoose an option:\033[0m"
    echo "n - /New"
    echo "d - /Delete"
    echo "r - /Reset"
    echo "l - /List"
    echo "e - /Exit"
    echo "h - /Usage"
    read -p "Enter option code: " option

    case $option in
        n)
            read -p "Enter hostname e.g test.dyn.la: " hostname
            if [[ "$hostname" != *".dyn.la" ]]; then
                hostname="${hostname}.dyn.la"
            fi
            response=$(curl -s -X POST "https://beta.dyn.la/new" \
            -H "Authorization: Bearer $token" \
            -d "hostname=$hostname")
            echo "\033[32m$response\033[0m"
            ;;
        d)
            read -p "Enter hostname e.g test.dyn.la: " hostname
            if [[ "$hostname" != *".dyn.la" ]]; then
                hostname="${hostname}.dyn.la"
            fi            
            response=$(curl -s -X POST "https://beta.dyn.la/delete" \
            -H "Authorization: Bearer $token" \
            -d "hostname=$hostname")
            echo "\033[32m$response\033[0m"
            ;;
        r)
            read -p "Enter hostname e.g test.dyn.la: " hostname
            if [[ "$hostname" != *".dyn.la" ]]; then
                hostname="${hostname}.dyn.la"
            fi            
            response=$(curl -s -X POST "https://beta.dyn.la/reset" \
            -H "Authorization: Bearer $token" \
            -d "hostname=$hostname")
            echo "\033[32m$response\033[0m"
            ;;
        l)
            response=$(curl -s -X POST "https://beta.dyn.la/list" \
            -H "Authorization: Bearer $token")
            echo "\033[32m$response\033[0m"
            ;;
        h)
            echo "\033[33mUsage Instructions:\033[0m"
            echo "1. Update hostname without specifying IP address:"
            echo "   \033[32mcurl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la\"\033[0m"
            echo ""
            echo "2. Update hostname with a specified IP address:"
            echo "   \033[32mcurl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la&myip=1.2.3.4\"\033[0m"
            echo ""
            echo "3. Get current IP from 4.ip.plus and update hostname:"
            echo "   \033[32mcurl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la&myip=\$(curl -s 4.ip.plus/myip)\"\033[0m"
            echo ""
            echo "4. Get current IP from 6.ip.plus and update hostname:"
            echo "   \033[32mcurl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la&myip=\$(curl -s 6.ip.plus/myip)\"\033[0m"
            echo ""
            echo "POST Requests:"
            echo "1. Update hostname using POST method:"
            echo "   \033[32mcurl -X POST https://dns.dyn.la/update -d \"password=iz5aqj11p8mual4e\" -d \"hostname=test.dyn.la\"\033[0m"
            echo "   (Default TTL is 1 minute)"
            ;;
        e)
            echo "\033[35mExiting.\033[0m"
            break
            ;;
        *)
            echo "\033[31mUndefined option.\033[0m"
            ;;
    esac
done
