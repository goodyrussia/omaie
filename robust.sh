#!/bin/bash
cd /root/smartking4luv-v2

# --- 1. ROBUST SSH MANAGER ---
cat << 'EOF' > protocols/ssh.sh
#!/bin/bash
DB="/etc/smartking4luv/database.sqlite"; DOM=$(cat /etc/smartking4luv/domain 2>/dev/null); NS=$(cat /etc/smartking4luv/ns 2>/dev/null); IP=$(curl -sS ipv4.icanhazip.com 2>/dev/null); PUB=$(cat /etc/smartking4luv/slowdns_pub 2>/dev/null)
ssh_menu() {
  while true; do
    clear; echo -e "\033[0;36m=== 🔐 SSH & OPENVPN MANAGER ===\033[0m"
    echo -e "1. Create Account\n2. Renew Account\n3. Delete Account\n4. Lock/Unlock Account\n5. Account Stats\n0. Back"
    read -p "Select: " opt
    case $opt in
      1) clear; read -p "Username: " u; read -p "Password: " p; read -p "Days: " d; read -p "Max Logins: " m; read -p "Quota (GB): " q
         e=$(date -d "+$d days" +"%Y-%m-%d"); sqlite3 $DB "INSERT INTO ssh_users VALUES ('$u','$p','$e',$q,$m,'ACTIVE');"
         useradd -e "$e" -s /bin/false -M "$u"; echo "$u:$p" | chpasswd
         clear; echo -e "\033[1;32m=== ACCOUNT CREATED ===\033[0m\nUsername: $u\nPassword: $p\nExpiry: $e\nMax Login: $m\nData Quota: ${q}GB"
         echo -e "Server IP: $IP\nDomain: $DOM\nName Server: $NS\n\n\033[1;33mSupported Ports:\033[0m\n- SSH-WS: 80 / 443\n- SSL/Stunnel: 444\n- Dropbear: 109\n- SlowDNS: 53\n- Squid: 8080, 3128\n- BadVPN/UDPGW: 7300\n\n\033[1;33m[Payloads]\033[0m"
         echo -e "WS/WSS: GET wss://$DOM/ HTTP/1.1[crlf]Host: $DOM[crlf]Upgrade: websocket[crlf][crlf]"
         echo -e "SlowDNS: $DOM / $NS / $PUB\nOpenVPN: http://$DOM:81/client.ovpn\n"; read -p "Press Enter..." ;;
      2) clear; echo -e "\033[1;33m--- Renew Account ---\033[0m\nActive Users:"; sqlite3 $DB "SELECT username, expiry FROM ssh_users;"
         read -p "Username: " u; read -p "Add Days: " d; e=$(date -d "+$d days" +"%Y-%m-%d"); usermod -e "$e" "$u"
         sqlite3 $DB "UPDATE ssh_users SET expiry='$e' WHERE username='$u'"; echo "Renewed to $e"; read -p "Enter..." ;;
      3) clear; echo -e "\033[1;31m--- Delete Account ---\033[0m\nActive Users:"; sqlite3 $DB "SELECT username FROM ssh_users;"
         read -p "Username: " u; userdel -f "$u"; sqlite3 $DB "DELETE FROM ssh_users WHERE username='$u'"; echo "Deleted"; read -p "Enter..." ;;
      4) clear; echo -e "\033[1;34m--- Lock/Unlock ---\033[0m\nUser Status:"; sqlite3 $DB "SELECT username, status FROM ssh_users;"
         read -p "Username: " u; read -p "Lock(L) or Unlock(U)?: " a
         if [[ "$a" == "L" || "$a" == "l" ]]; then usermod -L "$u"; sqlite3 $DB "UPDATE ssh_users SET status='LOCKED' WHERE username='$u'"; echo "Locked"; fi
         if [[ "$a" == "U" || "$a" == "u" ]]; then usermod -U "$u"; sqlite3 $DB "UPDATE ssh_users SET status='ACTIVE' WHERE username='$u'"; echo "Unlocked"; fi
         read -p "Enter..." ;;
      5) clear; echo -e "\033[1;36m--- SSH Stats ---\033[0m"
         tot=$(sqlite3 $DB "SELECT count(*) FROM ssh_users;"); on=$(netstat -anp | grep ESTABLISHED | grep sshd | wc -l); off=$((tot - on))
         echo -e "Total Accounts: $tot\nOnline Users: $on\nOffline Users: $off"; read -p "Enter..." ;;
      0) return ;;
    esac
  done
}
EOF

# --- 2. ROBUST XRAY MANAGER ---
cat << 'EOF' > protocols/xray.sh
#!/bin/bash
DB="/etc/smartking4luv/database.sqlite"; DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)
xray_menu() {
  while true; do
    clear; echo -e "\033[0;36m=== 🚀 XRAY & SS MANAGER ===\033[0m"
    echo -e "1. Create (Vless/Vmess/Trojan/SS)\n2. Renew Account\n3. Delete Account\n0. Back"
    read -p "Select: " opt
    case $opt in
      1) clear; read -p "Protocol (vless/vmess/trojan/ss): " pr; read -p "Username: " u; read -p "Days: " d
         id=$(uuidgen); e=$(date -d "+$d days" +"%Y-%m-%d"); sqlite3 $DB "INSERT INTO xray_users VALUES ('$u','$id','$pr','$e');"
         clear; echo -e "\033[1;32m=== $pr ACCOUNT CREATED ===\033[0m\nUser: $u | UUID: $id | Expiry: $e\n\033[1;33m[Payload Links]\033[0m"
         if [ "$pr" == "vless" ]; then echo -e "TLS (443): vless://$id@$DOM:443?path=/vmess&security=tls&encryption=none&type=ws#$u\nNon-TLS (80): vless://$id@$DOM:80?path=/vmess&security=none&encryption=none&type=ws#$u"; fi
         if [ "$pr" == "vmess" ]; then echo -e "VMess WS: vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$u\",\"add\":\"$DOM\",\"port\":\"443\",\"id\":\"$id\",\"net\":\"ws\",\"path\":\"/xray\",\"tls\":\"tls\"}" | base64 -w 0)"; fi
         if [ "$pr" == "trojan" ]; then echo -e "Trojan TLS: trojan://$id@$DOM:443?path=/vmess&security=tls&type=ws#$u"; fi
         if [ "$pr" == "ss" ]; then echo -e "Shadowsocks SR: ss://$(echo -n "aes-128-gcm:$id" | base64 -w 0)@$DOM:10005#$u"; fi
         read -p "Enter..." ;;
      2) clear; echo "Xray Accounts:"; sqlite3 $DB "SELECT username, protocol, expiry FROM xray_users;"; read -p "User to Renew: " u; read -p "Add Days: " d
         e=$(date -d "+$d days" +"%Y-%m-%d"); sqlite3 $DB "UPDATE xray_users SET expiry='$e' WHERE username='$u'"; echo "Renewed"; read -p "Enter..." ;;
      3) clear; echo "Xray Accounts:"; sqlite3 $DB "SELECT username, protocol FROM xray_users;"; read -p "User to Delete: " u
         sqlite3 $DB "DELETE FROM xray_users WHERE username='$u'"; echo "Deleted"; read -p "Enter..." ;;
      0) return ;;
    esac
  done
}
EOF

# --- 3. ROBUST WIREGUARD MANAGER ---
cat << 'EOF' > protocols/wireguard.sh
#!/bin/bash
wg_menu() {
  while true; do
    clear; echo -e "\033[0;36m=== 🛡️ WIREGUARD MANAGER ===\033[0m\n1. Create Client\n2. View Existing Clients\n0. Back"
    read -p "Select: " opt
    case $opt in
      1) read -p "Client Name: " u; ip="10.66.66.$(($RANDOM % 200 + 2))"; p=$(wg genkey); pub=$(echo "$p" | wg pubkey); dom=$(cat /etc/smartking4luv/domain)
         echo -e "\n[Peer]\nPublicKey = $pub\nAllowedIPs = $ip/32" >> /etc/wireguard/wg0.conf; systemctl restart wg-quick@wg0
         clear; echo -e "\033[1;32m=== WG CLIENT CONFIG ===\033[0m\n[Interface]\nPrivateKey = $p\nAddress = $ip/32\nDNS = 8.8.8.8\n\n[Peer]\nPublicKey = $(cat /etc/wireguard/publickey)\nEndpoint = $dom:51820\nAllowedIPs = 0.0.0.0/0"
         echo "$u : $ip" >> /etc/wireguard/clients.txt; read -p "Enter..." ;;
      2) clear; echo "Active Clients:"; cat /etc/wireguard/clients.txt 2>/dev/null; read -p "Enter..." ;;
      0) return ;;
    esac
  done
}
EOF

# --- 4 & 5. DOMAIN/SSL & PORT MANAGER ---
cat << 'EOF' > menu/ssl_manager.sh
#!/bin/bash
ssl_menu() {
  clear; echo -e "\033[0;36m=== 🌐 DOMAIN & SSL MANAGER ===\033[0m\n1. Change Domain/NS\n2. Renew SSL (Acme.sh)\n0. Back"
  read -p "Select: " opt
  if [ "$opt" == "1" ]; then read -p "New Domain: " d; read -p "New NS: " n; echo "$d" > /etc/smartking4luv/domain; echo "$n" > /etc/smartking4luv/ns; echo "Updated."; read -p "Enter..."; fi
  if [ "$opt" == "2" ]; then ~/.acme.sh/acme.sh --issue -d $(cat /etc/smartking4luv/domain) --standalone; ~/.acme.sh/acme.sh --installcert -d $(cat /etc/smartking4luv/domain) --fullchainpath /etc/ssl/smartking.pem --keypath /etc/ssl/smartking.key; systemctl restart stunnel4 haproxy; echo "Renewed."; read -p "Enter..."; fi
}
EOF

cat << 'EOF' > menu/port_manager.sh
#!/bin/bash
port_menu() {
  clear; echo -e "\033[0;36m=== 🔌 PORT MANAGER ===\033[0m\nActive Ports:"
  ss -tulpn | awk '{print $5, $7}' | grep -E 'haproxy|stunnel|dropbear|xray|squid|badvpn|wg'
  echo -e "\n1. Change Dropbear Port\n0. Back"
  read -p "Select: " opt
  if [ "$opt" == "1" ]; then read -p "New Port: " p; sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$p/g" /etc/default/dropbear; systemctl restart dropbear; echo "Changed to $p"; read -p "Enter..."; fi
}
EOF

# --- 6 & 7. MONITOR & UNINSTALL ---
cat << 'EOF' > menu/monitor.sh
#!/bin/bash
monitor_menu() {
  clear; echo -e "\033[0;36m=== 📊 SYSTEM MONITOR ===\033[0m\n\033[1;33mBandwidth Usage:\033[0m"
  ifconfig | grep -E 'RX packets|TX packets'
  echo -e "\n\033[1;33mActive Connections:\033[0m"
  netstat -anp | grep ESTABLISHED | awk '{print $4, $5, $7}' | head -n 15
  read -p "Press Enter..."
}
EOF

cat << 'EOF' > menu/uninstall.sh
#!/bin/bash
uninstall_menu() {
  clear; echo -e "\033[1;31m=== 🗑️ UNINSTALL SYSTEM ===\033[0m"
  read -p "Are you absolutely sure? This removes everything. (y/n): " c
  if [ "$c" == "y" ]; then
    systemctl stop haproxy nginx stunnel4 dropbear squid openvpn xray badvpn client-dnstt wg-quick@wg0
    apt-get purge -y haproxy nginx stunnel4 dropbear squid openvpn wireguard sqlite3
    rm -rf /etc/smartking4luv /etc/xray /etc/wireguard /etc/squid /etc/haproxy /usr/local/bin/menu
    echo "Cleanup complete. Bye."; exit 0
  fi
}
EOF

# --- INJECT INTO INSTALL.SH ---
sed -i '/source menu\/port_manager.sh/a source menu/monitor.sh; source menu/uninstall.sh' install.sh
sed -i 's/6) clear.*/6) monitor_menu ;;/g' install.sh
sed -i 's/7) read -p.*/7) uninstall_menu ;;/g' install.sh

# --- PUSH TO GIT ---
git add .
git commit -m "feat: Total rebuild of all submenus to match original prompt spec (Lists, Stats, VMess/Trojan, Complete Payloads, Monitor)"
git push origin main
