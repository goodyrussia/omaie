#!/bin/bash
DGN='\033[0;32m'; LBL='\033[1;36m'; DWH='\033[0;37m'; LRD='\033[1;31m'; WHT='\033[1;37m'; NC='\033[0m'
DB="/etc/smartking4luv/database.sqlite"; DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)

select_ss_user() {
    users=($(sqlite3 "$DB" "SELECT username FROM xray_users WHERE protocol='ss';"))
    if [ ${#users[@]} -eq 0 ]; then echo -e " ${LRD}[!] No Shadowsocks users found.${NC}"; return 1; fi
    echo -e "${DGN}┌─ ${DWH}REGISTERED SHADOWSOCKS ACCOUNTS ${DGN}───────────────────────┐${NC}"
    local i=1
    for u in "${users[@]}"; do
        exp=$(sqlite3 "$DB" "SELECT expiry FROM xray_users WHERE username='$u';")
        printf " ${DGN}│${NC} ${LRD}[%02d]${NC} ${WHT}%-16s${NC} Exp: ${LBL}%-10s${NC}\n" "$i" "$u" "$exp"
        ((i++))
    done
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Enter choice [Number or Username]: " target
    if [[ "$target" =~ ^[0-9]+$ ]] && [ "$target" -ge 1 ] && [ "$target" -le ${#users[@]} ]; then SELECTED_USER="${users[$((target-1))]}"; else SELECTED_USER="$target"; fi
}

ss_menu() {
  local DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)
  while true; do
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${DWH}             SHADOWSOCKS PROTOCOL MANAGER               ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[1]${NC} ${DWH}Create Shadowsocks User${NC}"
    echo -e "  ${LRD}[2]${NC} ${DWH}Renew / Extend Shadowsocks User${NC}"
    echo -e "  ${LRD}[3]${NC} ${DWH}Delete Shadowsocks User${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[0]${NC} ${DWH}Back to Main Menu${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select option: " opt
    case $opt in
      1) clear; echo -e "${DGN}┌─ ${DWH}CREATE SHADOWSOCKS ACCOUNT ${DGN}────────────────────────────┐${NC}"
         read -p " Username: " u; read -p " Days: " d; id=$(uuidgen); e=$(date -d "+$d days" +"%Y-%m-%d")
         sqlite3 $DB "INSERT INTO xray_users VALUES ('$u','$id','ss','$e');"
         echo -e " ${DGN}[+] SS Account Created!${NC}\n ${LRD}Link:${NC} ${WHT}ss://$(echo -n "aes-128-gcm:$id" | base64 -w 0)@$DOM:10005#$u${NC}"
         echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"; read -p " Press Enter..." ;;
      2) clear; echo -e "${DGN}┌─ ${DWH}RENEW SHADOWSOCKS ACCOUNT ${DGN}─────────────────────────────┐${NC}"
         select_ss_user || { read -p " Press Enter..."; continue; }
         read -p " Add Days: " d; e=$(date -d "+$d days" +"%Y-%m-%d")
         sqlite3 $DB "UPDATE xray_users SET expiry='$e' WHERE username='$SELECTED_USER';"
         echo -e " ${DGN}[+] Account $SELECTED_USER renewed to $e${NC}"; read -p " Press Enter..." ;;
      3) clear; echo -e "${DGN}┌─ ${DWH}DELETE SHADOWSOCKS ACCOUNT ${DGN}────────────────────────────┐${NC}"
         select_ss_user || { read -p " Press Enter..."; continue; }
         sqlite3 $DB "DELETE FROM xray_users WHERE username='$SELECTED_USER'"
         echo -e " ${LRD}[-] Account $SELECTED_USER removed.${NC}"; read -p " Press Enter..." ;;
      0) return ;;
    esac
  done
}

ss_menu
