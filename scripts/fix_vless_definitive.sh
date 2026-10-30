#!/bin/bash
echo "=== 1. CHECKING WHO OWNS PORT 443 ==="
ss -tulpn | grep ':443 '

echo -e "\n=== 2. INSPECTING XRAY INBOUND PORTS ==="
python3 -c '
import json
try:
    with open("/etc/xray/config.json") as f:
        data = json.load(f)
    for idx, inbound in enumerate(data.get("inbounds", [])):
        print(f"  -> Inbound {idx}: tag={inbound.get(\"tag\")}, port={inbound.get(\"port\")}, protocol={inbound.get(\"protocol\")}")
except Exception as e:
    print("  [ERROR] Reading xray config:", e)
'

echo -e "\n=== 3. ENSURING XRAY RESTART & SERVICE HEALTH ==="
systemctl restart xray
systemctl status xray --no-pager | head -n 8
