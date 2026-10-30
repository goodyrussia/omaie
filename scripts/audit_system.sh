#!/bin/bash
cd /root/omaie || exit 1

echo "=== 1. CHECKING MENU TARGET PATHS & PERMISSIONS ==="
declare -A targets=(
    ["01 (SSH)"]="./protocols/ssh.sh"
    ["02 (OpenVPN)"]="./protocols/openvpn.sh"
    ["03 (VLESS)"]="./protocols/vless.sh"
    ["04 (VMESS)"]="./protocols/vmess.sh"
    ["05 (Trojan)"]="./protocols/trojan.sh"
    ["06 (Shadowsocks)"]="./protocols/shadowsocks.sh"
    ["07 (WireGuard)"]="./protocols/wireguard.sh"
    ["08 (SSL Manager)"]="./menu/ssl_manager.sh"
    ["09 (Port Manager)"]="./menu/port_manager.sh"
    ["10 (Monitor)"]="./menu/monitor.sh"
    ["12 (Uninstall)"]="./menu/uninstall.sh"
)

for label in "${!targets[@]}"; do
    path="${targets[$label]}"
    if [ -f "$path" ]; then
        if [ -x "$path" ]; then
            echo "  [OK] $label -> $path (Exists & Executable)"
        else
            echo "  [FIXING] $label -> $path (Missing execute permission, fixing...)"
            chmod +x "$path"
        fi
    else
        echo "  [MISSING] $label -> $path NOT FOUND ON DISK"
    fi
done

echo -e "\n=== 2. CHECKING SCRIPT SYNTAX INTEGRITY ==="
for path in "${targets[@]}"; do
    if [ -f "$path" ]; then
        if bash -n "$path" 2>/dev/null; then
            echo "  [SYNTAX OK] $path"
        else
            echo "  [SYNTAX ERROR] $path contains syntax errors:"
            bash -n "$path"
        fi
    fi
done

echo -e "\n=== 3. INSPECTING /usr/local/bin/menu WRAPPER ==="
if [ -f /usr/local/bin/menu ]; then
    echo "Wrapper exists. First 15 lines:"
    head -n 15 /usr/local/bin/menu
else
    echo "  [ERROR] /usr/local/bin/menu does not exist!"
fi
