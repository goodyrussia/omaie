#!/bin/bash
echo "=== 1. CLEANING UP CONFLICTING NGINX CONFIGS ==="
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/conf.d/*

echo "=== 2. CREATING UNIFIED NGINX MULTIPLEXER ==="
# This forces Nginx to catch ALL traffic on 80 and 443 regardless of SNI
cat << 'NGINXEOF' > /etc/nginx/conf.d/vpn_multiplex.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    # SSL Certificate Paths
    ssl_certificate /root/.acme.sh/lebara.omatescomobile.com/lebara.omatescomobile.com.cer;
    ssl_certificate_key /root/.acme.sh/lebara.omatescomobile.com/lebara.omatescomobile.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Xray VLESS (Path: /xray)
    location = /xray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    # Xray VMESS (Path: /vmess)
    location = /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    # Xray TROJAN (Path: /trojan)
    location = /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    # SSH WS Proxy (Catch-All Path for /)
    location / {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
}
NGINXEOF

echo "=== 3. BUILDING HIGH-PERFORMANCE SSH WS PROXY ==="
# This Python script listens internally on 8880 and forwards to local SSH (port 22)
cat << 'PYEOF' > /usr/local/bin/ws-proxy.py
import socket, threading

def handle_client(client_socket):
    try:
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))
        
        request = client_socket.recv(8192)
        if b"HTTP/" in request:
            response = b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            client_socket.send(response)
        else:
            ssh_socket.send(request)
            
        def forward(src, dst):
            try:
                while True:
                    data = src.recv(8192)
                    if not data: break
                    dst.send(data)
            except: pass
            finally:
                src.close()
                dst.close()
                
        threading.Thread(target=forward, args=(client_socket, ssh_socket), daemon=True).start()
        threading.Thread(target=forward, args=(ssh_socket, client_socket), daemon=True).start()
    except:
        client_socket.close()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('127.0.0.1', 8880))
server.listen(100)
while True:
    client, _ = server.accept()
    threading.Thread(target=handle_client, args=(client,), daemon=True).start()
PYEOF

echo "=== 4. RESTARTING SERVICES ==="
cat << 'SRVEOF' > /etc/systemd/system/ws-proxy-custom.service
[Unit]
Description=Python WS Proxy for SSH
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy.py
Restart=always

[Install]
WantedBy=multi-user.target
SRVEOF

systemctl daemon-reload
systemctl stop ws-proxy-custom.service 2>/dev/null

# Kill any rogue process holding port 8880
pid=$(ss -tulpn | grep ':8880 ' | awk '{print $6}' | cut -d',' -f1 | cut -d'=' -f2)
[ -n "$pid" ] && kill -9 $pid

systemctl enable --now ws-proxy-custom.service

# Test and reload Nginx
nginx -t && systemctl restart nginx
echo "=== ALL DONE! PORTS 80 & 443 ARE FULLY MULTIPLEXED ==="
