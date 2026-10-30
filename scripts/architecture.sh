#!/bin/bash
cd /root/smartking4luv-v2

# 1. FORCE SLOWDNS KEY GENERATION
echo "[*] Forcing SlowDNS Key Generation..."
wget -qO /usr/local/bin/dnstt-server "https://github.com/Yukkiteru/dnstt/releases/latest/download/dnstt-server"
chmod +x /usr/local/bin/dnstt-server
mkdir -p /etc/slowdns /etc/smartking4luv
/usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
    cat /etc/slowdns/server.pub > /etc/smartking4luv/slowdns_pub

# 2. SEPARATE PROTOCOL MANAGERS
# --- OpenVPN Manager ---
cat << 'EOF' > protocols/openvpn.sh
#!/bin/bash
openvpn_menu() {
  while true; do
    clear; echo -e "\033[0;36m==============================================================\n\033[1;37m                 OPENVPN MANAGER                              \033[0m\n\033[0;36m==============================================================\033[0m"
    echo -e "\033[1;32m [1]\033[0m Create OpenVPN Account\n\033[1;32m [2]\033[0m Renew Account\n\033[1;32m [3]\033[0m Delete Account\n\033[0;36m--------------------------------------------------------------\033[0m\n\033[1;31m [0]\033[0m Back to Main Menu\n\033[0;36m==============================================================\033[0m"
    read -p " Select: " opt
    case $opt in
      1) read -p " Username: " u; read -p " Password: " p; read -p " Days: " d
         e=$(date -d "+$d days" +"%Y-%m-%d"); sqlite3 /etc/smartking4luv/database.sqlite "INSERT INTO ssh_users (username, password, expiry, status) VALUES ('$u','$p','$e','ACTIVE');"
         useradd -e "$e" -s /bin/false -M "$u" 2>/dev/null; echo "$u:$p" | chpasswd 2>/dev/null
         echo -e "\n \033[1;32m[+] OpenVPN Account Created\033[0m\n Config: http://$(cat /etc/smartking4luv/domain):81/client.ovpn"; read -p " Enter..." ;;
      0) return ;;
      *) echo "WIP"; sleep 1 ;;
    esac
  done
}
EOF

# --- Individual Xray Managers ---
for proto in vless vmess trojan; do
cat << EOF > protocols/${proto}.sh
#!/bin/bash
${proto}_menu() {
  while true; do
    clear; echo -e "\033[0;36m==============================================================\n\033[1;37m                 XRAY ${proto^^} MANAGER                              \033[0m\n\033[0;36m==============================================================\033[0m"
    echo -e "\033[1;32m [1]\033[0m Create ${proto^^} Account\n\033[1;32m [2]\033[0m Renew Account\n\033[1;32m [3]\033[0m Delete Account\n\033[0;36m--------------------------------------------------------------\033[0m\n\033[1;31m [0]\033[0m Back to Main Menu\n\033[0;36m==============================================================\033[0m"
    read -p " Select: " opt
    case \$opt in
      1) read -p " Username: " u; read -p " Days: " d; id=\$(uuidgen); e=\$(date -d "+\$d days" +"%Y-%m-%d")
         sqlite3 /etc/smartking4luv/database.sqlite "INSERT INTO xray_users VALUES ('\$u','\$id','${proto}','\$e');"
         echo -e "\n \033[1;32m[+] ${proto^^} Account Created for \$u\033[0m"; read -p " Enter..." ;;
      0) return ;;
      *) echo "WIP"; sleep 1 ;;
    esac
  done
}
EOF
done

# --- Shadowsocks Manager ---
cat << 'EOF' > protocols/shadowsocks.sh
#!/bin/bash
ss_menu() {
  while true; do
    clear; echo -e "\033[0;36m==============================================================\n\033[1;37m                 SHADOWSOCKS MANAGER                          \033[0m\n\033[0;36m==============================================================\033[0m"
    echo -e "\033[1;32m [1]\033[0m Create SS Account\n\033[1;32m [2]\033[0m Renew Account\n\033[1;32m [3]\033[0m Delete Account\n\033[0;36m--------------------------------------------------------------\033[0m\n\033[1;31m [0]\033[0m Back to Main Menu\n\033[0;36m==============================================================\033[0m"
    read -p " Select: " opt
    case $opt in
      1) read -p " Username: " u; read -p " Days: " d; id=$(uuidgen); e=$(date -d "+$d days" +"%Y-%m-%d")
         sqlite3 /etc/smartking4luv/database.sqlite "INSERT INTO xray_users VALUES ('$u','$id','ss','$e');"
         echo -e "\n \033[1;32m[+] Shadowsocks Account Created\033[0m"; read -p " Enter..." ;;
      0) return ;;
      *) echo "WIP"; sleep 1 ;;
    esac
  done
}
EOF

# 3. REBUILD DASHBOARD UI WITH ISOLATED MENUS
cat << 'EOF' > menu/dashboard.sh
#!/bin/bash
get_status() { systemctl is-active --quiet $1 && echo -e "\033[0;32m[ON]\033[0m" || echo -e "\033[0;31m[OFF]\033[0m"; }
show_dashboard() {
    clear
    UPTIME=$(uptime -p | cut -d " " -f 2-); RAM=$(free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100) }')
    DOMAIN=$(cat /etc/smartking4luv/domain 2>/dev/null || echo "Not Set"); IP=$(curl -sS ipv4.icanhazip.com 2>/dev/null)

    echo -e "\033[0;36m==============================================================\033[0m"
    echo -e "\033[1;37m                 SMARTKING4LUV v2 PREMIUM UI                  \033[0m"
    echo -e "\033[0;36m==============================================================\033[0m"
    echo -e " \033[1;33mOS:\033[0m $HOSTNAME\n \033[1;33mIP:\033[0m $IP\n \033[1;33mDomain:\033[0m $DOMAIN\n \033[1;33mRAM:\033[0m $RAM         \033[1;33mUptime:\033[0m $UPTIME"
    echo -e "\033[0;36m--------------------------------------------------------------\033[0m"
    echo -e "\033[1;37m                       SERVICE STATUS                         \033[0m"
    echo -e "\033[0;36m--------------------------------------------------------------\033[0m"
    echo -e " SSH-WS: $(get_status stunnel4)     XRAY: $(get_status xray)        WG: $(get_status wg-quick@wg0)"
    echo -e " OVPN: $(get_status openvpn)       HAPROXY: $(get_status haproxy)     SQUID: $(get_status squid)"
    echo -e "\033[0;36m==============================================================\033[0m"
    echo -e "\033[1;32m [1]\033[0m 🔐 SSH Manager               \033[1;32m [6]\033[0m 👻 Shadowsocks Manager"
    echo -e "\033[1;32m [2]\033[0m 🌐 OpenVPN Manager           \033[1;32m [7]\033[0m 🛡️ WireGuard Manager"
    echo -e "\033[1;32m [3]\033[0m 🚀 Xray VLESS Manager        \033[1;32m [8]\033[0m ⚙️ Domain & Port Manager"
    echo -e "\033[1;32m [4]\033[0m 🚀 Xray VMESS Manager        \033[1;32m [9]\033[0m 📊 System Monitor"
    echo -e "\033[1;32m [5]\033[0m 🚀 Xray Trojan Manager       \033[1;32m [10]\033[0m🗑️ Uninstall System"
    echo -e "\033[0;36m--------------------------------------------------------------\033[0m"
    echo -e "\033[1;31m [0]\033[0m ❌ Exit Dashboard"
    echo -e "\033[0;36m==============================================================\033[0m"
}
EOF

# 4. UPDATE INSTALL.SH TO ROUTE NEW MENUS
cat << 'EOF' > install.sh
#!/bin/bash
source core/init.sh; source modules/setup.sh; source modules/advanced_setup.sh
source protocols/ssh.sh; source protocols/openvpn.sh
source protocols/vless.sh; source protocols/vmess.sh; source protocols/trojan.sh; source protocols/shadowsocks.sh
source protocols/wireguard.sh; source menu/ssl_manager.sh; source menu/port_manager.sh
source menu/monitor.sh; source menu/uninstall.sh; source menu/dashboard.sh

check_license
while true; do
    show_dashboard
    read -p " Select Menu: " opt
    case $opt in
        1) ssh_menu ;; 2) openvpn_menu ;; 3) vless_menu ;; 4) vmess_menu ;; 5) trojan_menu ;;
        6) ss_menu ;; 7) wg_menu ;; 8) ssl_menu ;; 9) monitor_menu ;; 10) uninstall_menu ;; 0) clear; exit 0 ;;
    esac
done
EOF

chmod +x install.sh core/*.sh modules/*.sh protocols/*.sh menu/*.sh

# 5. GIT PUSH
git add .
git commit -m "feat: Completely separated all protocol managers into isolated submenus and fixed SlowDNS binary generation"
git push origin main
