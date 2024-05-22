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
    echo "正在以交互模式运行。"
else
    echo "==================================================="
    echo ""
    echo "此脚本未在交互模式下运行。"
    echo ""
    echo "==================================================="
    echo ""
    echo "请下载脚本并在本地运行以使用交互功能。"
    echo "使用以下命令下载并运行脚本："
    echo ""
    echo "  curl -O https://install.is/dynla.sh"
    echo "  chmod +x dynla.sh"
    echo "  ./dynla.sh"
    echo ""
    echo "或直接在交互式shell中运行："
    echo ""
    echo "  sh -c \"\$(curl -fsSL https://install.is/dynla.sh)\""
    echo ""
    exit 1 
fi

login_credential=${DYNLA:-}

if [ -z "$login_credential" ]; then
    if [ -f ".dynla" ]; then
        login_credential=$(cat .dynla)
        echo "从.dynla文件中加载登录凭证。"
    else
        echo "未找到登录凭证。您可能需要登录。"
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

    echo "在浏览器中打开以下URL"
    echo ""
    echo "${tty_underline}$verification_uri${tty_reset}"
    echo ""
    echo "并输入用户码"
    echo ""
    echo "${tty_green}$user_code${tty_reset}"
    echo ""
    echo "以完成登录。"
    echo "等待用户完成登录..."

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
            echo "授权错误：$error"
            echo "错误描述：$error_description"
            exit 1
        else
            echo "等待授权中...（${interval}秒后重试）"
        fi
    else
        echo "未获得有效的访问令牌，继续尝试..."
    fi
done
echo "授权成功！"
if [ -z "$login_credential" ]; then
    read -p "您是否希望将登录凭证保存到当前目录？（y/n）: " save_creds
    if [[ $save_creds == "y" || $save_creds == "Y" ]]; then
        echo $token > .dynla
        echo "登录凭证已保存到.dynla文件。"
    else
        echo "您可以使用export命令设置环境变量以持久化登录"
        echo "${tty_blue}export DYNLA=$token${tty_reset}"
    fi
fi

echo "登录中..." 
login_response=$(curl -s "https://beta.dyn.la/oauth/callback?provider=github" \
-H "Authorization: Bearer $token")
login_token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | sed -e 's/^"token":"//' -e 's/"$//')
username=$(echo "$login_response" | grep -o '"username":"[^"]*"' | sed -e 's/^"username":"//' -e 's/"$//')
login_error=$(echo "$login_response" | grep -o '"error":"[^"]*"' | sed -e 's/^"error":"//' -e 's/"$//')

if [ "$login_token" ]; then
echo "登录成功！"
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
echo "欢迎，$username"
echo "-----------------"
echo ""

while true; do
    echo "选择一个选项："
    echo ""
    echo "${tty_green}c${tty_reset} - 创建新的DDNS"
    echo "${tty_green}d${tty_reset} - 删除DDNS"
    echo "${tty_green}r${tty_reset} - 重置DDNS密码"
    echo "${tty_green}l${tty_reset} - 列出所有DDNS域"
    echo "${tty_green}s${tty_reset} - 显示DDNS IP历史"
    echo "${tty_green}q${tty_reset} - 退出"
    echo "${tty_green}h${tty_reset} - 显示帮助"
    echo ""
    read -p "输入选项代码： " option
    echo ""

    case "$option" in
        c)
            echo "[创建新的DDNS]"
            echo ""
            echo "输入域名，例如，test.dyn.la:"
            echo ""
            read -p "${tty_blue}<<${tty_reset} " domain
            echo ""
            case "$domain" in
                *.dyn.la) ;;
                *) domain="${domain}.dyn.la"
            esac
            response=$(curl -s -X POST "https://beta.dyn.la/new" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$domain")
            echo "${tty_green}>>${tty_reset} $response"
            echo ""

            re_status=$(echo "$response" | cut -d ' ' -f1)
            re_domain=$(echo "$response" | cut -d ' ' -f2)
            re_password=$(echo "$response" | cut -d ' ' -f3)

            if [ "$re_status" = "ok" ]; then
                echo "使用以下链接更新您的DDNS："
                echo ""
                echo "curl \"https://dns.dyn.la/update?password=${re_password}&domain=${re_domain}\""
                echo ""
                echo "有关更多用法，请参考帮助${tty_green}h${tty_reset}"
                echo ""
            fi
            # read -p "按Enter继续..."
            ;;
        d)
            echo "${tty_red}[删除DDNS]${tty_reset}"
            echo ""
            echo "输入要删除的域名，例如，test.dyn.la:"
            echo ""
            read -p "${tty_red}<<${tty_reset} " domain
            echo ""
            case "$domain" in
                *.dyn.la) ;;
                *) domain="${domain}.dyn.la"
            esac
            response=$(curl -s -X GET "https://beta.dyn.la/delete" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$domain")
            echo "${tty_green}>>${tty_reset} $response"
            echo ""
            # read -p "按Enter继续..."
            ;;
        r)
            echo "[重置DDNS密码]"
            echo ""
            echo "输入需要重置密码的域名，例如，test.dyn.la:"
            echo ""
            read -p "${tty_blue}<<${tty_reset} " domain
            echo ""
            case "$domain" in
                *.dyn.la) ;;
                *) domain="${domain}.dyn.la"
            esac
            response=$(curl -s -X GET "https://beta.dyn.la/reset" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$domain")
            echo "${tty_green}>>${tty_reset} $response"
            echo ""
            # read -p "按Enter继续..."
            ;;
        l)
            echo "[列出所有DDNS]"
            echo ""
            response=$(curl -s -X GET "https://beta.dyn.la/list" \
            -H "Authorization: Bearer $login_token")
            echo "${tty_blue}<<${tty_reset} list"
            echo ""
            echo "${tty_green}>>${tty_reset} $response"
            echo ""
            # read -p "按Enter继续..."
            ;;
        s)
            echo "[显示DDNS IP历史]"
            echo ""
            echo "输入域名，例如，test.dyn.la:"
            echo ""
            read -p "${tty_blue}<<${tty_reset} " domain
            echo ""
            case "$domain" in
                *.dyn.la) ;;
                *) domain="${domain}.dyn.la"
            esac
            response=$(curl -s -X GET "https://beta.dyn.la/log" \
            -H "Authorization: Bearer $login_token" \
            -d "domain=$domain")
            echo "${tty_green}>>${tty_reset} $response"
            echo ""
            # read -p "按Enter继续..."
            ;;
        h)
            echo "${tty_blue}<<${tty_reset} 帮助"
            echo ""
            echo "${tty_green}>>${tty_reset}"
            echo "使用说明："
            echo "-  更新域名不指定IP地址："
            echo "   curl \"https://dns.dyn.la/update?password=[您的密码]&domain=[您的域名]\""
            echo ""
            echo "-  更新域名并指定IP地址："
            echo "   curl \"https://dns.dyn.la/update?password=[您的密码]&domain=[您的域名]&myip=1.2.3.4\""
            echo ""
            echo "-  从4.ip.plus获取当前IP并更新域名："
            echo "   curl \"https://dns.dyn.la/update?password=[您的密码]&domain=[您的域名]&myip=\$(curl -s 4.ip.plus/myip)\""
            echo ""
            echo "-  从6.ip.plus获取当前IP并更新域名："
            echo "   curl \"https://dns.dyn.la/update?password=[您的密码]&domain=[您的域名]&myip=\$(curl -s 6.ip.plus/myip)\""
            echo ""
            echo "POST请求："
            echo "-  使用POST方法更新域名："
            echo "   curl -X POST https://dns.dyn.la/update -d \"password=[您的密码]\" -d \"domain=[您的域名]\""
            echo ""
            echo "TXT记录："
            echo "-  添加TXT记录："
            echo "   curl \"https://dns.dyn.la/update?password=[您的密码]&domain=[您的域名]&txt=一些文字\""
            echo ""
            echo "-  删除TXT记录："
            echo "   curl \"https://dns.dyn.la/update?password=[您的密码]&domain=[您的域名]&txt=clear\""
            echo ""
            # read -p "按Enter继续..."
            ;;
        q)
            echo "${tty_blue}<<${tty_reset} 退出"
            echo ""
            echo "${tty_green}>>${tty_reset} 退出。"
            break
            ;;
        *)
            echo "${tty_green}>>${tty_reset} 未定义的选项。"
            echo ""
            ;;
    esac
done
else
    echo ""
    echo "${tty_red}错误${tty_reset}"
    echo ""
    echo "${tty_green}>>${tty_reset} $login_error"
    echo ""
    echo "这可能是由于无效或过期的登录凭证造成的。"
    echo "使用 'unset DYNLA' 或 'rm ./.dynla' 删除登录凭证后再试。"
fi
