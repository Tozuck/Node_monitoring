#!/bin/bash

# Set Node Exporter version
NODE_EXPORTER_VERSION="1.9.0"

# Download and extract Node Exporter
cd /tmp
echo "Downloading Node Exporter v$NODE_EXPORTER_VERSION..."
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

if [ ! -f "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" ]; then
    echo "Download failed! Exiting..."
    exit 1
fi

echo "Extracting Node Exporter..."
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# Move binary to /usr/local/bin
echo "Moving Node Exporter binary to /usr/local/bin..."
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter
sudo chown root:root /usr/local/bin/node_exporter

# Create systemd service file
echo "Creating systemd service..."
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Node Exporter
echo "Enabling and starting Node Exporter..."
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# Verify service status
echo "Checking Node Exporter status..."
sudo systemctl status node_exporter --no-pager

# Print success message
echo "Node Exporter v$NODE_EXPORTER_VERSION installed successfully!"
echo "Check metrics at: http://$(hostname -I | awk '{print $1}'):9100/metrics"
