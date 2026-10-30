#!/bin/bash
echo "=== 1. FINDING XRAY WEBSOCKET PORT ==="
xray_port=$(grep -A 5 -i "ws" /etc/xray/config.json 2>/dev/null | grep -i "port" | head -n 1 | tr -dc '0-9')
[ -z "$xray_port" ] && xray_port="10000"
echo "  [INFO] Xray port: $xray_port"

echo "=== 2. LOCATING NGINX CONFIG FILE CONTAINING PORT 443 ==="
nginx_conf=$(grep -rnw '/etc/nginx/' -e 'listen.*443' | head -n 1 | cut -d':' -f1)

if [ -z "$nginx_conf" ]; then
    echo "  [ERROR] Could not locate Nginx configuration file with port 443."
    exit 1
fi
echo "  [INFO] Found Nginx config at: $nginx_conf"

echo "=== 3. INJECTING /xray LOCATION BLOCK ==="
if grep -q "location /xray" "$nginx_conf"; then
    echo "  [INFO] /xray location block already present."
else
    python3 -c '
path = "'$nginx_conf'"
port = "'$xray_port'"
block = """
    location /xray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:%s;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
""" % port

with open(path, "r") as f:
    content = f.read()

idx = content.rfind("}")
if idx != -1:
    new_content = content[:idx] + block + content[idx:]
    with open(path, "w") as f:
        f.write(new_content)
    print("  [SUCCESS] Injected /xray location block.")
'
fi

echo "=== 4. TESTING & RELOADING NGINX ==="
nginx -t && systemctl reload nginx
echo "  [SUCCESS] Nginx reloaded!"
