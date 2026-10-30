#!/bin/bash
CONFIG_DIR="/etc/smartking4luv"
mkdir -p "$CONFIG_DIR"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

check_license() {
    clear; echo -e "${CYAN}=== SMARTKING4LUV v2 INITIALIZATION ===${NC}"
    IP=$(curl -sS ipv4.icanhazip.com)
    TOKEN="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"
    if ! curl -sS -H "Authorization: token $TOKEN" "https://raw.githubusercontent.com/albertlanc/omaie/main/ips.txt?t=$(date +%s)" | grep -q "$IP"; then
        echo -e "${RED}[!] IP $IP is not authorized in ips.txt! Access Denied.${NC}"; exit 1
    fi

    # FIX: Prompt for Domain FIRST before compiling backend
    if [ ! -f "$CONFIG_DIR/domain" ]; then
        read -p "Enter Domain Name (e.g., vpn.com): " DOMAIN
        read -p "Enter Name Server for SlowDNS: " NS
        echo "$DOMAIN" > "$CONFIG_DIR/domain"
        echo "$NS" > "$CONFIG_DIR/ns"
    fi

    if [ ! -f "$CONFIG_DIR/installed" ]; then
        echo -e "${YELLOW}[*] Compiling Backend Muscle & Dependencies...${NC}"
        source modules/setup.sh
        install_core_deps
        install_backend_engines
        touch "$CONFIG_DIR/installed"
    fi
}
