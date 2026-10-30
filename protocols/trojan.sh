#!/bin/bash
DGN='\033[0;32m'; WHT='\033[1;37m'; RED='\033[1;31m'; NC='\033[0m'
DB="/etc/smartking4luv/database.sqlite"; # Dynamic DOM

print_trojan() {
    local DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)
    local u=$1; local id=$2; local e=$3
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${WHT}            TROJAN ACCOUNT PROVISIONED                ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}Username : ${WHT}$u"
    echo -e "  ${RED}UUID     : ${WHT}$id"
    echo -e "  ${RED}Expiry   : ${WHT}$e"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}[TLS / Port 443]${NC}"
    echo -e "  ${WHT}trojan://$id@$DOM:443?path=/trojan&security=tls&type=ws#$u${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Press Enter to return..."
}

select_trojan_user() {
    users=($(sqlite3 "$DB" "SELECT username FROM xray_users WHERE protocol='trojan';"))
    if [ ${#users[@]} -eq 0 ]; then echo -e " ${RED}[!] No TROJAN users found.${NC}"; return 1; fi
    echo -e "${DGN}┌─ REGISTERED TROJAN ACCOUNTS ─────────────────────────────┐${NC}"
    local i=1
    for u in "${users[@]}"; do
        exp=$(sqlite3 "$DB" "SELECT expiry FROM xray_users WHERE username='$u';")
        printf " ${DGN}│${NC} ${RED}[%02d]${NC} ${WHT}%-16s${NC} Exp: ${DGN}%-10s${NC}\n" "$i" "$u" "$exp"
        ((i++))
    done
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Enter choice [Number or Username]: " target
    if [[ "$target" =~ ^[0-9]+$ ]] && [ "$target" -ge 1 ] && [ "$target" -le ${#users[@]} ]; then SELECTED_USER="${users[$((target-1))]}"; else SELECTED_USER="$target"; fi
}

trojan_menu() {
  while true; do
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${WHT}               XRAY TROJAN MANAGER                     ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}[1]${NC} ${WHT}Create TROJAN Account${NC}"
    echo -e "  ${RED}[2]${NC} ${WHT}Create Trial TROJAN Account (24H)${NC}"
    echo -e "  ${RED}[3]${NC} ${WHT}Renew / Extend Account${NC}"
    echo -e "  ${RED}[4]${NC} ${WHT}Delete Account${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}[0]${NC} ${WHT}Back to Main Menu${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select an option: " opt
    case $opt in
      1) clear; read -p " Username: " u; read -p " Duration (Days): " d; id=$(uuidgen); e=$(date -d "+$d days" +"%Y-%m-%d")
         sqlite3 $DB "INSERT INTO xray_users VALUES ('$u','$id','trojan','$e');"
         print_trojan "$u" "$id" "$e" ;;
      2) clear; u="trojan_trial_$((RANDOM % 899 + 100))"; id=$(uuidgen); e=$(date -d "+1 day" +"%Y-%m-%d")
         sqlite3 $DB "INSERT INTO xray_users VALUES ('$u','$id','trojan','$e');"
         print_trojan "$u" "$id" "$e" ;;
      3) clear; select_trojan_user || { read -p " Press Enter..."; continue; }
         read -p " Add Days: " d; e=$(date -d "+$d days" +"%Y-%m-%d")
         sqlite3 $DB "UPDATE xray_users SET expiry='$e' WHERE username='$SELECTED_USER';"
         echo -e " ${DGN}[+] Account $SELECTED_USER renewed to $e${NC}"; read -p " Press Enter..." ;;
      4) clear; select_trojan_user || { read -p " Press Enter..."; continue; }
         sqlite3 $DB "DELETE FROM xray_users WHERE username='$SELECTED_USER';"
         echo -e " ${RED}[-] Account $SELECTED_USER removed.${NC}"; read -p " Press Enter..." ;;
      0) return ;;
    esac
  done
}

trojan_menu
