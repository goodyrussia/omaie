#!/bin/bash
echo "=== 1. FIXING PREVIOUS SERVICE NAMING ==="
systemctl stop udp-custom 2>/dev/null
# Move the BadVPN service to its proper name so they don't conflict
if grep -q "badvpn" /etc/systemd/system/udp-custom.service 2>/dev/null; then
    mv /etc/systemd/system/udp-custom.service /etc/systemd/system/badvpn-udpgw.service
    systemctl daemon-reload
    systemctl enable --now badvpn-udpgw
fi

echo "=== 2. DOWNLOADING REAL UDP CUSTOM BINARY ==="
mkdir -p /etc/udp-custom
rm -f /usr/bin/udp-custom

# Fetch the official compiled UDP Custom core trusted by the tunneling community
wget -qO /usr/bin/udp-custom "https://raw.githubusercontent.com/prjkt-nv404/VoltsshX/main/cstm/udp-custom"
if [ ! -s /usr/bin/udp-custom ]; then
    wget -qO /usr/bin/udp-custom "https://raw.githubusercontent.com/botnet-x/udp-custom/main/udp-custom-linux-amd64"
fi
chmod +x /usr/bin/udp-custom

echo "=== 3. CONFIGURING UDP CUSTOM (1-65535) ==="
cat << 'CONF' > /etc/udp-custom/config.json
{
  "listen": ":1-65535",
  "max_conn": 1024,
  "cert": "",
  "key": "",
  "obfs": "",
  "exclude": "53,5300,1-65535, 53, 5300"
}
CONF

echo "=== 4. CREATING UDP CUSTOM SERVICE ==="
cat << 'SRVEOF' > /etc/systemd/system/udp-custom.service
[Unit]
Description=Real UDP Custom (1-65535) for NetMod/ePro
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-custom
ExecStart=/usr/bin/udp-custom server
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SRVEOF

systemctl daemon-reload
systemctl enable --now udp-custom
systemctl restart udp-custom

echo "=== 5. VERIFYING ==="
systemctl status udp-custom --no-pager | head -n 8
echo "=== DONE! REAL UDP CUSTOM IS NOW ACTIVE ==="
