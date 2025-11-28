# Guide de Troubleshooting

## Problèmes Courants

### 1. Erreur de connexion Terraform à Proxmox

**Symptôme** : `Error: 401 Unauthorized`

**Solutions** :
```bash
# Vérifier les credentials
echo $PROXMOX_URL
echo $PROXMOX_USERNAME

# Tester la connexion API
curl -k -d "username=terraform@pam&password=xxx" \
  https://proxmox:8006/api2/json/access/ticket
```

### 2. Les VMs ne démarrent pas

**Symptôme** : VMs en état "stopped"

**Solutions** :
```bash
# Vérifier les ressources disponibles sur Proxmox
pvesh get /nodes/pve/status

# Vérifier les logs Proxmox
journalctl -u pve-cluster -f
```

### 3. Ansible ne peut pas se connecter aux VMs

**Symptôme** : `SSH connection refused`

**Solutions** :
```bash
# Vérifier que les VMs sont accessibles
ping 192.168.1.10

# Tester SSH manuellement
ssh -v ubuntu@192.168.1.10

# Vérifier la clé SSH
ssh-add -l
```

### 4. L'application ne répond pas

**Symptôme** : `502 Bad Gateway` ou timeout

**Solutions** :
```bash
# Sur le Load Balancer
sudo nginx -t
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log

# Sur les App Servers
sudo systemctl status app
sudo journalctl -u app -f
```

### 5. Erreur de connexion à la base de données

**Symptôme** : `Connection refused` sur port 5432

**Solutions** :
```bash
# Sur le serveur DB
sudo systemctl status postgresql
sudo tail -f /var/log/postgresql/postgresql-15-main.log

# Vérifier pg_hba.conf
sudo cat /etc/postgresql/15/main/pg_hba.conf

# Tester la connexion
psql -h localhost -U appuser -d appdb
```

### 6. Réplication PostgreSQL en échec

**Symptôme** : Le slave ne reçoit pas les données

**Solutions** :
```bash
# Sur le Master
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Sur le Slave
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

# Vérifier les logs
sudo tail -f /var/lib/postgresql/15/main/log/*.log
```

## Commandes de Diagnostic

### Vérification globale
```bash
./scripts/health-check.sh
```

### Logs centralisés
```bash
# Load Balancer
ssh ubuntu@192.168.1.10 "sudo tail -100 /var/log/nginx/access.log"

# App Servers
ssh ubuntu@192.168.1.21 "sudo tail -100 /var/log/app/error.log"

# Database
ssh ubuntu@192.168.1.31 "sudo tail -100 /var/log/postgresql/postgresql-15-main.log"
```

### Test de la chaîne complète
```bash
# 1. Test Load Balancer → Web
curl -k https://192.168.1.10/

# 2. Test Web → App
curl http://192.168.1.11/api/health

# 3. Test App → DB
curl http://192.168.1.21:3000/api/stats
```

## Rollback

### Rollback Terraform
```bash
cd terraform
terraform plan -target=... # Identifier les ressources
terraform apply -target=... # Appliquer sélectivement
```

### Rollback Application
```bash
# Restaurer depuis un backup
./scripts/backup-db.sh restore backups/backup_YYYYMMDD_HHMMSS.sql.gz

# Redéployer une version précédente
git checkout v1.0.0
ansible-playbook ansible/playbooks/deploy-app.yml
```
