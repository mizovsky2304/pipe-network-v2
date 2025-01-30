#!/bin/bash

# Logo installation script

sudo ufw allow 8002/tcp
sudo ufw allow 8003/tcp


echo "==============================================="
echo "        🔹 Stopping DCDND Service 🔹       "
echo "==============================================="
systemctl stop dcdnd && systemctl disable dcdnd
echo "✅ DCDND service successfully stopped."
echo



echo "==============================================="
echo "        🔹 Killing Process on port 8003 🔹       "
echo "==============================================="
echo "Stopping any process using port 8003..."
PID=$(lsof -ti :8003)
if [ -n "$PID" ]; then
  echo "✅ Killing process with PID: $PID"
  kill -9 $PID
else
  echo "❌ No process found using port 8003."
fi




echo "==============================================="
echo "     📁 Creating Node Configuration Folder 📁     "
echo "==============================================="
mkdir -p $HOME/pipenetwork-v2
echo "✅ Folder '$HOME/pipenetwork-v2' has been created."
echo

echo "==============================================="
echo "  🔗 Enter the Binary v2 Download Link (HTTPS)  "
echo "==============================================="
read -r binary_url

if [[ $binary_url == https* ]]; then
    echo
    echo "📥 Downloading binary file..."
    wget -O $HOME/pipenetwork-v2/pop "$binary_url"
    chmod +x $HOME/pipenetwork-v2/pop
    echo "✅ Binary successfully downloaded and execution permission granted."
else
    echo "❌ Invalid URL. Make sure the link starts with 'https'."
    exit 1
fi
echo

echo "==============================================="
echo "       💾 Configuring Node Resources        "
echo "==============================================="
read -p "🔹 Enter the amount of RAM to allocate (Minimum 4GB): " RAM
if [ "$RAM" -lt 4 ]; then
  echo "❌ RAM must be at least 4GB. Exiting..."
  exit 1
fi

read -p "🔹 Enter the maximum storage capacity (Minimum 100GB): " DISK
if [ "$DISK" -lt 100 ]; then
  echo "❌ Storage must be at least 100GB. Exiting..."
  exit 1
fi

read -p "🔹 Enter Your Public Key: " PUBKEY
echo

echo "==============================================="
echo "      ⚙️  Creating Node Systemd Service       "
echo "==============================================="
SERVICE_FILE="/etc/systemd/system/pipe.service"

cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=$HOME/pipenetwork-v2/pop \
    --ram=$RAM \
    --pubKey $PUBKEY \
    --max-disk $DISK \
    --cache-dir $HOME/pipenetwork-v2/download_cache \
    --signup-by-referral-route 752c3f7d064fd114
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=$HOME/pipenetwork-v2

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Systemd service successfully created: $SERVICE_FILE"
echo

echo "==============================================="
echo "  🔄 Starting and Enabling Node Service    "
echo "==============================================="
sudo systemctl daemon-reload
sudo systemctl enable pipe
sudo systemctl restart pipe
echo "✅ Pipe service has been started."
echo

echo "==============================================="
echo "     📜 Displaying Live Service Logs   "
echo "==============================================="
journalctl -u pipe -fo cat
