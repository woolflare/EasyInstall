#!/bin/sh

set -u

if [ -t 1 ]
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

login_credential=${DYNLA:-}

if [ -z "$login_credential" ]; then
    if [ -f ".dynla" ]; then
        login_credential=$(cat .dynla)
        echo "Login credential loaded from .dynla file."
    else
        echo "No login credential found. You may need to login."
    fi
fi

token=$login_credential

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
echo "Authorization successful!"
if [ -z "$login_credential" ]; then
    read -p "Do you want to save the login credential to the current directory? (y/n): " save_creds
    if [[ $save_creds == "y" || $save_creds == "Y" ]]; then
        echo $token > .dynla
        echo "Login credential saved to .dynla file."
    else
        echo "You can use export command to set an environment variable for login persistence"
        echo "${tty_blue}export DYNLA=$token${tty_reset}"
    fi
fi

echo "Logging in..." 
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

while true; do
    echo "Choose an option:"
    echo ""
    echo "${tty_green}c${tty_reset} - Create a new DDNS"
    echo "${tty_green}d${tty_reset} - Delete DDNS"
    echo "${tty_green}r${tty_reset} - Reset DDNS password"
    echo "${tty_green}l${tty_reset} - List all DDNS domains"
    echo "${tty_green}s${tty_reset} - Show DDNS IP history"
    echo "${tty_green}q${tty_reset} - Quit"
    echo "${tty_green}h${tty_reset} - Display help"
    echo ""
    read -p "Enter option code: " option
    echo ""

    case "$option" in
        c)
            echo "[Creatie a new DDNS]"
            echo ""
            echo "Enter domain, e.g., test.dyn.la:"
            echo ""
            read -p "${tty_blue}<<${tty_reset} " input
            echo ""
            case "$input" in
                *.dyn.la) ;;
                *) input="${input}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/new" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$input")

            error=$(echo "$response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')
            domain=$(echo "$response" | grep -o '"domain":"[^"]*"' | sed -e 's/^"domain":"//' -e 's/"$//')
            password=$(echo "$response" | grep -o '"password":"[^"]*"' | sed -e 's/^"password":"//' -e 's/"$//')
            if [ "$error" != "" ]; then
                echo "${tty_green}>>${tty_reset} Error: $error"
                echo ""
            else
                echo "${tty_green}>>${tty_reset} Domain: $domain"
                echo "${tty_green}>>${tty_reset} Password: $password"
                echo ""
                echo "Use the following link to update your DDNS:"
                echo ""
                echo "curl \"https://dns.dyn.la/update?password=${password}&domain=${domain}\""
                echo ""
                echo "For more usage, refer to the help with ${tty_green}h${tty_reset}"
                echo ""
            fi
            # read -p "Press enter to continue..."
            ;;
        d)
            echo "${tty_red}[Delete DDNS]${tty_reset}"
            echo ""
            echo "Enter domain to delete, e.g., test.dyn.la:"
            echo ""
            read -p "${tty_red}<<${tty_reset} " input
            echo ""
            case "$input" in
                *.dyn.la) ;;
                *) input="${input}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/delete" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$input")
            error=$(echo "$response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')
            if [ "$error" != "" ]; then
                echo "${tty_green}>>${tty_reset} Error: $error"
                echo ""
            else
                echo "${tty_green}>>${tty_reset} Deleted domain $input"
                echo ""
            fi
            # read -p "Press enter to continue..."
            ;;
        r)
            echo "[Reset DDNS password]"
            echo ""
            echo "Enter domain for password reset, e.g., test.dyn.la:"
            echo ""
            read -p "${tty_blue}<<${tty_reset} " input
            echo ""
            case "$input" in
                *.dyn.la) ;;
                *) input="${input}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/reset" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$input")
            error=$(echo "$response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')
            password=$(echo "$response" | grep -o '"password":"[^"]*"' | sed -e 's/^"password":"//' -e 's/"$//')
            if [ "$error" != "" ]; then
                echo "${tty_green}>>${tty_reset} Error: $error"
                echo ""
            else
                echo "${tty_green}>>${tty_reset} New password: $password"
                echo ""
            fi
            # read -p "Press enter to continue..."
            ;;
        l)
            echo "[List all DDNS]"
            echo ""
            response=$(curl -s -X GET "https://beta.dyn.la/list" \
            -H "Authorization: Bearer $login_token")
            echo "${tty_blue}<<${tty_reset} list"
            echo ""
            error=$(echo "$response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')
            domains=$(echo "$response" | grep -o '"domains":"[^"]*"' | sed -e 's/^"domains":"//' -e 's/"$//')
            if [ "$error" != "" ]; then
                echo "${tty_green}>>${tty_reset} Error: $error"
                echo ""
            else
                echo "${tty_green}>>${tty_reset} Domains list: $domains"
                echo ""
            fi
            # read -p "Press enter to continue..."
            ;;
        s)
            echo "[Show DDNS IP history]"
            echo ""
            echo "Enter domain, e.g., test.dyn.la:"
            echo ""
            read -p "${tty_blue}<<${tty_reset} " input
            echo ""
            case "$input" in
                *.dyn.la) ;;
                *) input="${input}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/log" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$input")

            error=$(echo "$response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')
            logs=$(echo "$response" | grep -o '"logs":"[^"]*"' | sed -e 's/^"logs":"//' -e 's/"$//')
            if [ "$error" != "" ]; then
                echo "${tty_green}>>${tty_reset} Error: $error"
                echo ""
            else
                echo "${tty_green}>>${tty_reset} Logs: $logs"
                echo ""
            fi
            # read -p "Press enter to continue..."
            ;;
        h)
            echo "${tty_blue}<<${tty_reset} help"
            echo ""
            echo "${tty_green}>>${tty_reset}"
            echo "Usage Instructions:"
            echo "-  Update domain without specifying IP address:"
            echo "   curl \"https://dns.dyn.la/update?password=[YOURPASSWORD]&domain=[YOURDOMAIN]\""
            echo ""
            echo "-  Update domain with a specified IP address:"
            echo "   curl \"https://dns.dyn.la/update?password=[YOURPASSWORD]&domain=[YOURDOMAIN]&myip=1.2.3.4\""
            echo ""
            echo "-  Get current IP from 4.ip.plus and update domain:"
            echo "   curl \"https://dns.dyn.la/update?password=[YOURPASSWORD]&domain=[YOURDOMAIN]&myip=\$(curl -s 4.ip.plus/myip)\""
            echo ""
            echo "-  Get current IP from 6.ip.plus and update domain:"
            echo "   curl \"https://dns.dyn.la/update?password=[YOURPASSWORD]&domain=[YOURDOMAIN]&myip=\$(curl -s 6.ip.plus/myip)\""
            echo ""
            echo "POST Requests:"
            echo "-  Update domain using POST method:"
            echo "   curl -X POST https://dns.dyn.la/update -d \"password=[YOURPASSWORD]\" -d \"domain=[YOURDOMAIN]\""
            echo ""
            echo "TXT Record:"
            echo "-  Add a TXT record:"
            echo "   curl \"https://dns.dyn.la/update?password=[YOURPASSWORD]&domain=[YOURDOMAIN]&txt=sometext\""
            echo ""
            echo "-  Delete a TXT record:"
            echo "   curl \"https://dns.dyn.la/update?password=[YOURPASSWORD]&domain=[YOURDOMAIN]&txt=clear\""
            echo ""
            # read -p "Press enter to continue..."
            ;;
        q)
            echo "${tty_blue}<<${tty_reset} quit"
            echo ""
            echo "${tty_green}>>${tty_reset} Quit."
            break
            ;;
        *)
            echo "${tty_green}>>${tty_reset} Undefined option."
            echo ""
            ;;
    esac
done
else
    echo ""
    echo "${tty_red}Error${tty_reset}"
    echo ""
    echo "${tty_green}>>${tty_reset} $login_error"
    echo ""
    echo "This might be caused by invalid or expired login credentials."
    echo "Remove login credentials with 'unset DYNLA' or 'rm ./.dynla' and try again."
fi
