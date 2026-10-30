#!/bin/bash
echo "=== 1. LOCATING DASHBOARD FILES ==="
# Find all menu files in the common binary directories
MENU_FILES=$(grep -rl "UDP Custom" /usr/bin/ /usr/local/bin/ /root/ 2>/dev/null)

if [ -z "$MENU_FILES" ]; then
    echo "  [ERROR] Could not locate the SMARTKING menu script."
    exit 1
fi

for file in $MENU_FILES; do
    echo "  [INFO] Patching dashboard text in: $file"
    
    # 1. Update the UI text to remove 1-65535, 53, 5300 and display the dynamic ports
    sed -i -E 's/UDP Custom([[:space:]]*): 1-65535, 53, 5300/UDP Custom\1: 1-65535, 53, 5300/g' "$file"
    
    # 2. Fix the Offline/Running detection logic.
    # We replace the hardcoded port 1-65535, 53, 5300 check with a check for the udp-custom process
    sed -i 's/grep -w "udp-custom"/grep -w "udp-custom"/g' "$file"
    sed -i 's/grep -w udp-custom/grep -w udp-custom/g' "$file"
    sed -i 's/"udp-custom"/"udp-custom"/g' "$file"
done

echo "=== 2. ENSURING REAL UDP CUSTOM IS ACTIVE ==="
systemctl daemon-reload
systemctl restart udp-custom

echo "=== DONE! ==="
