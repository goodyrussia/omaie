#!/bin/bash
DGN='\033[0;32m'; LBL='\033[1;36m'; DWH='\033[0;37m'; LRD='\033[1;31m'; WHT='\033[1;37m'; NC='\033[0m'
DB="/etc/smartking4luv/database.sqlite"
IP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
PUB=$(cat /etc/smartking4luv/slowdns_pub 2>/dev/null)

print_account() {
    DOM=$(cat /etc/smartking4luv/domain 2>/dev/null); NS=$(cat /etc/smartking4luv/ns 2>/dev/null); PUB=$(cat /etc/smartking4luv/slowdns_pub 2>/dev/null)
    clear
    UDP_PORT=$(grep -o "127.0.0.1:[0-9]*" /etc/systemd/system/badvpn.service 2>/dev/null | cut -d':' -f2 || echo "udp-custom")
    echo -e "${DGN}┌─ ${DWH}ACCOUNT CREATED SUCCESSFULLY ${DGN}──────────────────────────┐${NC}"
    echo -e " ${LBL}Username    : ${WHT}$1\n ${LBL}Password    : ${WHT}$2\n ${LBL}Expiry      : ${WHT}$3\n ${LBL}Max Login   : ${WHT}$4\n ${LBL}Data Quota  : ${WHT}$5GB\n ${LBL}Server IP   : ${WHT}$IP\n ${LBL}Domain      : ${WHT}$DOM"
    echo -e "${DGN}├─ ${DWH}UDP CUSTOM CONFIGURATION ${DGN}──────────────────────────────┤${NC}"
    echo -e " ${LBL}UDP Server   : ${WHT}$IP\n ${LBL}UDP Port     : ${WHT}1-65535 (Dynamic)\n ${LBL}UDPGW Port   : ${WHT}$UDP_PORT\n ${LBL}Account User : ${WHT}$1\n ${LBL}Account Pass : ${WHT}$2${NC}"
    echo -e "${DGN}├─ ${DWH}MULTIPLE TESTED PAYLOADS ${DGN}──────────────────────────────┤${NC}"
    echo -e " ${DGN}[01. Cloudflare CDN / WebSocket Payload]${NC}\n ${DWH}GET / HTTP/1.1[crlf]Host: $DOM[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf]User-Agent: [ua][crlf][crlf]${NC}"
    echo -e "\n ${DGN}[02. Direct WS / HTTP Custom Payload]${NC}\n ${DWH}GET wss://$DOM/ HTTP/1.1[crlf]Host: $DOM[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]${NC}"
    echo -e "\n ${DGN}[03. SlowDNS (DNSTT) Configuration]${NC}\n ${DWH}Domain : $DOM\n NS     : $NS\n PubKey : $PUB${NC}"
    echo -e "\n ${DGN}[04. Downloadable OpenVPN Config Link]${NC}\n ${DWH}http://$DOM:81/client.ovpn${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Press Enter to return..."
}

select_ssh_user() {
    users=($(sqlite3 "$DB" "SELECT username FROM ssh_users;"))
    if [ ${#users[@]} -eq 0 ]; then echo -e " ${LRD}[!] No users found.${NC}"; return 1; fi
    echo -e "${DGN}┌─ ${DWH}REGISTERED SSH ACCOUNTS ${DGN}───────────────────────────────┐${NC}"
    local i=1
    for u in "${users[@]}"; do
        info=$(sqlite3 "$DB" "SELECT expiry, status FROM ssh_users WHERE username='$u';")
        exp=$(echo "$info" | cut -d'|' -f1); stat=$(echo "$info" | cut -d'|' -f2)
        printf " ${DGN}│${NC} ${LRD}[%02d]${NC} ${WHT}%-16s${NC} Exp: ${LBL}%-10s${NC} Stat: %b\n" "$i" "$u" "$exp" "$stat"
        ((i++))
    done
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Enter choice [Number or Username]: " target
    if [[ "$target" =~ ^[0-9]+$ ]] && [ "$target" -ge 1 ] && [ "$target" -le ${#users[@]} ]; then SELECTED_USER="${users[$((target-1))]}"; else SELECTED_USER="$target"; fi
}

ssh_menu() {
  while true; do
    clear
    tot=$(sqlite3 $DB "SELECT count(*) FROM ssh_users;" 2>/dev/null || echo 0)
    on=$(netstat -anp 2>/dev/null | grep ESTABLISHED | grep sshd | wc -l); off=$((tot - on)); [ $off -lt 0 ] && off=0
    stat=$(systemctl is-active --quiet stunnel4 && echo -e "${DGN}[ONLINE]${NC}" || echo -e "${LRD}[OFFLINE]${NC}")

    echo -e "${DGN}┌─ ${DWH}PROTOCOL MANAGEMENT ${DGN}───────────────────────────────────┐${NC}"
    echo -e "${DGN}├── ${DWH}SSH & UDP CUSTOM PROTOCOL MANAGER ${DGN}────────────────────┤${NC}"
    echo -e "${DGN}│ ${LRD}Total Accounts : ${DWH}$tot             ${LRD}Service : ${DWH}$stat${DGN}      │${NC}"
    echo -e "${DGN}│ ${LRD}Online Users   : ${DWH}$on             ${LRD}Offline : ${DWH}$off${DGN}          │${NC}"
    echo -e "${DGN}├── ${DWH}ACCOUNT PROVISIONING ${DGN}─────────────────────────────────┤${NC}"
    echo -e "${DGN}│ ${LRD}[01]${LBL} Create Premium SSH & UDP Custom User               ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[02]${LBL} Create Trial SSH & UDP User (24 Hours)             ${DGN}│${NC}"
    echo -e "${DGN}├── ${DWH}ACCOUNT MANAGEMENT ${DGN}───────────────────────────────────┤${NC}"
    echo -e "${DGN}│ ${LRD}[03]${LBL} Renew / Extend SSH User                            ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[04]${LBL} Lock SSH User (Disable Login)                      ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[05]${LBL} Unlock SSH User (Enable Login)                     ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[06]${LBL} Delete SSH User                                    ${DGN}│${NC}"
    echo -e "${DGN}├── ${DWH}MONITORING & DIAGNOSTICS ${DGN}─────────────────────────────┤${NC}"
    echo -e "${DGN}│ ${LRD}[07]${LBL} Live Monitor & Multi-Login Manager                 ${DGN}│${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}\n"
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${LRD}[00]${LBL} Back to Main Menu                                  ${DGN}│${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select an option [00-07]: " opt
    
    case $opt in
      01|1) clear; echo -e "${DGN}┌─ ${DWH}CREATE PREMIUM ACCOUNT ${DGN}────────────────────────────────┐${NC}"
         read -p " Username: " u; read -p " Password: " p; read -p " Days: " d; read -p " Max Logins: " m; read -p " Quota (GB): " q
         e=$(date -d "+$d days" +"%Y-%m-%d"); sqlite3 $DB "INSERT INTO ssh_users VALUES ('$u','$p','$e',$q,$m,'ACTIVE');"
         useradd -e "$e" -s /bin/false -M "$u" 2>/dev/null; echo "$u:$p" | chpasswd 2>/dev/null
         print_account "$u" "$p" "$e" "$m" "$q" ;;
      02|2) clear; echo -e "${DGN}┌─ ${DWH}GENERATING TRIAL ACCOUNT (24H) ${DGN}────────────────────────┐${NC}"
         u="trial_$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 4 | head -n 1)"; p=$((RANDOM % 8999 + 1000)); d=1; m=1; q=1
         e=$(date -d "+1 day" +"%Y-%m-%d"); sqlite3 $DB "INSERT INTO ssh_users VALUES ('$u','$p','$e',$q,$m,'ACTIVE');"
         useradd -e "$e" -s /bin/false -M "$u" 2>/dev/null; echo "$u:$p" | chpasswd 2>/dev/null
         print_account "$u" "$p" "$e" "$m" "$q" ;;
      03|3) clear; echo -e "${DGN}┌─ ${DWH}RENEW SSH ACCOUNT ${DGN}─────────────────────────────────────┐${NC}"
         select_ssh_user || { read -p " Press Enter..."; continue; }
         read -p " Add Days: " d; e=$(date -d "+$d days" +"%Y-%m-%d"); usermod -e "$e" "$SELECTED_USER" 2>/dev/null
         sqlite3 $DB "UPDATE ssh_users SET expiry='$e' WHERE username='$SELECTED_USER';"
         echo -e " ${DGN}[+] Account $SELECTED_USER renewed to $e${NC}"; read -p " Press Enter..." ;;
      04|4) clear; echo -e "${DGN}┌─ ${DWH}LOCK SSH USER ${DGN}─────────────────────────────────────────┐${NC}"
         select_ssh_user || { read -p " Press Enter..."; continue; }
         usermod -L "$SELECTED_USER" 2>/dev/null; sqlite3 $DB "UPDATE ssh_users SET status='LOCKED' WHERE username='$SELECTED_USER';"
         echo -e " ${DGN}[+] Account $SELECTED_USER LOCKED.${NC}"; read -p " Press Enter..." ;;
      05|5) clear; echo -e "${DGN}┌─ ${DWH}UNLOCK SSH USER ${DGN}───────────────────────────────────────┐${NC}"
         select_ssh_user || { read -p " Press Enter..."; continue; }
         usermod -U "$SELECTED_USER" 2>/dev/null; sqlite3 $DB "UPDATE ssh_users SET status='ACTIVE' WHERE username='$SELECTED_USER';"
         echo -e " ${DGN}[+] Account $SELECTED_USER UNLOCKED.${NC}"; read -p " Press Enter..." ;;
      06|6) clear; echo -e "${DGN}┌─ ${DWH}DELETE SSH USER ${DGN}───────────────────────────────────────┐${NC}"
         select_ssh_user || { read -p " Press Enter..."; continue; }
         userdel -f "$SELECTED_USER" 2>/dev/null; sqlite3 $DB "DELETE FROM ssh_users WHERE username='$SELECTED_USER';"
         echo -e " ${LRD}[-] Account $SELECTED_USER removed.${NC}"; read -p " Press Enter..." ;;
      
      07|7) clear
         echo -e "${DGN}┌─ ${DWH}LIVE MONITOR & MULTI-LOGIN MANAGER ${DGN}────────────────────┐${NC}"
         echo -e "${DGN}│ ${WHT}USER         STATUS     MULTI-LOGIN   DEVICE              ${DGN}│${NC}"
         echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
         
         users=$(sqlite3 $DB "SELECT username, max_login FROM ssh_users;" 2>/dev/null)
         if [ -z "$users" ]; then
             echo -e "  ${LRD}No registered users found in database.${NC}"
         else
             for entry in $users; do
                 u=$(echo $entry | cut -d'|' -f1)
                 max=$(echo $entry | cut -d'|' -f2)
                 
                 # Accurately count Dropbear and OpenSSH active sessions
                 c_ssh=$(pgrep -u "$u" sshd | wc -l)
                 c_drop=$(pgrep -u "$u" dropbear | wc -l)
                 conns=$((c_ssh + c_drop))
                 
                 u_pad=$(printf "%-12s" "$u")
                 
                 if [ "$conns" -gt 0 ]; then
                     s_pad="${DGN}$(printf "%-10s" "Online")${NC}"
                     
                     if [ "$conns" -gt "$max" ]; then
                         m_pad="${LRD}$(printf "%-13s" "YES ($conns/$max)")${NC}"
                     else
                         m_pad="${WHT}$(printf "%-13s" "NO ($conns/$max)")${NC}"
                     fi
                     
                     # Check Auth logs for Android/iOS identification
                     recent_log=$(grep -E "sshd|dropbear" /var/log/auth.log 2>/dev/null | grep "$u" | tail -n 50)
                     if echo "$recent_log" | grep -qiE "httpcustom|netmod|android|injector|termux"; then
                         device="${DGN}Android OS${NC}"
                     elif echo "$recent_log" | grep -qiE "iphone|ios|shadowrocket|napsternet"; then
                         device="${LBL}Apple iOS${NC}"
                     else
                         device="${LBL}Android / iOS${NC}"
                     fi
                 else
                     s_pad="${LRD}$(printf "%-10s" "Offline")${NC}"
                     m_pad="${DWH}$(printf "%-13s" "NO (0/$max)")${NC}"
                     device="${DWH}-${NC}"
                 fi
                 
                 echo -e "  ${LBL}${u_pad}${NC} ${s_pad} ${m_pad} ${device}"
             done
         fi
         echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
         echo -e "  ${LRD}[1]${NC} ${DWH}Auto-Kill All Multi-Login Violators${NC}"
         echo -e "  ${LRD}[2]${NC} ${DWH}Kill Specific User Sessions${NC}"
         echo -e "  ${LRD}[0]${NC} ${DWH}Back to Protocol Menu${NC}"
         echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
         read -p " Select an option [00-02]: " m_opt
         case $m_opt in
             1) 
                echo -e " ${DGN}[*] Scanning for multi-login violators...${NC}"
                found=0
                for entry in $users; do
                    u=$(echo $entry | cut -d'|' -f1)
                    max=$(echo $entry | cut -d'|' -f2)
                    c_s=$(pgrep -u "$u" sshd | wc -l)
                    c_d=$(pgrep -u "$u" dropbear | wc -l)
                    c_t=$((c_s + c_d))
                    if [ "$c_t" -gt "$max" ]; then
                        # pkill and killall perfectly target processes spawned by the violating user
                        killall -u "$u" -9 2>/dev/null || pkill -u "$u" 2>/dev/null
                        echo -e " ${LRD}[-] Disconnected $c_t excess sessions for: $u${NC}"
                        found=1
                    fi
                done
                if [ "$found" -eq 0 ]; then echo -e " ${DWH}No multi-login violators found.${NC}"; fi
                read -p " Press Enter..." ;;
             2) 
                read -p " Enter Username to disconnect: " k_user
                killall -u "$k_user" -9 2>/dev/null || pkill -u "$k_user" 2>/dev/null
                echo -e " ${DGN}[+] All active sessions terminated for $k_user.${NC}"
                read -p " Press Enter..." ;;
             0) continue ;;
         esac
         ;;
      00|0) return ;;
    esac
  done
}
ssh_menu
