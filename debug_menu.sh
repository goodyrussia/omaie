#!/bin/bash
cd /root/omaie
echo "=== 1. FILE EXISTENCE & PERMISSIONS CHECK ==="
for script in protocols/ssh.sh protocols/openvpn.sh protocols/vless.sh protocols/vmess.sh protocols/trojan.sh protocols/shadowsocks.sh protocols/wireguard.sh menu/ssl_manager.sh menu/port_manager.sh menu/monitor.sh menu/uninstall.sh; do
    if [ -f "$script" ]; then
        perm=$(ls -l "$script" | awk '{print $1}')
        echo "  [OK] $script exists (Perms: $perm)"
    else
        echo "  [MISSING] $script NOT FOUND"
    fi
done

echo -e "\n=== 2. INPUT CAPTURE & EXECUTION TRACE ==="
echo "Starting menu in debug mode. Type an option (e.g., 1) and press Enter. Press Ctrl+C to exit."
sleep 2

# Run the menu wrapper with bash tracing enabled
bash -x /usr/local/bin/menu
