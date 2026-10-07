#!/bin/bash
# ══════════════════════════════════════════
# Script VM3 — Installation PostgreSQL
# Charger les variables : source ../.env
# ══════════════════════════════════════════
set -e

# Charger le .env depuis la racine du projet
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env.example"

echo "▶ Installation PostgreSQL..."
apt-get update -q
apt-get install -y postgresql postgresql-contrib

echo "▶ Création de la base et de l'utilisateur..."
sudo -u postgres psql << SQL
CREATE DATABASE ${DB_NAME};
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
SQL

echo "▶ Configuration réseau PostgreSQL..."
PG_VERSION=$(ls /etc/postgresql/)
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

# Écouter sur l'IP du réseau interne
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '${VM_DB_IP}'/" "$PG_CONF"

# Autoriser les connexions depuis le réseau interne
echo "host  ${DB_NAME}  ${DB_USER}  ${VM_API_IP}/32  md5" >> "$PG_HBA"

echo "▶ Chargement des données initiales..."
sudo -u postgres psql -d ${DB_NAME} -f "$SCRIPT_DIR/../db/init.sql"

echo "▶ Redémarrage PostgreSQL..."
systemctl restart postgresql
systemctl enable postgresql

echo "✔ VM3 prête — PostgreSQL écoute sur ${VM_DB_IP}:${DB_PORT}"
