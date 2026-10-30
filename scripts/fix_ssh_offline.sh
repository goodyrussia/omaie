#!/bin/bash
echo "=== 1. RESTARTING SSH SERVICES ==="
systemctl restart ssh 2>/dev/null
systemctl restart sshd 2>/dev/null
systemctl restart dropbear 2>/dev/null

echo "=== 2. VERIFYING PORT 22 LISTENER ==="
PORT_22_LISTENER=$(ss -tulpn | grep -w ':22')

if [ -z "$PORT_22_LISTENER" ]; then
    echo "  [ERROR] Nothing is listening on port 22! Check your SSH config."
else
    echo "  [SUCCESS] SSH is actively listening on port 22:"
    echo "  $PORT_22_LISTENER"
fi

echo "=== 3. RESTARTING MULTIPLEXER ==="
systemctl restart sslh
systemctl restart nginx
echo "  [OK] Server is ready!"
