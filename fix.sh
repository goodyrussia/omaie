#!/bin/bash
cd /root/smartking4luv-v2

# 1. FIX DASHBOARD UI (Universal Mobile-Safe ASCII)
cat << 'EOF' > menu/dashboard.sh
#!/bin/bash
get_status() { systemctl is-active --quiet $1 && echo -e "\033[0;32m[ON]\033[0m" || echo -e "\033[0;31m[OFF]\033[0m"; }

show_dashboard() {
    clear
    UPTIME=$(uptime -p | cut -d " " -f 2-)
    RAM=$(free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100) }')
    DOMAIN=$(cat /etc/smartking4luv/domain 2>/dev/null || echo "Not Set")
    IP=$(curl -sS ipv4.icanhazip.com 2>/dev/null)

    echo -e "\033[0;36m==============================================================\033[0m"
    echo -e "\033[1;37m                 SMARTKING4LUV v2 PREMIUM UI                  \033[0m"
    echo -e "\033[0;36m==============================================================\033[0m"
    echo -e " \033[1;33mOS:\033[0m $HOSTNAME"
    echo -e " \033[1;33mIP:\033[0m $IP"
    echo -e " \033[1;33mDomain:\033[0m $DOMAIN"
    echo -e " \033[1;33mRAM:\033[0m $RAM         \033[1;33mUptime:\033[0m $UPTIME"
    echo -e "\033[0;36m--------------------------------------------------------------\033[0m"
    echo -e "\033[1;37m                       SERVICE STATUS                         \033[0m"
    echo -e "\033[0;36m--------------------------------------------------------------\033[0m"
    echo -e " SSH-WS: $(get_status stunnel4)     XRAY: $(get_status xray)        WG: $(get_status wg-quick@wg0)"
    echo -e " OVPN: $(get_status openvpn)       HAPROXY: $(get_status haproxy)     SQUID: $(get_status squid)"
    echo -e "\033[0;36m==============================================================\033[0m"
    echo -e "\033[1;32m [1]\033[0m 🔐 SSH/OVPN/DNSTT Manager    \033[1;32m[4]\033[0m 🌐 Domain & SSL Manager"
    echo -e "\033[1;32m [2]\033[0m 🚀 Xray (Vless/SS) Manager   \033[1;32m[5]\033[0m 🔌 Port Manager"
    echo -e "\033[1;32m [3]\033[0m 🛡 WireGuard Manager          \033[1;32m[6]\033[0m 📊 System Monitor"
    echo -e "\033[1;32m [7]\033[0m 🗑️ Uninstall System"
    echo -e "\033[0;36m--------------------------------------------------------------\033[0m"
    echo -e "\033[1;31m [0]\033[0m ❌ Exit Dashboard"
    echo -e "\033[0;36m==============================================================\033[0m"
}
EOF

# 2. FIX STUNNEL CRASH
echo "[*] Fixing Stunnel Certificates..."
mkdir -p /etc/ssl
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/CN=localhost" -keyout /etc/ssl/smartking.key -out /etc/ssl/smartking.pem 2>/dev/null
cat /etc/ssl/smartking.key >> /etc/ssl/smartking.pem
cat << 'STUN' > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel.pid
cert = /etc/ssl/smartking.pem
[dropbear]
accept = 444
connect = 127.0.0.1:109
STUN
systemctl restart stunnel4

# 3. FIX WIREGUARD MISSING UNIT
echo "[*] Fixing WireGuard Interface..."
apt-get install -y wireguard-tools
mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
cat << WG > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = 10.66.66.1/24
ListenPort = 51820
WG
systemctl enable --now wg-quick@wg0

# 4. PUSH TO GITHUB
git add menu/dashboard.sh
git commit -m "fix: Apply mobile-safe ASCII dashboard, generate missing stunnel cert, and create wg0.conf"
git push origin main
