#!/bin/bash
echo "=== 1. CLEANING UP CONFLICTING CONFIGS ==="
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/conf.d/*
systemctl stop ws-proxy-custom.service 2>/dev/null
fuser -k 8880/tcp 2>/dev/null

echo "=== 2. CREATING EXPLICIT NGINX MULTIPLEXER ==="
cat << 'NGINXEOF' > /etc/nginx/conf.d/vpn_multiplex.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    ssl_certificate /root/.acme.sh/lebara.omatescomobile.com/lebara.omatescomobile.com.cer;
    ssl_certificate_key /root/.acme.sh/lebara.omatescomobile.com/lebara.omatescomobile.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Xray VLESS
    location = /xray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    # Xray VMESS
    location = /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    # Xray TROJAN
    location = /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    # Dedicated SSH WebSocket Proxy
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

echo "=== 3. BUILDING BULLETPROOF SSH WS PROXY ==="
cat << 'PYEOF' > /usr/local/bin/ws-proxy.py
import socket, threading
def handle(client):
    try:
        req = client.recv(4096).decode('utf-8', 'ignore')
        if not req: return
        
        # Standard WebSocket handshake accepted by SSH Custom
        client.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        
        ssh = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh.connect(('127.0.0.1', 22))
        
        def forward(s, d):
            try:
                while True:
                    data = s.recv(4096)
                    if not data: break
                    d.send(data)
            except: pass
            finally:
                s.close()
                d.close()
                
        threading.Thread(target=forward, args=(client, ssh), daemon=True).start()
        threading.Thread(target=forward, args=(ssh, client), daemon=True).start()
    except: pass

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('127.0.0.1', 8880))
s.listen(100)
while True:
    c, _ = s.accept()
    threading.Thread(target=handle, args=(c,)).start()
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
systemctl enable --now ws-proxy-custom.service
nginx -t && systemctl restart nginx
echo "=== PORTS 80 & 443 ARE NOW FULLY ROUTED ==="
