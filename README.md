# TodoApp : Déploiement Cloud et infrastructure virtualisée

TP 1 : Virtualisation et Cloud Computing, ENIS (2026-2027)
Enseignante : Chaima ZAHANI
Binôme : [Nom 1] et [Nom 2]

## 1. Présentation

Application web de gestion de tâches (ajout, consultation, modification, suppression), déployée de deux façons :

1. **Dans le Cloud** avec Vercel et une base PostgreSQL Neon.
2. **Dans une infrastructure virtualisée** : 3 machines virtuelles VirtualBox selon une architecture 3-tiers.

Version Cloud : [URL Vercel de l'application]

## 2. Architecture 3-tiers

```
Navigateur --> VM-Web (Nginx) --> VM-Backend (Node.js/Express) --> VM-Database (PostgreSQL)
```

| Couche | Machine virtuelle | Technologie | Adresse IP | Port |
|---|---|---|---|---|
| Présentation | VM-Web | Nginx + frontend (Vite) | 192.168.100.10 | 80 |
| Application | VM-Backend | Node.js / Express | 192.168.100.20 | 4000 |
| Données | VM-Database | PostgreSQL | 192.168.100.30 | 5432 |

- Réseau interne VirtualBox : `intnet` (192.168.100.0/24).
- Chaque VM a deux cartes réseau : **NAT** (Internet et port forwarding) et **Réseau interne** `intnet` (communication entre les VM, interface `enp0s8`).
- Accès depuis la machine hôte : port forwarding du port 8080 de l'hôte vers le port 80 de VM-Web.

## 3. Structure du dépôt

```
frontend/   Application React (Vite)
backend/    API Node.js / Express
db/         Script SQL d'initialisation (init.sql)
scripts/    Scripts d'automatisation (optionnels)
```

## 4. Identifiants de la base de données

| Paramètre | Valeur |
|---|---|
| Base | tododb |
| Utilisateur | todouser |
| Mot de passe | todopass |

Ces valeurs sont réservées au TP et ne doivent pas être utilisées en production.

## 5. Déploiement

### 5.1 VM-Database (192.168.100.30)

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
sudo -u postgres psql
```

Dans psql :

```sql
CREATE USER todouser WITH PASSWORD 'todopass';
CREATE DATABASE tododb OWNER todouser;
\q
```

Autoriser les connexions réseau :

```bash
sudo -u postgres psql -c "SHOW config_file;"   # puis listen_addresses = '*'
sudo -u postgres psql -c "SHOW hba_file;"      # puis ajouter la règle ci-dessous
```

Règle à ajouter dans `pg_hba.conf` :

```
host tododb todouser 192.168.100.0/24 scram-sha-256
```

```bash
sudo systemctl restart postgresql
sudo ss -lntp | grep 5432
```

### 5.2 VM-Backend (192.168.100.20)

```bash
sudo apt update && sudo apt install -y nodejs npm postgresql-client git
git clone https://github.com/[utilisateur]/todoapp-vms.git
cd todoapp-vms/backend
npm install
psql -h 192.168.100.30 -U todouser -d tododb -f ../db/init.sql
npm start
```

Test depuis VM-Web :

```bash
curl http://192.168.100.20:4000/tasks
```

### 5.3 VM-Web (192.168.100.10)

```bash
sudo apt update && sudo apt install -y nodejs npm nginx git
git clone https://github.com/[utilisateur]/todoapp-vms.git
cd todoapp-vms/frontend
npm install
npm run build
sudo mkdir -p /var/www/todoapp
sudo cp -r dist/* /var/www/todoapp/
sudo chown -R www-data:www-data /var/www/todoapp
sudo chmod -R 755 /var/www/todoapp
```

Configuration Nginx (`/etc/nginx/sites-available/todoapp`) :

```nginx
server {
    listen 80;
    server_name _;
    root /var/www/todoapp;
    index index.html;

    location /api/ {
        proxy_pass http://192.168.100.20:4000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/todoapp /etc/nginx/sites-enabled/todoapp
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
curl http://localhost
curl http://localhost/api/tasks
```

### 5.4 Port forwarding (VirtualBox)

VM-Web éteinte : **Configuration, Réseau, Adaptateur 1 (NAT), Avancé, Redirection de ports**.

| Protocole | Port hôte | Port invité |
|---|---|---|
| TCP | 8080 | 80 |

L'application est alors accessible depuis l'hôte : http://localhost:8080

## 6. Tests et validation

- [ ] `ping` entre les trois VM
- [ ] PostgreSQL actif (`systemctl status postgresql`)
- [ ] `curl http://192.168.100.20:4000/tasks` renvoie du JSON
- [ ] Nginx actif et `nginx -t` correct
- [ ] Application accessible sur http://localhost:8080
- [ ] Ajout, modification et suppression de tâches fonctionnels
- [ ] Données visibles en base : `sudo -u postgres psql -d tododb -c "SELECT * FROM tasks;"`

## 7. Captures d'écran

À ajouter : déploiement Vercel, ping entre les VM, statut des services, application dans le navigateur, résultat du SELECT.

## 8. Cloud et virtualisation : comparaison

| Critère | Cloud (Vercel + Neon) | Infrastructure virtualisée |
|---|---|---|
| Mise en place | Quelques clics, quelques minutes | Installation et configuration manuelles |
| Gestion de l'infrastructure | Déléguée au fournisseur | À la charge de l'équipe |
| Contrôle | Limité | Total (système, réseau, services) |
| Évolutivité | Automatique | Manuelle |
| Coût | Offre gratuite, puis à l'usage | Coût du matériel hôte |
