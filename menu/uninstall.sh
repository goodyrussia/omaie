#!/bin/bash
DGN='\033[0;32m'; WHT='\033[1;37m'; RED='\033[1;31m'; NC='\033[0m'
uninstall_menu() {
  clear
  echo -e "${RED}┌─────────────────────────────────────────────────────────┐${NC}"
  echo -e "${RED}│ ${WHT}            DANGER: SYSTEM UNINSTALLATION               ${RED}│${NC}"
  echo -e "${RED}├─────────────────────────────────────────────────────────┤${NC}"
  echo -e "  ${WHT}This action will completely remove SmartKing4Luv v2,"
  echo -e "  delete all accounts, and purge VPN dependencies."
  echo -e "${RED}└─────────────────────────────────────────────────────────┘${NC}"
  read -p " Are you absolutely sure? (y/n): " c
  if [ "$c" == "y" ]; then
    systemctl stop haproxy nginx stunnel4 dropbear squid openvpn xray badvpn client-dnstt wg-quick@wg0 2>/dev/null
    apt-get purge -y haproxy nginx stunnel4 dropbear squid openvpn wireguard sqlite3 2>/dev/null
    rm -rf /etc/smartking4luv /etc/xray /etc/wireguard /etc/squid /etc/haproxy /usr/local/bin/menu /var/www/html/client.ovpn
    echo -e " ${DGN}[+] Uninstallation Complete. Goodbye.${NC}"; exit 0
  fi
}

uninstall_menu
