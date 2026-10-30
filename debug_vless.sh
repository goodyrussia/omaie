#!/bin/bash
echo "=== 1. CHECKING XRAY SERVICE STATUS ==="
systemctl status xray --no-pager | head -n 10

echo -e "\n=== 2. CHECKING RECENT XRAY ERROR LOGS ==="
journalctl -u xray -n 30 --no-pager

echo -e "\n=== 3. CHECKING IF UUID IS REGISTERED IN XRAY CONFIG ==="
if grep -rn "a2730389-540d-48a3-8a7d-cd33ade0d537" /etc/xray/ 2>/dev/null; then
    echo "  [OK] UUID found in Xray configuration."
else
    echo "  [ERROR] UUID 'a2730389-540d-48a3-8a7d-cd33ade0d537' NOT found in /etc/xray/!"
fi

echo -e "\n=== 4. CHECKING NGINX WEBSOCKET PATH (/xray) ==="
if grep -rn "/xray" /etc/nginx/ 2>/dev/null; then
    echo "  [OK] Path /xray found in Nginx configuration."
else
    echo "  [WARNING] Path /xray not found in /etc/nginx/. WebSocket proxying might be missing."
fi
