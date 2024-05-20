#!/bin/sh

if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_green="$(tty_mkbold 32)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

if [ -t 0 ]; then
    echo "Running in interactive mode."
else
    echo "==================================================="
    echo ""
    echo "This script is not running in an interactive mode."
    echo ""
    echo "==================================================="
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
    echo "${tty_underline}$verification_uri${tty_reset}"
    echo ""
    echo "and enter the user code"
    echo ""
    echo "${tty_green}$user_code${tty_reset}"
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


login_response=$(curl -s "https://beta.dyn.la/oauth/callback?provider=github" \
-H "Authorization: Bearer $token")
login_token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | sed -e 's/^"token":"//' -e 's/"$//')
username=$(echo "$login_response" | grep -o '"username":"[^"]*"' | sed -e 's/^"username":"//' -e 's/"$//')
login_error=$(echo "$login_response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')

if [ "$login_token" ]; then
echo "Login successful!"
echo "
______   __   __  __    _        ___      _______ 
|      | |  | |  ||  |  | |      |   |    |   _   |
|  _    ||  |_|  ||   |_| |      |   |    |  |_|  |
| | |   ||       ||       |      |   |    |       |
| |_|   ||_     _||  _    | ___  |   |___ |       |
|       |  |   |  | | |   ||   | |       ||   _   |
|______|   |___|  |_|  |__||___| |_______||__| |__|
"
echo ""
echo "Welcome $username"
echo "-----------------"
echo ""

if [ -z "$DYNLA" ]; then
    echo "Use this command to set an environment variable for login persistence"
    echo "${tty_blue}export DYNLA=$token${tty_reset}"
    echo ""
fi

while true; do
    echo "Choose an option:"
    echo ""
    echo "${tty_green}n${tty_reset} - Create new dynamic DNS"
    echo "${tty_green}d${tty_reset} - Delete dynamic DNS"
    echo "${tty_green}r${tty_reset} - Reset dynamic DNS password"
    echo "${tty_green}l${tty_reset} - List all dynamic DNS"
    echo "${tty_green}e${tty_reset} - Exit"
    echo "${tty_green}h${tty_reset} - Display help"
    echo ""
    read -p "Enter option code: " option
    echo ""

    case "$option" in
        n)
            echo "[Creatie new dynamic DNS]"
            echo ""
            read -p "Enter hostname e.g test.dyn.la: " hostname
            echo ""
            case "$hostname" in
                *.dyn.la) ;;
                *) hostname="${hostname}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/new" \
            -H "Authorization: Bearer $login_token" \
            -d "hostname=$hostname")
            echo "${tty_blue}->${tty_reset} $response"
            echo ""
            # read -p "Press enter to continue..."
            ;;
        d)
            echo "${tty_red}[Delete dynamic DNS]${tty_reset}"
            echo ""
            read -p "Enter hostname e.g test.dyn.la: " hostname
            echo ""
            case "$hostname" in
                *.dyn.la) ;;
                *) hostname="${hostname}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/delete" \
            -H "Authorization: Bearer $login_token" \
            -d "hostname=$hostname")
            echo "${tty_blue}->${tty_reset} $response"
            echo ""
            # read -p "Press enter to continue..."
            ;;
        r)
            echo "[Reset dynamic DNS password]"
            echo ""
            read -p "Enter hostname e.g test.dyn.la: " hostname
            echo ""
            case "$hostname" in
                *.dyn.la) ;;
                *) hostname="${hostname}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/reset" \
            -H "Authorization: Bearer $login_token" \
            -d "hostname=$hostname")
            echo "${tty_blue}->${tty_reset} $response"
            echo ""
            # read -p "Press enter to continue..."
            ;;
        l)
            echo "[List all dynamic DNS]"
            echo ""
            response=$(curl -s -X POST "https://beta.dyn.la/list" \
            -H "Authorization: Bearer $login_token")
            echo "${tty_blue}->${tty_reset} $response"
            echo ""
            # read -p "Press enter to continue..."
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
            echo ""
            # read -p "Press enter to continue..."
            ;;
        e)
            echo "${tty_blue}->${tty_reset} Exiting."
            break
            ;;
        *)
            echo "${tty_blue}->${tty_reset} Undefined option."
            ;;
    esac
done
else
    echo ""
    echo "${tty_red}Error${tty_reset}"
    echo ""
    echo "${tty_blue}->${tty_reset} $login_error"
    echo ""
    echo "This might be caused by invalid or expired login credentials."
    echo "If environment variables are set, unset login credentials with 'unset DYNLA' and try again."
fi
