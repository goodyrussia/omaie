#!/bin/bash
DGN='\033[0;32m'; LBL='\033[1;36m'; DWH='\033[0;37m'; LRD='\033[1;31m'; WHT='\033[1;37m'; NC='\033[0m'

ssl_menu() {
  while true; do
    clear
    CUR_DOM=$(cat /etc/smartking4luv/domain 2>/dev/null || echo "Not Configured")
    CUR_NS=$(cat /etc/smartking4luv/ns 2>/dev/null || echo "Not Configured")

    echo -e "${DGN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DGN}│ ${DWH}                DOMAIN & SSL MANAGER                    ${DGN}│${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}■${NC} ${DWH}Current Domain : ${LBL}$CUR_DOM${NC}"
    echo -e "  ${LRD}■${NC} ${DWH}Current NS     : ${LBL}$CUR_NS${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[1]${NC} ${DWH}Change Domain & NS (Full Auto-SSL & Sync)${NC}"
    echo -e "  ${LRD}[2]${NC} ${DWH}Force Renew Existing SSL Certificate${NC}"
    echo -e "${DGN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${LRD}[0]${NC} ${DWH}Back to Main Menu${NC}"
    echo -e "${DGN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p " Select option: " opt

    case $opt in
      1) clear
         echo -e "${DGN}┌─ ${DWH}CHANGE DOMAIN & AUTO-PROVISION SSL ${DGN}────────────────────┐${NC}"
         read -p " Enter New Domain (e.g., vpn.site.com): " NEW_DOM
         read -p " Enter New SlowDNS NS (e.g., ns.site.com): " NEW_NS

         if [ -z "$NEW_DOM" ] || [ -z "$NEW_NS" ]; then
             echo -e " ${LRD}[!] Domain and Name Server cannot be empty.${NC}"
             read -p " Press Enter..."; continue
         fi

         # Update system records
         echo "$NEW_DOM" > /etc/smartking4luv/domain
         echo "$NEW_NS" > /etc/smartking4luv/ns

         echo -e "\n ${DGN}[*] Temporarily pausing Port 80 services for ACME validation...${NC}"
         systemctl stop haproxy nginx 2>/dev/null

         echo -e " ${DGN}[*] Requesting official SSL Certificate via Acme.sh...${NC}"
         if [ ! -f ~/.acme.sh/acme.sh ]; then
             curl -sS https://get.acme.sh | sh >/dev/null 2>&1
         fi
         ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1
         ~/.acme.sh/acme.sh --issue -d "$NEW_DOM" --standalone --force
         
         mkdir -p /etc/ssl
         ~/.acme.sh/acme.sh --installcert -d "$NEW_DOM" \
             --fullchainpath /etc/ssl/smartking.pem \
             --keypath /etc/ssl/smartking.key >/dev/null 2>&1

         # If ACME standalone failed (e.g., DNS propagation delay), apply self-signed fallback so services don't crash
         if [ ! -s /etc/ssl/smartking.pem ]; then
             echo -e " ${LRD}[!] ACME validation failed (check DNS pointing). Generating fallback TLS certificate...${NC}"
             openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
                 -subj "/CN=$NEW_DOM" -keyout /etc/ssl/smartking.key -out /etc/ssl/smartking.pem >/dev/null 2>&1
             cat /etc/ssl/smartking.key >> /etc/ssl/smartking.pem
         else
             # Append private key to PEM for Stunnel compatibility
             cat /etc/ssl/smartking.key >> /etc/ssl/smartking.pem
             echo -e " ${DGN}[+] Official SSL Certificate issued and configured.${NC}"
         fi

         # Restart frontend multiplexers
         systemctl start haproxy nginx stunnel4 2>/dev/null

         echo -e " ${DGN}[*] Updating SlowDNS service with new Domain and NS...${NC}"
         cat << DNSSRV > /etc/systemd/system/client-dnstt.service
[Unit]
Description=DNSTT Server
After=network.target
[Service]
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $NEW_DOM 127.0.0.1:22
Restart=always
[Install]
WantedBy=multi-user.target
DNSSRV
         systemctl daemon-reload
         systemctl restart client-dnstt 2>/dev/null

         echo -e " ${DGN}[*] Updating OpenVPN client download package...${NC}"
         cat << OVPNCLI > /var/www/html/client.ovpn
client
dev tun
proto tcp
remote $NEW_DOM 442
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3
<ca>
$(cat /etc/openvpn/ca.crt 2>/dev/null || cat /etc/ssl/smartking.pem 2>/dev/null)
</ca>
OVPNCLI

         echo -e "\n ${DGN}[+] Synchronization complete.${NC}"
         echo -e " ${DWH}All submenus, managers, and payloads are now using:${NC} ${LBL}$NEW_DOM${NC}"
         read -p " Press Enter..." ;;

      2) clear
         DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)
         echo -e " ${DGN}[*] Renewing SSL Certificate for $DOM...${NC}"
         systemctl stop haproxy nginx 2>/dev/null
         ~/.acme.sh/acme.sh --renew -d "$DOM" --force
         cat /etc/ssl/smartking.key >> /etc/ssl/smartking.pem
         systemctl start haproxy nginx stunnel4 2>/dev/null
         echo -e " ${DGN}[+] SSL Renewed and services restarted.${NC}"
         read -p " Press Enter..." ;;

      0) return ;;
    esac
  done
}

ssl_menu
