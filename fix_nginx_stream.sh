#!/bin/bash
echo "=== 1. INSTALLING NGINX STREAM MODULE ==="
apt-get update
apt-get install -y libnginx-mod-stream

echo "=== 2. VERIFYING NGINX CONFIGURATION ==="
# Ensure the stream module is loaded correctly
nginx -t

echo "=== 3. RESTARTING NGINX ==="
systemctl restart nginx
echo "=== PORT 443 MULTIPLEXER IS NOW ACTIVE ==="
