#!/bin/bash
DGN='\033[0;32m'; WHT='\033[1;37m'; RED='\033[1;31m'; NC='\033[0m'
wg_menu() {
  while true; do
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${WHT}              WIREGUARD PROTOCOL MANAGER                ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}[1]${NC} ${WHT}Create WireGuard Client${NC}"
    echo -e "  ${RED}[2]${NC} ${WHT}View Active Clients${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}[0]${NC} ${WHT}Back to Main Menu${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select option: " opt
    case $opt in
      1) clear; read -p " Client Name: " u; ip="10.66.66.$(($RANDOM % 200 + 2))"; p=$(wg genkey); pub=$(echo "$p" | wg pubkey); dom=$(cat /etc/smartking4luv/domain)
         echo -e "\n[Peer]\nPublicKey = $pub\nAllowedIPs = $ip/32" >> /etc/wireguard/wg0.conf; systemctl restart wg-quick@wg0
         echo "$u | $ip" >> /etc/wireguard/clients.txt
         clear; echo -e "${DGN}┌─ WIREGUARD CLIENT CONFIG ───────────────────────────────┐${NC}"
         echo -e " ${WHT}[Interface]\n PrivateKey = $p\n Address = $ip/32\n DNS = 8.8.8.8\n\n [Peer]\n PublicKey = $(cat /etc/wireguard/publickey 2>/dev/null)\n Endpoint = $dom:51820\n AllowedIPs = 0.0.0.0/0${NC}"
         echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"; read -p " Press Enter..." ;;
      2) clear; echo -e "${DGN}┌─ ACTIVE WIREGUARD CLIENTS ──────────────────────────────┐${NC}"
         cat /etc/wireguard/clients.txt 2>/dev/null | column -t -s '|'
         echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"; read -p " Press Enter..." ;;
      0) return ;;
    esac
  done
}

wg_menu
