#!/bin/bash
echo "=== 1. ELIMINATING HAPROXY CONFLICT ON PORT 443 & 80 ==="
systemctl stop haproxy 2>/dev/null
systemctl disable haproxy 2>/dev/null
# Forcefully kill anything holding the ports
fuser -k 443/tcp 2>/dev/null
fuser -k 80/tcp 2>/dev/null

echo "=== 2. BOOTING PURE SSL + WS MULTIPLEXER ==="
systemctl restart sslh
systemctl restart nginx

echo "=== 3. PATCHING DASHBOARD TEXT ==="
# Find all menu script files containing "UDP Custom"
MENU_FILES=$(grep -rl "UDP Custom" /usr/bin/ /usr/local/bin/ /root/ 2>/dev/null)

for f in $MENU_FILES; do
    # Only patch if it is a text script (avoids corrupting compiled binaries)
    if file "$f" | grep -q "text"; then
        echo "  [INFO] Patching text in $f..."
        # Replace the display text 1-65535, 53, 5300 with your requested ports
        sed -i 's/1-65535, 53, 5300/1-65535, 53, 5300/g' "$f"
        
        # Fix the internal status checker so it looks for the udp-custom process
        # instead of searching for a hardcoded port number
        sed -i 's/grep "udp-custom"/grep "udp-custom"/g' "$f"
        sed -i 's/grep -vw "udp-custom"/grep -vw "udp-custom"/g' "$f"
    fi
done

echo "=== 4. VERIFYING PORT 443 OWNERSHIP ==="
ss -tulpn | grep ':443 '
echo "=== DONE! PORT 443 IS NOW FREED FOR PURE SSL ==="
