import os, re
path = "menu/monitor.sh"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        c = f.read()

    # HAProxy patch
    hap_replace = '''P_HAP=$(ss -tulpn 2>/dev/null | grep -w "haproxy" | awk '{print $5}' | rev | cut -d: -f1 | rev | sort -nu | paste -sd, -)
    [ -z "$P_HAP" ] && P_HAP="80, 443"
    check_svc "HAProxy (Mux)" "haproxy" "$P_HAP"'''
    c = re.sub(r'check_svc\s+"HAProxy \(Mux\)"\s+"haproxy"\s+"\$.*"', hap_replace, c)

    # Xray patch
    xray_replace = '''P_XRAY=$(ss -tulpn 2>/dev/null | grep -w "xray" | awk '{print $5}' | rev | cut -d: -f1 | rev | sort -nu | head -n 3 | paste -sd, -)
    [ -z "$P_XRAY" ] && P_XRAY="443, 80"
    check_svc "Xray Core" "xray" "$P_XRAY"'''
    c = re.sub(r'check_svc\s+"Xray Core"\s+"xray"\s+"\$.*"', xray_replace, c)

    with open(path, "w", encoding="utf-8") as f:
        f.write(c)
    print("\033[0;32m[+] Monitor UI patched successfully with live port lookups.\033[0m")
else:
    print("\033[0;31m[-] Error: menu/monitor.sh not found.\033[0m")
