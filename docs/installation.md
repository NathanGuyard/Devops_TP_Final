# Guide d'Installation

## Prérequis Système

### Outils à installer

```bash
# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Ansible
sudo apt install ansible

# Packer
sudo apt install packer
```

### Configuration Proxmox

1. Créer un utilisateur API dans Proxmox :
   - Datacenter → Permissions → Users → Add
   - Username: `terraform@pam`

2. Créer un token API :
   - Datacenter → Permissions → API Tokens → Add
   - User: `terraform@pam`
   - Token ID: `terraform`
   - Copier le secret généré

3. Attribuer les permissions :
   - Datacenter → Permissions → Add
   - Path: `/`
   - User: `terraform@pam`
   - Role: `Administrator`

## Configuration

### Variables Terraform

Créer le fichier `terraform/terraform.tfvars` :

```hcl
proxmox_api_url          = "https://192.168.1.100:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!terraform"
proxmox_api_token_secret = "votre-secret-token"
proxmox_node             = "pve"

# Adresses IP à adapter selon votre réseau
gateway        = "192.168.1.1"
lb_ip          = "192.168.1.10"
web_ips        = ["192.168.1.11", "192.168.1.12"]
app_ips        = ["192.168.1.21", "192.168.1.22"]
db_master_ip   = "192.168.1.31"
db_slave_ip    = "192.168.1.32"

# Clé SSH
ssh_public_key = "ssh-rsa AAAA... votre-clé-publique"
```

### Variables d'environnement Packer

```bash
export PROXMOX_URL="https://192.168.1.100:8006/api2/json"
export PROXMOX_USERNAME="terraform@pam!terraform"
export PROXMOX_PASSWORD="votre-secret-token"
export PROXMOX_NODE="pve"
```

## Déploiement

### Étape 1 : Construction des images

```bash
cd packer
packer build web.json
packer build app.json
packer build db.json
```

### Étape 2 : Provisionnement de l'infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Étape 3 : Configuration des serveurs

```bash
cd ansible
ansible-playbook playbooks/site.yml
```

### Étape 4 : Déploiement de l'application

```bash
ansible-playbook playbooks/deploy-app.yml
```

## Vérification

```bash
# Test de l'API
curl -k https://192.168.1.10/api/health

# Test du frontend
curl -k https://192.168.1.10/

# Health check complet
./scripts/health-check.sh
```

## Mise à jour de l'application

Pour mettre à jour l'application sans interruption :

```bash
cd ansible
ansible-playbook playbooks/rolling-update.yml
```
