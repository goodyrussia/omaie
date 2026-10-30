#!/bin/bash
REPO_DIR="/root/omaie"
GITHUB_USER="albertlanc"
GITHUB_TOKEN="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"
# Fallback token if the one above is expired: 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

cd "$REPO_DIR" || exit 1
echo "=== Working in repository: $REPO_DIR ==="

echo "=== 1. ORGANIZING FILES ==="
mkdir -p ./configs/nginx ./configs/sslh ./configs/systemd ./configs/udp-custom ./scripts

# Copy multiplexer and proxy configs
[ -f /etc/nginx/stream.d/ssl_multiplex.conf ] && cp /etc/nginx/stream.d/ssl_multiplex.conf ./configs/nginx/
[ -f /etc/nginx/conf.d/vpn_multiplex.conf ] && cp /etc/nginx/conf.d/vpn_multiplex.conf ./configs/nginx/
[ -f /etc/default/sslh ] && cp /etc/default/sslh ./configs/sslh/
[ -f /usr/local/bin/ws-proxy.py ] && cp /usr/local/bin/ws-proxy.py ./scripts/
[ -f /etc/udp-custom/config.json ] && cp /etc/udp-custom/config.json ./configs/udp-custom/

# Copy systemd service definitions
[ -f /etc/systemd/system/ws-proxy-custom.service ] && cp /etc/systemd/system/ws-proxy-custom.service ./configs/systemd/
[ -f /etc/systemd/system/udp-custom.service ] && cp /etc/systemd/system/udp-custom.service ./configs/systemd/

# Copy setup scripts created during the session
cp -u /root/omaie/*.sh ./scripts/ 2>/dev/null

echo "=== 2. STAGING CHANGES ==="
git status
git add -A

echo "=== 3. COMMITTING CHANGES ==="
COMMIT_MSG="feat: complete 80/443 multiplexer, pure SSL resolution, and real UDP custom stack"
git commit -m "$COMMIT_MSG"

echo "=== 4. CONFIGURING AUTHENTICATION ==="
BRANCH=$(git branch --show-current)
[ -z "$BRANCH" ] && BRANCH="main"

# Get current remote URL and extract repo name, fallback to 'oma' if missing
REPO_URL=$(git config --get remote.origin.url)
if [[ $REPO_URL == *".git" ]]; then
    REPO_NAME=$(basename -s .git "$REPO_URL")
else
    REPO_NAME="oma"
fi

# Inject token directly into remote URL
git remote set-url origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo "=== 5. PUSHING TO REPOSITORY ==="
git push origin "$BRANCH"
echo "=== DONE! ==="
