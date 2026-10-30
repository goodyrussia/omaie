import json

print("=== 1. CHECKING PORT 443 LISTENERS ===")
import subprocess
result = subprocess.run(["ss", "-tulpn"], capture_output=True, text=True)
for line in result.stdout.splitlines():
    if ":443" in line or ":80" in line:
        print("  ", line)

print("\n=== 2. INSPECTING XRAY CONFIG INBOUNDS ===")
try:
    with open("/etc/xray/config.json", "r") as f:
        data = json.load(f)
    for idx, inbound in enumerate(data.get("inbounds", [])):
        tag = inbound.get("tag", "N/A")
        port = inbound.get("port", "N/A")
        proto = inbound.get("protocol", "N/A")
        print(f"  -> Inbound {idx}: tag={tag}, port={port}, protocol={proto}")
except Exception as e:
    print("  [ERROR] Reading Xray config:", e)
