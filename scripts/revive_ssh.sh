#!/bin/bash
echo "=== 1. CLEARING UBUNTU 24.04 SOCKET CONFLICTS ==="
systemctl stop ssh.socket 2>/dev/null
systemctl disable ssh.socket 2>/dev/null
systemctl daemon-reload

echo "=== 2. FORCING OPENSSH TO PORT 22 ==="
# Ensure OpenSSH is explicitly told to listen on standard port
if [ -f /etc/ssh/sshd_config ]; then
    sed -i '/^#Port 22/c\Port 22' /etc/ssh/sshd_config
    grep -q "^Port 22" /etc/ssh/sshd_config || echo "Port 22" >> /etc/ssh/sshd_config
fi
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

echo "=== 3. RESTARTING DROPBEAR AS BACKUP (PORT 109) ==="
if [ -f /etc/default/dropbear ]; then
    sed -i 's/DROPBEAR_PORT=.*/DROPBEAR_PORT=109/' /etc/default/dropbear
    sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
fi
systemctl unmask dropbear 2>/dev/null
systemctl restart dropbear 2>/dev/null

echo "=== 4. VERIFYING ACTIVE SSH PORTS ==="
ss -tulpn | grep -iE 'sshd|dropbear'

echo "=== 5. RE-LINKING SSLH MULTIPLEXER ==="
# Find the first active SSH port that isn't 443 or 80
ACTIVE_SSH=$(ss -tulpn | grep -iE 'sshd|dropbear' | awk '{print $5}' | cut -d':' -f2 | grep -vE '443|80' | head -n 1)

if [ -n "$ACTIVE_SSH" ]; then
    echo "  [INFO] Found active SSH daemon on port: $ACTIVE_SSH"
    # Update sslh to point exactly to the working SSH port
    sed -i "s/--ssh 127.0.0.1:[0-9]*/--ssh 127.0.0.1:$ACTIVE_SSH/" /etc/default/sslh
    systemctl restart sslh
    echo "  [SUCCESS] SSLH dispatcher is now linked to Port $ACTIVE_SSH!"
else
    echo "  [ERROR] SSH daemons completely failed to start."
    echo "  Run: journalctl -xeu ssh --no-pager"
fi
