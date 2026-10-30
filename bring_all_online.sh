#!/bin/bash
echo "=== 1. BRINGING DROPBEAR ONLINE (PORT 109) ==="
# Ensure it is installed and configured to port 109
apt-get update >/dev/null 2>&1
apt-get install -y dropbear >/dev/null 2>&1
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=.*/DROPBEAR_PORT=109/g' /etc/default/dropbear
systemctl unmask dropbear
systemctl enable --now dropbear
systemctl restart dropbear

echo "=== 2. BRINGING STUNNEL4 ONLINE (PORT 444) ==="
# Re-enable the Stunnel service we disabled earlier
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl unmask stunnel4
systemctl enable --now stunnel4
systemctl restart stunnel4

echo "=== 3. BRINGING UDP CUSTOM ONLINE (PORT 1-65535, 53, 5300) ==="
# Start standard UDP Custom and fallback UDPeGW services
systemctl unmask udp-custom 2>/dev/null
systemctl enable --now udp-custom 2>/dev/null
systemctl restart udp-custom 2>/dev/null

systemctl unmask badvpn-udpgw 2>/dev/null
systemctl enable --now badvpn-udpgw 2>/dev/null
systemctl restart badvpn-udpgw 2>/dev/null

echo "=== 4. BRINGING WIREGUARD ONLINE (PORT 51820) ==="
# Bring up the default WireGuard interface
systemctl unmask wg-quick@wg0 2>/dev/null
systemctl enable --now wg-quick@wg0 2>/dev/null
systemctl restart wg-quick@wg0 2>/dev/null

echo "=== 5. VERIFYING ALL SERVICES ARE LISTENING ==="
ss -tulpn | grep -E ':109\b|:444\b|:1-65535, 53, 5300\b|:51820\b'
echo "=== DONE! SERVICES ARE ONLINE ==="
