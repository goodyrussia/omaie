#!/bin/bash
echo "=== 1. FINDING XRAY LOCAL WEBSOCKET PORT ==="
# Extract the local port Xray is listening on for WebSocket
xray_port=$(grep -A 5 -i "ws" /etc/xray/config.json 2>/dev/null | grep -i "port" | head -n 1 | tr -dc '0-9')
if [ -z "$xray_port" ]; then
    xray_port="10000" # Fallback default
fi
echo "  [INFO] Detected Xray internal WS port: $xray_port"

echo "=== 2. LOCATING NGINX CONFIG FILE ==="
nginx_conf=""
for conf in /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*; do
    if [ -f "$conf" ] && grep -q "listen.*443" "$conf"; then
        nginx_conf="$conf"
        break
    fi
done

if [ -z "$nginx_conf" ]; then
    echo "  [ERROR] Could not find an active Nginx 443 server block configuration!"
    exit 1
fi
echo "  [INFO] Found Nginx config: $nginx_conf"

echo "=== 3. INJECTING /xray LOCATION BLOCK ==="
if grep -q "location /xray" "$nginx_conf"; then
    echo "  [INFO] /xray location block already exists in Nginx config."
else
    # Insert the location block right before the last closing brace of the server block
    python3 -c '
conf_path = "'$nginx_conf'"
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

with open(conf_path, "r") as f:
    content = f.read()

# Insert before the last closing brace
last_brace = content.rfind("}")
if last_brace != -1:
    new_content = content[:last_brace] + block + content[last_brace:]
    with open(conf_path, "w") as f:
        f.write(new_content)
    print("  [SUCCESS] Injected /xray location block into Nginx config.")
else:
    print("  [ERROR] Could not parse Nginx server block braces.")
'
fi

echo "=== 4. TESTING & RELOADING NGINX ==="
nginx -t && systemctl reload nginx
echo "  [SUCCESS] Nginx reloaded successfully!"
