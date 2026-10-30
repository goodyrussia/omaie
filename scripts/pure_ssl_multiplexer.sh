#!/bin/bash
echo "=== 1. INSTALLING PROTOCOL DISPATCHER (SSLH) ==="
# Stop stunnel if it was started from the previous test
systemctl stop stunnel4 2>/dev/null
systemctl disable stunnel4 2>/dev/null

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y sslh

echo "=== 2. CONFIGURING SSLH ==="
# Listen internally on 4444. Route SSH to 22. Route HTTP to Nginx on 8080.
cat << 'SSLHEOF' > /etc/default/sslh
RUN=yes
DAEMON_OPTS="--user sslh --listen 127.0.0.1:4444 --ssh 127.0.0.1:22 --http 127.0.0.1:8080 --pidfile /var/run/sslh/sslh.pid"
SSLHEOF

systemctl restart sslh
systemctl enable sslh

echo "=== 3. CONFIGURING NGINX TLS DECRYPTOR (STREAM) ==="
# Inject stream support into the main nginx config if missing
python3 -c "
conf_path = '/etc/nginx/nginx.conf'
with open(conf_path, 'r') as f:
    content = f.read()
if 'stream {' not in content:
    content += '\nstream {\n    include /etc/nginx/stream.d/*.conf;\n}\n'
    with open(conf_path, 'w') as f:
        f.write(content)
"

mkdir -p /etc/nginx/stream.d
cat << 'NGINXSTREAM' > /etc/nginx/stream.d/ssl_multiplex.conf
server {
    listen 443 ssl;
    ssl_certificate /root/.acme.sh/lebara.omatescomobile.com/lebara.omatescomobile.com.cer;
    ssl_certificate_key /root/.acme.sh/lebara.omatescomobile.com/lebara.omatescomobile.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Pass all decrypted traffic to SSLH for protocol inspection
    proxy_pass 127.0.0.1:4444;
}
NGINXSTREAM

echo "=== 4. CONFIGURING NGINX HTTP ROUTER ==="
cat << 'NGINXEOF' > /etc/nginx/conf.d/vpn_multiplex.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 127.0.0.1:8080 default_server; # Receives HTTP traffic from SSLH

    server_name _;

    location = /xray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    location = /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    location = /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    location = /sshws {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
}
NGINXEOF

echo "=== 5. APPLYING CHANGES ==="
nginx -t && systemctl restart nginx
echo "=== PORT 443 FULLY ARMED FOR PURE SSL AND WEBSOCKETS ==="
