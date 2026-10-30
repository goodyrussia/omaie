#!/bin/bash
DGN='\033[0;32m'; LBL='\033[1;36m'; DWH='\033[0;37m'; LRD='\033[1;31m'; NC='\033[0m'

show_services() {
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${DWH}                 RUNNING SERVICES                       ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    
    check_svc() {
        local name=$1; local svc=$2; local port=$3
        if systemctl is-active --quiet $svc; then
            printf "  ${LRD}■${NC} ${DWH}%-20s${NC} ${DGN}:${NC} ${LBL}%-8s${NC} [${DGN}Running${NC}]\n" "$name" "$port"
        else
            printf "  ${LRD}■${NC} ${DWH}%-20s${NC} ${DGN}:${NC} ${LBL}%-8s${NC} [${LRD}Offline${NC}]\n" "$name" "$port"
        fi
    }

    P_DROP=$(grep -oP "(?<=DROPBEAR_PORT=)[0-9]+" /etc/default/dropbear 2>/dev/null || echo "109")
    P_UDP=$(grep -o "127.0.0.1:[0-9]*" /etc/systemd/system/badvpn.service 2>/dev/null | cut -d':' -f2 || echo "udp-custom")
    P_STUN=$(grep -oP "(?<=accept = )[0-9]+" /etc/stunnel/stunnel.conf 2>/dev/null || echo "444")
    P_WG=$(grep -oP "(?<=ListenPort = )[0-9]+" /etc/wireguard/wg0.conf 2>/dev/null || echo "51820")
    P_SQUID=$(grep -oP "(?<=http_port )[0-9]+" /etc/squid/squid.conf 2>/dev/null | head -n1 || echo "8080")
    P_OVPN=$(grep -oP "(?<=port )[0-9]+" /etc/openvpn/server/server.conf 2>/dev/null || echo "1194")
    P_DNSTT=$(grep -oP "(?<=-udp :)[0-9]+" /etc/systemd/system/dnstt-server.service 2>/dev/null || echo "53")
    P_HAP=$(grep -oP "(?<=bind \*:)[0-9]+" /etc/haproxy/haproxy.cfg 2>/dev/null | grep -v "80" | head -n1 || echo "443")
    
    check_svc "OpenSSH" "sshd" "22"
    check_svc "Dropbear SSH" "dropbear" "$P_DROP"
    check_svc "Stunnel4 (SSL)" "stunnel4" "$P_STUN"
    check_svc "Squid Proxy" "squid" "$P_SQUID"
    check_svc "UDP Custom" "badvpn" "$P_UDP"
    check_svc "SlowDNS (DNSTT)" "dnstt" "$P_DNSTT"
    P_HAP=$(ss -tulpn 2>/dev/null | grep -w "haproxy" | awk '{print $5}' | rev | cut -d: -f1 | rev | sort -nu | paste -sd, -)
    [ -z "$P_HAP" ] && P_HAP="80, 443"
    check_svc "HAProxy (Mux)" "haproxy" "$P_HAP"
    check_svc "WireGuard" "wg-quick@wg0" "$P_WG"
    check_svc "OpenVPN" "openvpn" "$P_OVPN"
    P_XRAY=$(ss -tulpn 2>/dev/null | grep -w "xray" | awk '{print $5}' | rev | cut -d: -f1 | rev | sort -nu | head -n 3 | paste -sd, -)
    [ -z "$P_XRAY" ] && P_XRAY="443, 80"
    check_svc "Xray Core" "xray" "$P_XRAY"
    
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Press Enter to return..."
}

show_data_stats() {
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${DWH}               DATA USAGE STATISTICS                    ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    
    IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    if ! vnstat -i $IFACE >/dev/null 2>&1; then
        echo -e "  ${LRD}[!] Data tracking is currently initializing.${NC}"
        echo -e "  ${DWH}Please wait a few minutes for vnStat to collect data.${NC}"
    else
        YESTER_DATE=$(date -d yesterday +'%Y-%m-%d')
        TODAY=$(vnstat -i $IFACE -d | grep "today" | awk '{print $8, $9}')
        YESTERDAY=$(vnstat -i $IFACE -d | grep "$YESTER_DATE" | awk '{print $8, $9}')
        WEEK=$(vnstat -i $IFACE -w | grep "current week" | awk '{print $9, $10}')
        MONTH=$(vnstat -i $IFACE -m | grep "$(date +'%Y-%m')" | awk '{print $8, $9}')
        
        [ -z "$TODAY" ] && TODAY="0.00 MB"
        [ -z "$YESTERDAY" ] && YESTERDAY="Not enough data"
        [ -z "$WEEK" ] && WEEK="0.00 MB"
        [ -z "$MONTH" ] && MONTH="0.00 MB"
        
        echo -e "  ${LRD}■${NC} ${DWH}Data Used Today     ${DGN}:${NC} ${LBL}${TODAY}${NC}"
        echo -e "  ${LRD}■${NC} ${DWH}Data Used Yesterday ${DGN}:${NC} ${LBL}${YESTERDAY}${NC}"
        echo -e "  ${LRD}■${NC} ${DWH}Data Used This Week ${DGN}:${NC} ${LBL}${WEEK}${NC}"
        echo -e "  ${LRD}■${NC} ${DWH}Data Used This Month${DGN}:${NC} ${LBL}${MONTH}${NC}"
    fi
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Press Enter to return..."
}

show_live_diag() {
    clear
    CPU=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
    RAM=$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)", $3,$2,$3*100/$2 }')
    DISK=$(df -h / | awk '$NF=="/"{printf "%s/%s (%s)", $3,$2,$5}')
    UPTIME=$(uptime -p | cut -d " " -f 2-)
    
    SSH_CON=$(netstat -tnpa 2>/dev/null | grep -E 'sshd|dropbear' | grep ESTABLISHED | wc -l)
    XRAY_CON=$(netstat -tnpa 2>/dev/null | grep xray | grep ESTABLISHED | wc -l)
    OVPN_CON=$(netstat -tnpa 2>/dev/null | grep openvpn | grep ESTABLISHED | wc -l)

    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${DWH}             LIVE SYSTEM DIAGNOSTICS                    ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}■${NC} ${DWH}CPU Load       ${DGN}:${NC} ${LBL}$CPU${NC}"
    echo -e "  ${LRD}■${NC} ${DWH}Memory Usage   ${DGN}:${NC} ${LBL}$RAM${NC}"
    echo -e "  ${LRD}■${NC} ${DWH}Disk Usage     ${DGN}:${NC} ${LBL}$DISK${NC}"
    echo -e "  ${LRD}■${NC} ${DWH}System Uptime  ${DGN}:${NC} ${LBL}$UPTIME${NC}"
    echo -e "${DGN}├─ ACTIVE CONNECTIONS ────────────────────────────────────┤${NC}"
    echo -e "  ${DWH}SSH / Dropbear : ${LBL}$SSH_CON${NC}"
    echo -e "  ${DWH}Xray (All)     : ${LBL}$XRAY_CON${NC}"
    echo -e "  ${DWH}OpenVPN        : ${LBL}$OVPN_CON${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Press Enter to return..."
}

monitor_menu() {
  while true; do
    clear
    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${DWH}           SYSTEM MONITORING & DIAGNOSTICS              ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[1]${NC} ${DWH}Live System Diagnostics${NC}"
    echo -e "  ${LRD}[2]${NC} ${DWH}Running Services & Ports${NC}"
    echo -e "  ${LRD}[3]${NC} ${DWH}Data Usage Statistics (vnStat)${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[0]${NC} ${DWH}Back to Main Menu${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select option: " opt
    case $opt in
      1) show_live_diag ;;
      2) show_services ;;
      3) show_data_stats ;;
      0) return ;;
    esac
  done
}

monitor_menu
