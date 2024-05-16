#!/bin/bash

# Define the version number
VERSION="v4.0.1"

# Determine the system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    i386) ARCH="i386" ;;
    aarch64) ARCH="aarch64" ;;
    armv7l) ARCH="armv7l" ;;
    *) echo "Architecture $ARCH is not supported by this script."; exit 1 ;;
esac

# Define the download URL and filename based on the architecture
URL="https://dl.nssurge.com/snell/snell-server-${VERSION}-linux-${ARCH}.zip"
FILENAME="snell-server-${VERSION}-linux-${ARCH}.zip"
EXTRACTED="snell-server"

# Check and install unzip if not present
if ! command -v unzip &> /dev/null
then
    echo "unzip could not be found, now installing unzip..."
    sudo apt-get update && sudo apt-get install -y unzip
fi

# Download snell-server
echo "Downloading Snell Server from $URL..."
wget $URL

# Extract files
echo "Extracting files..."
unzip $FILENAME

# Move snell-server to /usr/local/bin
echo "Installing Snell Server..."
sudo mv $EXTRACTED /usr/local/bin/snell-server
sudo chmod +x /usr/local/bin/snell-server

# Create systemd service file
echo "Setting up systemd service..."
cat <<EOT | sudo tee /etc/systemd/system/snell.service
[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/snell-server -c /etc/snell/snell-server.conf
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=snell-server

[Install]
WantedBy=multi-user.target
EOT

# Create snell configuration file in the current directory
yes | /usr/local/bin/snell-server

# Create configuration directory and move the configuration file
mkdir -p /etc/snell
mv snell-server.conf /etc/snell/snell-server.conf

# Enable and start the service
echo "Enabling and starting Snell service..."
sudo systemctl enable snell.service
sudo systemctl start snell.service

echo "Snell Server installation and setup completed!"

# Display the configuration file content
cat /etc/snell/snell-server.conf
