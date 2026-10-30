REPO_DIR="/root/omaie"
cd "$REPO_DIR" || exit 1

cat << 'INSEOF' > scripts/install.sh
#!/bin/bash

# 1. IP LICENSE CHECK
CLIENT_IP=$(curl -s https://api.ipify.org)
AUTHORIZED_IPS="https://raw.githubusercontent.com/albertlanc/omaie/main/licensed_ips.txt"

if ! curl -s "$AUTHORIZED_IPS" | grep -qw "$CLIENT_IP"; then
    echo "[-] Access Denied! Your IP ($CLIENT_IP) is not licensed to run this script."
    exit 1
fi

echo "[+] License Verified for IP: $CLIENT_IP"
echo "[+] Starting complete server deployment..."

# 2. PROMPT FOR DOMAIN / NS
read -p "Enter your Domain Name (or press Enter to use server IP): " USER_DOMAIN
if [ -z "$USER_DOMAIN" ]; then
    USER_DOMAIN=$(curl -s https://api.ipify.org)
fi
echo "[+] Using Domain/IP: $USER_DOMAIN"

# 3. INSTALL SYSTEM DEPENDENCIES & UTILITIES
echo "[+] Installing core packages and dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx sslh dropbear squid ufw git curl wget python3 wireguard wireguard-tools openvpn certbot socat net-tools

# 4. CLONE REPOSITORY FILES
echo "[+] Fetching full configuration stack..."
rm -rf /root/omaie_client_install
git clone https://github.com/albertlanc/omaie.git /root/omaie_client_install
cd /root/omaie_client_install || { echo "[-] Failed to clone repository."; exit 1; }

# 5. CONFIGURE PORTS & FIREWALL
echo "[+] Configuring firewall and network rules..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 109/tcp
ufw allow 444/tcp
ufw allow 53/udp
ufw allow 1194/udp
ufw allow 3128/tcp
ufw allow 51820/udp
ufw allow 7300/udp
ufw --force enable

# 6. GENERATE / SETUP SSL CERTIFICATE
echo "[+] Setting up SSL certificates for $USER_DOMAIN..."
mkdir -p /etc/v2ray /etc/xray
if command -v certbot &> /dev/null && [[ "$USER_DOMAIN" != *"$(curl -s https://api.ipify.org)*" ]]; then
    systemctl stop nginx
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$USER_DOMAIN" --non-interactive || true
    systemctl start nginx
fi

# 7. APPLY CONFIGURATIONS FROM REPOSITORY
echo "[+] Applying multiplexer and protocol configurations..."
[ -d "./configs/nginx" ] && cp -r ./configs/nginx/* /etc/nginx/
[ -f "./configs/sslh/sslh" ] && cp ./configs/sslh/sslh /etc/default/sslh

# 8. RESTORE DASHBOARD MENU DESIGN
echo "[+] Installing dashboard menu tools..."
if [ -d "./menu" ]; then
    cp -r ./menu/* /usr/local/bin/ 2>/dev/null || cp -r ./menu/* /usr/bin/ 2>/dev/null
    chmod +x /usr/local/bin/* /usr/bin/* 2>/dev/null
fi

# 9. START & ENABLE ALL SERVICES
echo "[+] Starting and enabling all backend services..."
systemctl daemon-reload
systemctl restart nginx
systemctl restart sslh
systemctl restart dropbear
systemctl restart squid
systemctl restart openvpn
systemctl enable --now wg-quick@wg0 2>/dev/null || true
systemctl restart udp-custom 2>/dev/null || true

echo "=================================================="
echo " [SUCCESS] FULL DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo " Target Domain/IP: $USER_DOMAIN"
echo " Type 'menu' to access your server control panel."
echo "=================================================="
INSEOF

chmod +x scripts/install.sh

# Re-compile into the secure binary
shc -f scripts/install.sh -o secure_installer
rm -f scripts/install.sh.x.c

# Push updates to GitHub
git add -A
git commit -m "feat: upgrade master installer to fully configure domain, certs, dependencies, ports, protocols, and dashboard"
git push origin main
echo "=== MASTER INSTALLER UPDATED AND PUSHED TO GITHUB ==="
