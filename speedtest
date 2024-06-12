#!/usr/bin/env sh

set -e

INFO="[INFO]"
ERROR="[ERROR]"

PROJECT_NAME='Ookla Speedtest CLI'
BIN_DIR='/usr/local/bin'
BIN_NAME='speedtest'
BIN_FILE="${BIN_DIR}/${BIN_NAME}"

if [ "$(uname -s)" != "Linux" ]; then
    echo "${ERROR} This operating system is not supported."
    exit 1
fi

if [ "$(id -u)" != 0 ]; then
    echo "${ERROR} This script must be run as root."
    exit 1
fi

echo "${INFO} Get CPU architecture ..."
if command -v apk > /dev/null 2>&1; then
    PKGT='(apk)'
    OS_ARCH=$(apk --print-arch)
elif command -v dpkg > /dev/null 2>&1; then
    PKGT='(dpkg)'
    OS_ARCH=$(dpkg --print-architecture | awk -F- '{ print $NF }')
else
    OS_ARCH=$(uname -m)
fi
case ${OS_ARCH} in
*86)
    FILE_KEYWORD='i386'
    ;;
x86_64 | amd64)
    FILE_KEYWORD='x86_64'
    ;;
aarch64 | arm64)
    FILE_KEYWORD='aarch64'
    ;;
arm*)
    FILE_KEYWORD='arm'
    ;;
*)
    echo "${ERROR} Unsupported architecture: ${OS_ARCH} ${PKGT}"
    exit 1
    ;;
esac
echo "${INFO} Architecture: ${OS_ARCH} ${PKGT}"

echo "${INFO} Get ${PROJECT_NAME} download URL ..."
DOWNLOAD_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-${FILE_KEYWORD}-linux.tgz"
echo "${INFO} Download URL: ${DOWNLOAD_URL}"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf ${TEMP_DIR}' EXIT

echo "${INFO} Downloading ${PROJECT_NAME} ..."
curl -LS "${DOWNLOAD_URL}" -o "${TEMP_DIR}/speedtest.tgz"

echo "${INFO} Installing ${PROJECT_NAME} ..."
tar -xzC ${BIN_DIR} -f "${TEMP_DIR}/speedtest.tgz" ${BIN_NAME}
chmod +x ${BIN_FILE}
if ! echo "${PATH}" | grep -q "${BIN_DIR}"; then
    ln -sf ${BIN_FILE} /usr/bin/${BIN_NAME}
fi

if [ -s ${BIN_FILE} ] && ${BIN_NAME} --version > /dev/null 2>&1; then
    echo "${INFO} Done."
else
    echo "${ERROR} ${PROJECT_NAME} installation failed !"
    exit 1
fi
