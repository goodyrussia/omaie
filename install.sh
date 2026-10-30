#!/bin/bash
cd /root/omaie
source ./menu/dashboard.sh
while true;
do
  show_dashboard
  read -r -p "Select option [00-12]: " c
  c=$(echo "$c" | tr -d "\r" | tr -d " ")
  case "$c" in
    1|01) bash ./protocols/ssh.sh ;;
    2|02) bash ./protocols/openvpn.sh ;;
    3|03) bash ./protocols/vless.sh ;;
    4|04) bash ./protocols/vmess.sh ;;
    5|05) bash ./protocols/trojan.sh ;;
    6|06) bash ./protocols/shadowsocks.sh ;;
    7|07) bash ./protocols/wireguard.sh ;;
    8|08) bash ./menu/ssl_manager.sh ;;
    9|09) bash ./menu/port_manager.sh ;;
    10) bash ./menu/monitor.sh ;;
    11) reboot ;;
    12) bash ./menu/uninstall.sh ;;
    0|00) exit 0 ;;
    *) echo -e "\n[!] Invalid option: '$c'"; sleep 1 ;;
  esac
done
