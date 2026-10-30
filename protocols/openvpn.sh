#!/bin/bash
DGN='\033[0;32m'; LBL='\033[1;36m'; DWH='\033[0;37m'; LRD='\033[1;31m'; WHT='\033[1;37m'; NC='\033[0m'
DB="/etc/smartking4luv/database.sqlite"; DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)

select_ovpn_user() {
    users=($(sqlite3 "$DB" "SELECT username FROM ssh_users;"))
    if [ ${#users[@]} -eq 0 ]; then echo -e " ${LRD}[!] No OpenVPN/SSH users found.${NC}"; return 1; fi
    echo -e "${DGN}┌─ ${DWH}REGISTERED OPENVPN ACCOUNTS ${DGN}───────────────────────────┐${NC}"
    local i=1
    for u in "${users[@]}"; do
        exp=$(sqlite3 "$DB" "SELECT expiry FROM ssh_users WHERE username='$u';")
        printf " ${DGN}│${NC} ${LRD}[%02d]${NC} ${WHT}%-16s${NC} Exp: ${LBL}%-10s${NC}\n" "$i" "$u" "$exp"
        ((i++))
    done
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Enter choice [Number or Username]: " target
    if [[ "$target" =~ ^[0-9]+$ ]] && [ "$target" -ge 1 ] && [ "$target" -le ${#users[@]} ]; then SELECTED_USER="${users[$((target-1))]}"; else SELECTED_USER="$target"; fi
}

openvpn_menu() {
  local DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)
  while true; do
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${DWH}               OPENVPN PROTOCOL MANAGER                 ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[1]${NC} ${DWH}Create OpenVPN User${NC}"
    echo -e "  ${LRD}[2]${NC} ${DWH}Create Trial OpenVPN User (24H)${NC}"
    echo -e "  ${LRD}[3]${NC} ${DWH}Renew / Extend OpenVPN User${NC}"
    echo -e "  ${LRD}[4]${NC} ${DWH}Delete OpenVPN User${NC}"
    echo -e "  ${LRD}[5]${NC} ${DWH}Download / View .ovpn Config Link${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[0]${NC} ${DWH}Back to Main Menu${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select an option: " opt
    case $opt in
      1) clear; echo -e "${DGN}┌─ ${DWH}CREATE OPENVPN ACCOUNT ${DGN}────────────────────────────────┐${NC}"
         read -p " Username: " u; read -p " Password: " p; read -p " Days: " d
         e=$(date -d "+$d days" +"%Y-%m-%d"); sqlite3 $DB "INSERT INTO ssh_users VALUES ('$u','$p','$e',10,1,'ACTIVE');"
         useradd -e "$e" -s /bin/false -M "$u" 2>/dev/null; echo "$u:$p" | chpasswd 2>/dev/null
         echo -e " ${DGN}[+] Account Created!${NC}\n ${LRD}Download Client Config:${NC} ${WHT}http://$DOM:81/client.ovpn${NC}"
         echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"; read -p " Press Enter..." ;;
      2) clear; echo -e "${DGN}┌─ ${DWH}CREATE OPENVPN TRIAL ${DGN}──────────────────────────────────┐${NC}"
         u="ovpn_trial_$((RANDOM % 899 + 100))"; p=$((RANDOM % 8999 + 1000)); e=$(date -d "+1 day" +"%Y-%m-%d")
         sqlite3 $DB "INSERT INTO ssh_users VALUES ('$u','$p','$e',1,1,'ACTIVE');"
         useradd -e "$e" -s /bin/false -M "$u" 2>/dev/null; echo "$u:$p" | chpasswd 2>/dev/null
         echo -e " ${DGN}[+] Trial Created: $u (Pass: $p)${NC}\n ${LRD}Config Link:${NC} ${WHT}http://$DOM:81/client.ovpn${NC}"
         echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"; read -p " Press Enter..." ;;
      3) clear; echo -e "${DGN}┌─ ${DWH}RENEW OPENVPN ACCOUNT ${DGN}─────────────────────────────────┐${NC}"
         select_ovpn_user || { read -p " Press Enter..."; continue; }
         read -p " Add Days: " d; e=$(date -d "+$d days" +"%Y-%m-%d"); usermod -e "$e" "$SELECTED_USER" 2>/dev/null
         sqlite3 $DB "UPDATE ssh_users SET expiry='$e' WHERE username='$SELECTED_USER';"
         echo -e " ${DGN}[+] Account $SELECTED_USER renewed to $e${NC}"; read -p " Press Enter..." ;;
      4) clear; echo -e "${DGN}┌─ ${DWH}DELETE OPENVPN USER ${DGN}───────────────────────────────────┐${NC}"
         select_ovpn_user || { read -p " Press Enter..."; continue; }
         userdel -f "$SELECTED_USER" 2>/dev/null; sqlite3 $DB "DELETE FROM ssh_users WHERE username='$SELECTED_USER'"
         echo -e " ${LRD}[-] Account $SELECTED_USER removed.${NC}"; read -p " Press Enter..." ;;
      5) clear; echo -e "${DGN}┌─ ${DWH}OPENVPN DOWNLOAD URL ${DGN}──────────────────────────────────┐${NC}"
         echo -e "  ${WHT}http://$DOM:81/client.ovpn${NC}"
         echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"; read -p " Press Enter..." ;;
      0) return ;;
    esac
  done
}

openvpn_menu
