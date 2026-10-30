#!/bin/bash
echo "=== 1. STARTING DROPBEAR & SSH ==="
systemctl unmask dropbear 2>/dev/null
systemctl restart dropbear 2>/dev/null
systemctl restart ssh 2>/dev/null
systemctl restart sshd 2>/dev/null

echo "=== 2. CHECKING LISTENERS ==="
ss -tulpn | grep -E ':22\b|:443\b'

echo "=== 3. RESTARTING MULTIPLEXER STACK ==="
systemctl restart sslh
systemctl restart nginx
echo "=== DONE! ==="
