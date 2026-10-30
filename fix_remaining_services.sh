#!/bin/bash
echo "=== 1. FIXING DROPBEAR (PORT 109) ==="
# Install dropbear if it is completely missing
DEBIAN_FRONTEND=noninteractive apt-get install -y dropbear >/dev/null 2>&1

# Disable systemd socket activation that blocks the service
systemctl stop dropbear.socket 2>/dev/null
systemctl disable dropbear.socket 2>/dev/null
systemctl unmask dropbear.service 2>/dev/null

# Force the correct configuration
cat << DBEOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 109"
DROPBEAR_BANNER=""
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF

systemctl daemon-reload
systemctl enable dropbear.service
systemctl restart dropbear.service

echo "=== 2. COMPILING & FIXING UDP CUSTOM (PORT 1-65535, 53, 5300) ==="
# Install build dependencies
DEBIAN_FRONTEND=noninteractive apt-get install -y cmake make gcc g++ git >/dev/null 2>&1

# Build BadVPN UDPGW from source to guarantee Ubuntu 24.04 compatibility
if [ ! -f /usr/bin/badvpn-udpgw ]; then
    echo "  [INFO] Building UDP Custom from source..."
    rm -rf /root/badvpn
    git clone https://github.com/ambrop72/badvpn.git /root/badvpn >/dev/null 2>&1
    cd /root/badvpn
    mkdir build && cd build
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
    make >/dev/null 2>&1
    cp badvpn-udpgw /usr/bin/badvpn-udpgw
    chmod +x /usr/bin/badvpn-udpgw
    cd /root
    rm -rf /root/badvpn
fi

# Create a robust systemd service
cat << 'UDPEOF' > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Gateway (BadVPN)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:1-65535, 53, 5300 --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UDPEOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

echo "=== 3. VERIFYING LISTENERS ==="
ss -tulpn | grep -E ':109\b|:1-65535, 53, 5300\b'
echo "=== DONE! REFRESH YOUR DASHBOARD ==="
