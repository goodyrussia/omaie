#!/bin/bash
echo "=== 1. RESOLVING PORT CONFLICTS FOR SSH WS ==="
WS_PORT=""

# Look for standard WS proxy services installed by the script
for svc in /etc/systemd/system/*ws*.service /etc/systemd/system/*proxy*.service; do
    if [ -f "$svc" ] && grep -q -iE 'python|go|node|dropbear' "$svc"; then
        # If it binds to 80 or 443, it conflicts with Nginx. Move it to 8880.
        if grep -q -E '80\b|443\b' "$svc"; then
            sed -i -E 's/( -p |:|=)80\b/\18880/g' "$svc"
            sed -i -E 's/( -p |:|=)443\b/\18880/g' "$svc"
            systemctl daemon-reload
            systemctl restart $(basename "$svc")
            echo "  [SUCCESS] Moved WS proxy in $svc to safe port 8880."
            WS_PORT=8880
        fi
    fi
done

# Try to detect running WS port if still empty
if [ -z "$WS_PORT" ]; then
    WS_PORT=$(ss -tulpn | grep -iE 'python|ws-' | grep -vE ':80\b|:443\b|:1000' | awk '{print $5}' | cut -d':' -f2 | head -n 1)
fi

if [ -z "$WS_PORT" ]; then
    echo "  [WARNING] Could not detect a running WS proxy! Defaulting Nginx to internal port 8880."
    WS_PORT=8880
else
    echo "  [INFO] Target SSH WS port is: $WS_PORT"
fi

echo "=== 2. ROUTING NGINX PORT 443 TO SSH WS ==="
conf_path="/etc/nginx/sites-available/vless_ssl.conf"

python3 -c '
import re
conf_path = "'$conf_path'"
port = "'$WS_PORT'"
block = """
    location / {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:%s;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
""" % port

with open(conf_path, "r") as f:
    content = f.read()

if "location / {" not in content:
    idx = content.rfind("}")
    if idx != -1:
        new_content = content[:idx] + block + content[idx:]
        with open(conf_path, "w") as f:
            f.write(new_content)
        print("  [SUCCESS] Injected SSHWS routing (/) into Nginx SSL config.")
else:
    # Update existing location / port
    content = re.sub(r"proxy_pass http://127\.0\.0\.1:\d+;", f"proxy_pass http://127.0.0.1:{port};", content)
    with open(conf_path, "w") as f:
        f.write(content)
    print("  [INFO] Updated existing SSHWS routing port in Nginx.")
'

nginx -t && systemctl reload nginx
echo "  [SUCCESS] SSHWS mapped to Port 443!"
