conf_path = "/etc/nginx/sites-available/vless_ssl.conf"

with open(conf_path, "r") as f:
    content = f.read()

extra_locations = """
    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
"""

if "location /vmess" not in content:
    idx = content.rfind("}")
    if idx != -1:
        new_content = content[:idx] + extra_locations + content[idx:]
        with open(conf_path, "w") as f:
            f.write(new_content)
        print("[SUCCESS] Added VMess and Trojan location blocks to Nginx.")
else:
    print("[INFO] VMess/Trojan location blocks already present.")
