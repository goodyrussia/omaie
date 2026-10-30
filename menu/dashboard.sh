#!/bin/bash
DGN='\033[0;32m'; LBL='\033[1;36m'; DWH='\033[0;37m'; LRD='\033[1;31m'; NC='\033[0m'
get_status() { systemctl is-active --quiet $1 && echo -e "${DGN}[Running]${NC}" || echo -e "${LRD}[Offline]${NC}"; }

show_dashboard() {
    clear
    UP=$(uptime -p | cut -d " " -f 2-)
    RAM_P=$(free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100) }')
    RAM_U=$(free -m | awk '/Mem:/ { print $3 }')
    RAM_T=$(free -m | awk '/Mem:/ { print $2 }')
    DOM=$(cat /etc/smartking4luv/domain 2>/dev/null || echo "Not Set")
    IP=$(curl -sS ipv4.icanhazip.com 2>/dev/null)
    LOAD=$(cat /proc/loadavg | awk '{print $1}')
    DISK=$(df -h / | awk '/\// {print $5 " of " $2}')

    echo -e "${DGN}System load:            ${LBL}$LOAD${NC}"
    echo -e "${DGN}Usage of /:             ${LBL}$DISK${NC}"
    echo -e "${DGN}Memory usage:           ${LBL}$RAM_P${NC}"
    echo -e "${DGN}* Management:           ${DWH}SMARTKING4LUV v2 PRO${NC}"
    echo -e "${DGN}* Support:              ${LBL}https://github.com/albertlanc${NC}\n"

    echo -e "${DGN}┌─ ${DWH}SMARTKING4LUV V2 PRO (ELITE) ${DGN}──────────────────────────┐${NC}"
    echo -e "${DGN}│ ${LRD}Host : ${DWH}$HOSTNAME ${LBL}($IP) ${NC}"
    echo -e "${DGN}│ ${LRD}Up   : ${DWH}$UP ${NC}"
    echo -e "${DGN}│ ${LRD}RAM  : ${DWH}[##--------] $RAM_P ${LBL}(${RAM_U}MB/${RAM_T}MB) ${NC}"
    echo -e "${DGN}│ ${LRD}SVC  : ${DWH}Xray:$(get_status xray) SSH:$(get_status stunnel4) WG:$(get_status wg-quick@wg0)${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}\n"

    echo -e "${DGN}┌─ ${DWH}PROTOCOL MANAGEMENT ${DGN}───────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${LRD}[01]${LBL} SSH, SSHWS & UDP Custom Manager                    ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[02]${LBL} OpenVPN Manager                                    ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[03]${LBL} Xray VLESS Manager                                 ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[04]${LBL} Xray VMESS Manager                                 ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[05]${LBL} Xray Trojan Manager                                ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[06]${LBL} Shadowsocks Manager                                ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[07]${LBL} WireGuard Manager                                  ${DGN}│${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}\n"

    echo -e "${DGN}┌─ ${DWH}SERVER & AUTOMATION ${DGN}───────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${LRD}[08]${LBL} SSL/TLS & Domain Manager                           ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[09]${LBL} Service & Port Manager                             ${DGN}│${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}\n"

    echo -e "${DGN}┌─ ${DWH}DIAGNOSTICS & TOOLS ${DGN}───────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${LRD}[10]${LBL} Monitoring & Tools                                 ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[11]${LBL} Reboot System                                      ${DGN}│${NC}"
    echo -e "${DGN}│ ${LRD}[12]${LBL} Uninstall System                                   ${DGN}│${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}\n"

    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${LRD}[00]${LBL} Exit Dashboard                                     ${DGN}│${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
}
