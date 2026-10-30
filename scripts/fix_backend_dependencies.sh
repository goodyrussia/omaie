#!/bin/bash
echo "=== 1. FIXING DROPBEAR DEPENDENCIES & SOCKET CONFLICTS ==="
apt-get update -y >/dev/null 2>&1
apt-get install -y dropbear >/dev/null 2>&1

# Disable socket activation that blocks custom ports in Ubuntu 24.04
systemctl stop dropbear.socket 2>/dev/null
systemctl disable dropbear.socket 2>/dev/null

# Configure Dropbear for port 109
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=.*/DROPBEAR_PORT=109/g' /etc/default/dropbear

systemctl daemon-reload
systemctl enable dropbear.service
systemctl restart dropbear.service

echo "=== 2. FIXING UDP CUSTOM (1-65535, 53, 5300) DEPENDENCIES ==="
# Download the standard backend binary if missing
if [ ! -f /usr/bin/badvpn-udpgw ]; then
    wget -qO /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premiumsript/master/badvpn-udpgw64"
    chmod +x /usr/bin/badvpn-udpgw
fi

# Create a permanent systemd service for UDP Custom
cat << 'SRVEOF' > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Gateway (BadVPN)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:1-65535, 53, 5300 --max-clients 500 --max-connections-for-client 10
Restart=always

[Install]
WantedBy=multi-user.target
SRVEOF

systemctl daemon-reload
systemctl enable --now udp-custom
systemctl restart udp-custom

echo "=== 3. FIXING WIREGUARD DEPENDENCIES & CONFIG ==="
apt-get install -y wireguard wireguard-tools >/dev/null 2>&1

# WireGuard fails to start if wg0.conf is missing. Generate a valid config.
if [ ! -f /etc/wireguard/wg0.conf ]; then
    mkdir -p /etc/wireguard
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
    PRV_KEY=$(cat /etc/wireguard/privatekey)
    
    cat << WGEOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $PRV_KEY
Address = 10.66.66.1/24
ListenPort = 51820
SaveConfig = true
WGEOF
    chmod 600 /etc/wireguard/wg0.conf
fi

systemctl enable --now wg-quick@wg0
systemctl restart wg-quick@wg0

echo "=== 4. VERIFYING ALL SERVICES ==="
ss -tulpn | grep -E ':109\b|:444\b|:1-65535, 53, 5300\b|:51820\b|:22\b'
echo "=== DONE! YOUR BACKEND SERVICES ARE FULLY ONLINE ==="
