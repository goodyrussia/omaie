#!/bin/bash
REPO_DIR="/root/omaie"
GITHUB_USER="albertlanc"
GITHUB_TOKEN="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"

cd "$REPO_DIR" || exit 1
echo "=== Working in repository: $REPO_DIR ==="

echo "=== 1. ORGANIZING LATEST FIXES ==="
mkdir -p ./configs/nginx ./configs/sslh ./configs/systemd ./configs/udp-custom ./scripts

# Copy multiplexer and proxy configs
[ -f /etc/nginx/stream.d/ssl_multiplex.conf ] && cp /etc/nginx/stream.d/ssl_multiplex.conf ./configs/nginx/
[ -f /etc/nginx/conf.d/vpn_multiplex.conf ] && cp /etc/nginx/conf.d/vpn_multiplex.conf ./configs/nginx/
[ -f /etc/default/sslh ] && cp /etc/default/sslh ./configs/sslh/
[ -f /usr/local/bin/ws-proxy.py ] && cp /usr/local/bin/ws-proxy.py ./scripts/
[ -f /etc/udp-custom/config.json ] && cp /etc/udp-custom/config.json ./configs/udp-custom/
[ -f /etc/systemd/system/ws-proxy-custom.service ] && cp /etc/systemd/system/ws-proxy-custom.service ./configs/systemd/
[ -f /etc/systemd/system/udp-custom.service ] && cp /etc/systemd/system/udp-custom.service ./configs/systemd/

# Copy all session scripts including the sslh deadlock fix
cp -u /root/omaie/*.sh ./scripts/ 2>/dev/null

echo "=== 2. STAGING & COMMITTING ==="
git status
git add -A
git commit -m "fix: update repository target to omaie and push final port 443 pure ssl + sshws multiplexer stack" || echo "No changes to commit"

echo "=== 3. SETTING CORRECT REMOTE TO OMAIE ==="
BRANCH=$(git branch --show-current)
[ -z "$BRANCH" ] && BRANCH="main"

# Explicitly set remote origin to your omaie repo
git remote set-url origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/omaie.git"

echo "=== 4. PUSHING TO GITHUB (OMAIE) ==="
git push -u origin "$BRANCH"
echo "=== DONE! ALL LATEST WORKING FIXES PUSHED TO OMAIE ==="
