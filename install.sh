#!/bin/bash

echo "Installing dependencies..."

# Update and install dependencies
apt-get update && apt-get install -y net-tools nginx docker.io

# Create log file and set permissions
touch /var/log/devopsfetch.log
chmod 644 /var/log/devopsfetch.log

# Copy the service file
cp devopsfetch.service /etc/systemd/system/

# Enable and start the service
systemctl daemon-reload
systemctl enable devopsfetch
systemctl start devopsfetch

echo "Installation completed. devopsfetch is now running."
