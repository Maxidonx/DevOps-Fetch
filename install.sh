#!/bin/bash

echo "Installing dependencies..."

# Update and install dependencies
apt-get update && apt-get install -y net-tools nginx docker.io

# Install Docker Compose
echo "Installing Docker Compose..."
sudo apt-get install -y docker-compose


# Create log file and set permissions
echo "Setting up log file..."
touch /var/log/devopsfetch.log
chmod 644 /var/log/devopsfetch.log

# Copy the service file
echo "Copying the systemd service file..."
cp devopsfetch.service /etc/systemd/system/

# Enable and start the service
echo "Enabling and starting the devopsfetch service..."
systemctl daemon-reload
systemctl enable devopsfetch
systemctl start devopsfetch

echo "Installation completed. devopsfetch is now running."
