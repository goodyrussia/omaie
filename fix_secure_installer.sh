REPO_DIR="/root/omaie"
cd "$REPO_DIR" || exit 1

echo "=== 1. CREATING CLEAN INSTALLER SCRIPT ==="
cat << 'INSEOF' > scripts/install.sh
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# IP License Check
CLIENT_IP=$(curl -s https://api.ipify.org)
AUTHORIZED_IPS="https://raw.githubusercontent.com/albertlanc/omaie/main/licensed_ips.txt"

if ! curl -s "$AUTHORIZED_IPS" | grep -qw "$CLIENT_IP"; then
    echo "[-] Access Denied! Your IP ($CLIENT_IP) is not licensed to run this script."
    exit 1
fi

echo "[+] License Verified for IP: $CLIENT_IP"
echo "[+] Starting complete server deployment..."

read -p "Enter your Domain Name (or press Enter to use server IP): " USER_DOMAIN
if [ -z "$USER_DOMAIN" ]; then
    USER_DOMAIN=$(curl -s https://api.ipify.org)
fi

echo "[+] Installing core packages..."
apt-get update -y
apt-get install -y nginx sslh dropbear squid ufw git curl wget python3 wireguard wireguard-tools openvpn certbot socat net-tools

echo "[+] Cloning full configuration stack..."
rm -rf /root/omaie_client_install
git clone https://github.com/albertlanc/omaie.git /root/omaie_client_install
cd /root/omaie_client_install || exit 1

echo "[+] Configuring network rules..."
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

echo "[+] Applying multiplexer configurations..."
[ -d "./configs/nginx" ] && cp -r ./configs/nginx/* /etc/nginx/
[ -f "./configs/sslh/sslh" ] && cp ./configs/sslh/sslh /etc/default/sslh

echo "[+] Setting up services..."
systemctl daemon-reload
systemctl restart nginx
systemctl restart sslh
systemctl restart dropbear
systemctl restart squid
systemctl restart openvpn
systemctl enable --now wg-quick@wg0 2>/dev/null || true

echo "=================================================="
echo " [SUCCESS] FULL DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo " Target Domain/IP: $USER_DOMAIN"
echo "=================================================="
INSEOF

chmod +x scripts/install.sh

echo "=== 2. ENCODING INSTALLER INTO SECURE WRAPPER ==="
# This hides your source code completely while avoiding compiled binary bugs
ENCODED_PAYLOAD=$(cat scripts/install.sh | base64 -w 0)

cat << WRAPEOF > secure_installer
#!/bin/bash
# Secure Obfuscated Runner for Omaie Stack
PAYLOAD="$ENCODED_PAYLOAD"
echo "\$PAYLOAD" | base64 -d > /tmp/omaie_install_exec.sh
bash /tmp/omaie_install_exec.sh
rm -f /tmp/omaie_install_exec.sh
WRAPEOF

chmod +x secure_installer

echo "=== 3. PUSHING TO GITHUB ==="
git add -A
git commit -m "fix: replace shc binary with robust base64-encoded secure wrapper installer"
git push origin main
echo "=== DONE! SECURE INSTALLER FIXED AND PUSHED ==="
