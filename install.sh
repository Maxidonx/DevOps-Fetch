#!/bin/bash

set -e

# Uninstall any conflicting packages
sudo apt-get remove containerd -y
sudo apt-get purge containerd -y

# Install dependencies
sudo apt-get update
sudo apt-get install -y nginx curl

# Set up Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Copy devopsfetch script to /usr/local/bin
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch

# Set up systemd service
cat << EOF | sudo tee /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOpsFetch Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch -t "1 hour ago"
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

echo "DevOpsFetch has been installed and the monitoring service has been started."
