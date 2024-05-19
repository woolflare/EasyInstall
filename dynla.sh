#!/bin/sh

if [ -t 0 ]; then
    echo "Running in interactive mode."
else
    echo ""
    echo "This script is not running in an interactive mode."
    echo ""
    echo "Please download the script and run it locally for interactive features."
    echo "Use the following commands to download and run the script:"
    echo ""
    echo "  curl -O https://install.is/dynla.sh"
    echo "  chmod +x dynla.sh"
    echo "  ./dynla.sh"
    echo ""
    echo "Or run it directly in an interactive shell:"
    echo ""
    echo "  sh -c \"\$(curl -fsSL https://install.is/dynla.sh)\""
    echo ""
    exit 1 
fi

token=${DYNLA:-}

if [ -z "$token" ]; then
    response=$(curl -s -X POST "https://p.ip.vg/?url=https://github.com/login/device/code" \
    -H "Accept: application/json" \
    -d "client_id=Ov23lixTcMeZpkmqNiWJ")

    device_code=$(echo "$response" | grep -o '"device_code":"[^"]*"' | sed -e 's/^"device_code":"//' -e 's/"$//')
    user_code=$(echo "$response" | grep -o '"user_code":"[^"]*"' | sed -e 's/^"user_code":"//' -e 's/"$//')
    verification_uri=$(echo "$response" | grep -o '"verification_uri":"[^"]*"' | sed -e 's/^"verification_uri":"//' -e 's/"$//')
    expires_in=$(echo "$response" | grep -o '"expires_in":[0-9]*' | sed -e 's/^"expires_in"://')
    interval=$(echo "$response" | grep -o '"interval":[0-9]*' | sed -e 's/^"interval"://')

    echo "Open the following URL in your browser"
    echo ""
    echo "$verification_uri"
    echo ""
    echo "and enter the user code"
    echo ""
    echo "$user_code"
    echo ""
    echo "to complete the login."

    echo "Waiting for user to complete login..."
fi
while [ -z "$token" ]; do
    sleep "$interval"
    token_response=$(curl -s -X POST "https://p.ip.vg/?url=https://github.com/login/oauth/access_token" \
    -H "Accept: application/json" \
    -d "client_id=Ov23lixTcMeZpkmqNiWJ" \
    -d "device_code=$device_code" \
    -d "grant_type=urn:ietf:params:oauth:grant-type:device_code")

    token=$(echo "$token_response" | grep -o '"access_token":"[^"]*"' | sed -e 's/^"access_token":"//' -e 's/"$//')
    error=$(echo "$token_response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')

    if [ -n "$token" ]; then
        break
    elif [ "$error" != "" ]; then
        if [ "$error" != "authorization_pending" ]; then
            error_description=$(echo "$token_response" | grep -o '"error_description":"[^"]*"' | sed -e 's/^"error_description":"//' -e 's/"$//')
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

HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "https://beta.dyn.la/oauth/callback?provider=github" -H "Authorization: Bearer $token")

if [ "$HTTP_STATUS" -eq 200 ]; then
    login_token=$(curl -fsSL "https://beta.dyn.la/oauth/callback?provider=github" -H "Authorization: Bearer $token")
echo "
______   __   __  __    _        ___      _______ 
|      | |  | |  ||  |  | |      |   |    |   _   |
|  _    ||  |_|  ||   |_| |      |   |    |  |_|  |
| | |   ||       ||       |      |   |    |       |
| |_|   ||_     _||  _    | ___  |   |___ |       |
|       |  |   |  | | |   ||   | |       ||   _   |
|______|   |___|  |_|  |__||___| |_______||__| |__|
"
echo "Login successful!"

if [ -z "$DYNLA" ]; then
    echo ""
    echo "Use this command to set an environment variable for login persistence"
    echo "export DYNLA=$token"
    echo ""
fi

while true; do
    echo "Choose an option:"
    echo "n - Create new dynamic DNS"
    echo "d - Delete dynamic DNS"
    echo "r - Reset dynamic DNS"
    echo "l - List all dynamic DNS"
    echo "e - Exit"
    echo "h - Display help"
    read -p "Enter option code: " option

    case "$option" in
        n)
            read -p "Enter hostname e.g test.dyn.la: " hostname
            case "$hostname" in
                *.dyn.la) ;;
                *) hostname="${hostname}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/new" \
            -H "Authorization: Bearer $login_token" \
            -d "hostname=$hostname")
            echo "$response"
            ;;
        d)
            read -p "Enter hostname e.g test.dyn.la: " hostname
            case "$hostname" in
                *.dyn.la) ;;
                *) hostname="${hostname}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/delete" \
            -H "Authorization: Bearer $login_token" \
            -d "hostname=$hostname")
            echo "$response"
            ;;
        r)
            read -p "Enter hostname e.g test.dyn.la: " hostname
            case "$hostname" in
                *.dyn.la) ;;
                *) hostname="${hostname}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/reset" \
            -H "Authorization: Bearer $login_token" \
            -d "hostname=$hostname")
            echo "$response"
            ;;
        l)
            response=$(curl -s -X POST "https://beta.dyn.la/list" \
            -H "Authorization: Bearer $login_token")
            echo "$response"
            ;;
        h)
            echo "Usage Instructions:"
            echo "1. Update hostname without specifying IP address:"
            echo "   curl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la\""
            echo ""
            echo "2. Update hostname with a specified IP address:"
            echo "   curl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la&myip=1.2.3.4\""
            echo ""
            echo "3. Get current IP from 4.ip.plus and update hostname:"
            echo "   curl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la&myip=\$(curl -s 4.ip.plus/myip)\""
            echo ""
            echo "4. Get current IP from 6.ip.plus and update hostname:"
            echo "   curl \"https://dns.dyn.la/update?password=iz5aqj11p8mual4e&hostname=test.dyn.la&myip=\$(curl -s 6.ip.plus/myip)\""
            echo ""
            echo "POST Requests:"
            echo "1. Update hostname using POST method:"
            echo "   curl -X POST https://dns.dyn.la/update -d \"password=iz5aqj11p8mual4e\" -d \"hostname=test.dyn.la\""
            echo "   (Default TTL is 1 minute)"
            ;;
        e)
            echo "Exiting."
            break
            ;;
        *)
            echo "Undefined option."
            ;;
    esac
done
else
    echo "Invalid or expired login credentials."
    echo  "Unset login credentials with 'unset DYNLA' and try again."
fi
