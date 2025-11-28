# Architecture Détaillée

## Vue d'Ensemble

L'architecture est conçue pour garantir :
- **Haute disponibilité** : Redondance à chaque niveau
- **Scalabilité** : Ajout facile de serveurs
- **Sécurité** : Isolation réseau et règles firewall strictes
- **Maintenabilité** : Infrastructure as Code

## Composants

### 1. Load Balancer (1 VM)

**Rôle** : Point d'entrée unique, distribution du trafic

**Configuration** :
- Nginx avec module upstream
- SSL/TLS termination
- Health checks actifs
- Algorithme : Least Connections

**Flux** :
```
Internet → :443 (HTTPS) → Load Balancer → :80 → Web Servers
```

### 2. Web Servers (2 VMs)

**Rôle** : Servir le contenu statique, proxy vers l'API

**Configuration** :
- Nginx optimisé pour le contenu statique
- Cache activé pour les assets
- Gzip compression
- Proxy vers les App Servers pour `/api/*`

**Flux** :
```
Load Balancer → :80 → Web Server → :3000 → App Server
```

### 3. App Servers (2 VMs)

**Rôle** : Logique métier, API REST

**Configuration** :
- Python 3 + Flask
- Gunicorn (4 workers)
- Connexion PostgreSQL (Master pour écriture, Slave pour lecture)

**Flux** :
```
Web Server → :3000 → App Server → :5432 → Database
```

### 4. Database Servers (2 VMs)

**Rôle** : Stockage persistant avec réplication

**Configuration** :
- PostgreSQL 15
- Réplication streaming Master → Slave
- Hot Standby (lecture sur le slave)
- Backups automatiques quotidiens

**Flux** :
```
App Server (write) → :5432 → DB Master
App Server (read)  → :5432 → DB Slave
DB Master → :5432 → DB Slave (réplication)
```

## Sécurité

### Règles Firewall (UFW)

| Serveur | Ports Ouverts |
|---------|--------------|
| Load Balancer | 22, 80, 443 |
| Web Servers | 22, 80, 443 |
| App Servers | 22, 3000 |
| DB Servers | 22, 5432 |

### Isolation Réseau

- Seul le Load Balancer est exposé à Internet
- Communication inter-tiers sur réseau privé
- Base de données accessible uniquement depuis les App Servers

## Haute Disponibilité

### Niveaux de Redondance

1. **Load Balancing** : 2 Web Servers actifs
2. **Application** : 2 App Servers actifs
3. **Database** : Master + Slave (Hot Standby)

### Failover

- **Web/App** : Automatique via Nginx upstream
- **Database** : Manuel (promotion du slave en master)

## Scalabilité

### Horizontal Scaling

Pour ajouter des serveurs :

1. Modifier `variables.tf` :
```hcl
variable "web_ips" {
  default = ["192.168.1.11", "192.168.1.12", "192.168.1.13"]
}
```

2. Appliquer :
```bash
terraform apply
ansible-playbook playbooks/site.yml
```

### Limites

- Maximum 7 VMs (contrainte Proxmox)
- 2 vCPU / 4GB RAM par VM
- 20GB stockage par VM

## Monitoring

### Endpoints de Santé

| Endpoint | Description |
|----------|-------------|
| `/health` | Status Load Balancer |
| `/api/health` | Status Application + DB |
| `/nginx_status` | Métriques Nginx |

### Logs

| Composant | Emplacement |
|-----------|-------------|
| Nginx | `/var/log/nginx/` |
| Application | `/var/log/app/` |
| PostgreSQL | `/var/log/postgresql/` |
