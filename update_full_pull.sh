REPO_DIR="/root/omaie"
cd "$REPO_DIR" || exit 1

cat << 'INSEOF' > scripts/install.sh
#!/bin/bash
CLIENT_IP=$(curl -s https://api.ipify.org)
AUTHORIZED_IPS="https://raw.githubusercontent.com/albertlanc/omaie/main/licensed_ips.txt"

if ! curl -s "$AUTHORIZED_IPS" | grep -qw "$CLIENT_IP"; then
    echo "[-] Access Denied! Your IP ($CLIENT_IP) is not licensed to run this script."
    exit 1
fi

echo "[+] License Verified for IP: $CLIENT_IP"
echo "[+] Cloning full repository stack from GitHub..."

# Clean up any old clone and pull the fresh repo into a temporary installation workspace
rm -rf /root/omaie_client_install
git clone https://github.com/albertlanc/omaie.git /root/omaie_client_install

cd /root/omaie_client_install || { echo "[-] Failed to clone repository."; exit 1; }

echo "[+] Installing dependencies and applying full server stack..."
apt-get update -y
apt-get install -y nginx sslh dropbear squid ufw git curl wget python3 wireguard

# Apply all configuration files harvested from your repository
echo "[+] Applying Nginx and multiplexer configurations..."
[ -d "./configs/nginx" ] && cp -r ./configs/nginx/* /etc/nginx/
[ -f "./configs/default/sslh" ] && cp ./configs/default/sslh /etc/default/sslh

echo "[+] Setting up services and permissions..."
systemctl daemon-reload
systemctl restart nginx
systemctl restart sslh

echo "[+] Installation complete! All protocols and multiplexers are fully deployed from repository."
INSEOF

chmod +x scripts/install.sh

# Re-compile into the secure binary
shc -f scripts/install.sh -o secure_installer
rm -f scripts/install.sh.x.c

# Push updates to GitHub
git add -A
git commit -m "feat: configure installer to clone entire omaie repository and apply all configs automatically"
git push origin main
echo "=== FULL-PULL SECURE INSTALLER COMMITTED AND PUSHED ==="
