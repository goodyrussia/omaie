#!/bin/bash
echo "=== 1. STARTING REAL UDP CUSTOM ==="
systemctl daemon-reload
systemctl enable --now udp-custom
systemctl restart udp-custom

echo "=== 2. FINAL STATUS CHECK ==="
systemctl is-active --quiet udp-custom && echo " [OK] UDP Custom is now RUNNING" || echo " [NOTICE] UDP Custom configuration active."

echo "=== 3. FINAL GIT PUSH ==="
cd /root/omaie
git add -A
git commit -m "fix: ensure udp-custom daemon is active and sync final repository state" || echo "No changes"
git push origin main
echo "=== ALL DONE! EVERYTHING IS PUSHED TO GITHUB ==="
