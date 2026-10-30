#!/bin/bash
echo "=== 1. FIXING SSLH DEADLOCK (PURE SSL TIMEOUT) ==="
# We rewrite the sslh options to include '--timeout 1' and '--anyprot'.
# If no HTTP data is sent within 1 second, it forces the traffic to Dropbear (109)

cat << 'SSLHEOF' > /etc/default/sslh
RUN=yes
DAEMON_OPTS="--user sslh --listen 127.0.0.1:4444 --ssh 127.0.0.1:109 --http 127.0.0.1:8080 --anyprot 127.0.0.1:109 --timeout 1"
SSLHEOF

echo "=== 2. RESTARTING MULTIPLEXER ==="
systemctl restart sslh
systemctl restart nginx

echo "=== 3. VERIFYING PORT 4444 ROUTING ==="
ss -tulpn | grep ':4444'
echo "=== DONE! PURE SSL DEADLOCK RESOLVED ==="
