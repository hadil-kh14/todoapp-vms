#!/bin/bash
# ══════════════════════════════════════════
# Script VM2 — Installation API Node.js
# ══════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env.example"

echo "▶ Installation Node.js..."
apt-get update -q
apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "▶ Installation des dépendances API..."
cd "$SCRIPT_DIR/../backend"
npm install --production

echo "▶ Création du service systemd..."
cat > /etc/systemd/system/todo-api.service << EOF
[Unit]
Description=Todo API Node.js
After=network.target

[Service]
Environment=DB_HOST=${VM_DB_IP}
Environment=DB_PORT=${DB_PORT}
Environment=DB_NAME=${DB_NAME}
Environment=DB_USER=${DB_USER}
Environment=DB_PASSWORD=${DB_PASSWORD}
Environment=API_PORT=${API_PORT}
WorkingDirectory=$SCRIPT_DIR/../backend
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now todo-api

echo "✔ VM2 prête — API écoute sur ${VM_API_IP}:${API_PORT}"
echo "  Test : curl http://${VM_API_IP}:${API_PORT}/health"
