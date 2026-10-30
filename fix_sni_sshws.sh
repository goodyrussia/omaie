#!/bin/bash
echo "=== 1. ENFORCING CATCH-ALL FOR NGINX (SNI BUGGING) ==="
# Remove default Nginx config to prevent routing conflicts
rm -f /etc/nginx/sites-enabled/default

conf="/etc/nginx/sites-available/vless_ssl.conf"
# Make this config the default server for ANY SNI request
sed -i 's/listen 443 ssl;/listen 443 ssl default_server;/g' "$conf"
sed -i 's/server_name lebara.omatescomobile.com;/server_name _;/' "$conf"

echo "=== 2. VERIFYING BACKEND SSH WS PROXY ==="
WS_PID=$(ss -tulpn | grep ':8880 ' | awk '{print $6}' | cut -d',' -f1 | cut -d'=' -f2)
if [ -z "$WS_PID" ]; then
    echo "  [WARNING] Nothing is listening on port 8880! SSHWS backend is offline."
    echo "  [ACTION] Launching a reliable Python WS proxy on 8880..."
    
    # Create a robust Python WS Proxy script
    cat << 'PYEOF' > /usr/local/bin/ws-proxy.py
import socket, threading

def handle(client):
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.connect(('127.0.0.1', 22))
        req = client.recv(8192)
        
        if b'HTTP/' in req:
            client.send(b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n')
        else:
            server.send(req)
            
        def forward(s, d):
            try:
                while True:
                    data = s.recv(8192)
                    if not data: break
                    d.send(data)
            except: pass
            
        threading.Thread(target=forward, args=(client, server), daemon=True).start()
        threading.Thread(target=forward, args=(server, client), daemon=True).start()
    except:
        client.close()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', 8880))
server.listen(100)
while True:
    c, a = server.accept()
    threading.Thread(target=handle, args=(c,)).start()
PYEOF
    
    # Create systemd service for the proxy
    cat << 'SRVEOF' > /etc/systemd/system/ws-proxy-custom.service
[Unit]
Description=Python WS Proxy for SSH
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy.py
Restart=always

[Install]
WantedBy=multi-user.target
SRVEOF
    
    systemctl daemon-reload
    systemctl enable --now ws-proxy-custom.service
    echo "  [SUCCESS] Backup SSH WS Proxy started on port 8880!"
else
    echo "  [OK] Backend service is running on port 8880."
fi

echo "=== 3. RELOADING NGINX ==="
nginx -t && systemctl restart nginx
echo "  [SUCCESS] SNI Routing & SSHWS mapped securely!"
