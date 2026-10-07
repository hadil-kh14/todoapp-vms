#!/bin/bash
# ══════════════════════════════════════════
# Script VM1 — Build React + Nginx
# ══════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env.example"

echo "▶ Installation Node.js + Nginx..."
apt-get update -q
apt-get install -y curl nginx
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "▶ Build du frontend React..."
cd "$SCRIPT_DIR/../frontend"

# Écrire le .env avec l'IP de l'API
echo "VITE_API_URL=http://${VM_API_IP}:${API_PORT}" > .env

npm install
npm run build

echo "▶ Déploiement vers Nginx..."
rm -rf /var/www/html/*
cp -r dist/* /var/www/html/

echo "▶ Configuration Nginx (SPA routing)..."
cat > /etc/nginx/sites-available/default << 'NGINX'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINX

nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo "✔ VM1 prête — Frontend sur http://${VM_FRONTEND_IP}"
