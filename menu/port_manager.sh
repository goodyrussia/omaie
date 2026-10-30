#!/bin/bash
DGN='\033[0;32m'; WHT='\033[1;37m'; RED='\033[1;31m'; NC='\033[0m'

change_port() {
    local service=$1; local file=$2; local search=$3; local replace=$4; local restart=$5
    read -p " Enter New Port for $service: " np
    if ! [[ "$np" =~ ^[0-9]+$ ]] || [ "$np" -gt 65535 ]; then 
        echo -e " ${RED}[!] Invalid Port Number.${NC}"; read -p " Press Enter..."; return
    fi
    if netstat -tuln | grep -q ":$np "; then 
        echo -e " ${RED}[!] CONFLICT: Port $np is already in use by another service!${NC}"
        read -p " Press Enter..."; return
    fi
    
    # Apply to file (suppressing errors if file location varies slightly)
    sed -i "s/$search/$replace$np/g" $file 2>/dev/null
    eval "$restart" 2>/dev/null
    echo -e " ${DGN}[+] $service port successfully changed to $np.${NC}"
    read -p " Press Enter..."
}

port_menu() {
  while true; do
    clear
    # Fetch live ports directly from configuration files
    P_DROP=$(grep -oP "(?<=DROPBEAR_PORT=)[0-9]+" /etc/default/dropbear 2>/dev/null || echo "109")
    P_UDP=$(grep -o "127.0.0.1:[0-9]*" /etc/systemd/system/badvpn.service 2>/dev/null | cut -d':' -f2 || echo "udp-custom")
    P_STUN=$(grep -oP "(?<=accept = )[0-9]+" /etc/stunnel/stunnel.conf 2>/dev/null || echo "444")
    P_WG=$(grep -oP "(?<=ListenPort = )[0-9]+" /etc/wireguard/wg0.conf 2>/dev/null || echo "51820")
    P_SQUID=$(grep -oP "(?<=http_port )[0-9]+" /etc/squid/squid.conf 2>/dev/null | head -n1 || echo "8080")
    P_OVPN=$(grep -oP "(?<=port )[0-9]+" /etc/openvpn/server/server.conf 2>/dev/null || grep -oP "(?<=port )[0-9]+" /etc/openvpn/server.conf 2>/dev/null || echo "1194")
    P_DNSTT=$(grep -oP "(?<=-udp :)[0-9]+" /etc/systemd/system/client-dnstt.service 2>/dev/null || echo "53")
    P_HAP=$(grep -oP "(?<=bind \*:)[0-9]+" /etc/haproxy/haproxy.cfg 2>/dev/null | grep -v "80" | head -n1 || echo "443")
    P_SS=$(grep -oP "(?<=\"port\": )[0-9]+" /usr/local/etc/xray/config.json 2>/dev/null | tail -n1 || echo "10005")

    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${WHT}           SYSTEM PORT & PROTOCOL DASHBOARD             ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}■${NC} ${WHT}Dropbear SSH        ${DGN}:${NC} ${WHT}$P_DROP${NC}"
    echo -e "  ${RED}■${NC} ${WHT}Stunnel4 (SSL)      ${DGN}:${NC} ${WHT}$P_STUN${NC}"
    echo -e "  ${RED}■${NC} ${WHT}UDP Custom (UDPGW)  ${DGN}:${NC} ${WHT}$P_UDP${NC}"
    echo -e "  ${RED}■${NC} ${WHT}WireGuard           ${DGN}:${NC} ${WHT}$P_WG${NC}"
    echo -e "  ${RED}■${NC} ${WHT}Squid Proxy         ${DGN}:${NC} ${WHT}$P_SQUID${NC}"
    echo -e "  ${RED}■${NC} ${WHT}OpenVPN             ${DGN}:${NC} ${WHT}$P_OVPN${NC}"
    echo -e "  ${RED}■${NC} ${WHT}SlowDNS (DNSTT)     ${DGN}:${NC} ${WHT}$P_DNSTT${NC}"
    echo -e "  ${RED}■${NC} ${WHT}Shadowsocks (SS)    ${DGN}:${NC} ${WHT}$P_SS${NC}"
    echo -e "  ${RED}■${NC} ${WHT}Xray VLESS          ${DGN}:${NC} ${WHT}$P_HAP (Multiplexed by HAProxy)${NC}"
    echo -e "  ${RED}■${NC} ${WHT}Xray VMess          ${DGN}:${NC} ${WHT}$P_HAP (Multiplexed by HAProxy)${NC}"
    echo -e "  ${RED}■${NC} ${WHT}Xray Trojan         ${DGN}:${NC} ${WHT}$P_HAP (Multiplexed by HAProxy)${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}[1]${NC} ${WHT}Change Dropbear Port${NC}"
    echo -e "  ${RED}[2]${NC} ${WHT}Change Stunnel4 Port${NC}"
    echo -e "  ${RED}[3]${NC} ${WHT}Change UDP Custom (Gateway) Port${NC}"
    echo -e "  ${RED}[4]${NC} ${WHT}Change WireGuard Port${NC}"
    echo -e "  ${RED}[5]${NC} ${WHT}Change Squid Proxy Port${NC}"
    echo -e "  ${RED}[6]${NC} ${WHT}Change OpenVPN Port${NC}"
    echo -e "  ${RED}[7]${NC} ${WHT}Change SlowDNS (DNSTT) Port${NC}"
    echo -e "  ${RED}[8]${NC} ${WHT}Change Shadowsocks Port${NC}"
    echo -e "  ${RED}[9]${NC} ${WHT}Change HAProxy (Xray Multiplexer) Port${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${RED}[0]${NC} ${WHT}Back to Main Menu${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select option: " opt
    
    case $opt in
      1) change_port "Dropbear" "/etc/default/dropbear" "DROPBEAR_PORT=[0-9]*" "DROPBEAR_PORT=" "systemctl restart dropbear" ;;
      2) change_port "Stunnel4" "/etc/stunnel/stunnel.conf" "accept = [0-9]*" "accept = " "systemctl restart stunnel4" ;;
      3) change_port "UDP Custom" "/etc/systemd/system/badvpn.service" "127.0.0.1:[0-9]*" "127.0.0.1:" "systemctl daemon-reload; systemctl restart badvpn" ;;
      4) change_port "WireGuard" "/etc/wireguard/wg0.conf" "ListenPort = [0-9]*" "ListenPort = " "systemctl restart wg-quick@wg0" ;;
      5) change_port "Squid" "/etc/squid/squid.conf" "http_port [0-9]*" "http_port " "systemctl restart squid" ;;
      6) change_port "OpenVPN" "/etc/openvpn/server/server.conf /etc/openvpn/server.conf" "port [0-9]*" "port " "systemctl restart openvpn-server@server 2>/dev/null || systemctl restart openvpn" ;;
      7) change_port "SlowDNS" "/etc/systemd/system/client-dnstt.service" "-udp :[0-9]*" "-udp :" "systemctl daemon-reload; systemctl restart client-dnstt" ;;
      8) change_port "Shadowsocks" "/usr/local/etc/xray/config.json" "\"port\": [0-9]*" "\"port\": " "systemctl restart xray" ;;
      9) change_port "HAProxy (Xray)" "/etc/haproxy/haproxy.cfg" "bind \*:[0-9]*" "bind \*:" "systemctl restart haproxy" ;;
      0) return ;;
    esac
  done
}

port_menu
