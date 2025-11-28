# Projet DevOps - Déploiement d'une Application Web Haute Disponibilité

## Architecture

Infrastructure distribuée sur 7 machines virtuelles :

```
                    ┌─────────────────┐
                    │   Internet      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Load Balancer  │  (1 VM - Nginx)
                    │   192.168.1.10  │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │   Web Server 1  │           │   Web Server 2  │  (2 VMs - Nginx)
     │  192.168.1.11   │           │  192.168.1.12   │
     └────────┬────────┘           └────────┬────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │   App Server 1  │           │   App Server 2  │  (2 VMs - Python/Flask)
     │  192.168.1.21   │           │  192.168.1.22   │
     └────────┬────────┘           └────────┬────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │   DB Master     │◄─────────►│   DB Slave      │  (2 VMs - PostgreSQL)
     │  192.168.1.31   │ Réplication│  192.168.1.32   │
     └─────────────────┘           └─────────────────┘
```

## Prérequis

- Proxmox VE 7.x ou supérieur
- Terraform >= 1.0.0
- Ansible >= 2.12
- Packer >= 1.8
- Ubuntu 22.04 ISO

## Structure du Projet

```
project/
├── terraform/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── templates/
├── packer/             # Images VM
│   ├── web.json
│   ├── app.json
│   └── db.json
├── ansible/            # Configuration
│   ├── playbooks/
│   ├── roles/
│   └── inventory/
├── app/                # Application
│   ├── frontend/
│   └── backend/
├── docs/               # Documentation
├── scripts/            # Automatisation
└── README.md
```

## Déploiement Rapide

### 1. Configuration

```bash
# Copier et éditer les variables Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
vim terraform/terraform.tfvars

# Configurer les variables d'environnement Packer
export PROXMOX_URL="https://your-proxmox:8006/api2/json"
export PROXMOX_USERNAME="terraform@pam!terraform"
export PROXMOX_PASSWORD="your-password"
export PROXMOX_NODE="pve"
```

### 2. Déploiement Complet

```bash
./scripts/deploy.sh --all
```

### 3. Déploiement Étape par Étape

```bash
# Construction des images
./scripts/deploy.sh --images

# Provisionnement de l'infrastructure
./scripts/deploy.sh --infra

# Configuration des serveurs
./scripts/deploy.sh --config

# Déploiement de l'application
./scripts/deploy.sh --app
```

## Vérification

```bash
# Health check complet
./scripts/health-check.sh

# Accès à l'application
curl -k https://192.168.1.10/api/health
```

## Règles Réseau

| Source | Destination | Ports | Statut |
|--------|------------|-------|--------|
| Internet | Load Balancer | 80, 443 | Autorisé |
| Load Balancer | Web Servers | 80, 443 | Autorisé |
| Web Servers | App Servers | 3000 | Autorisé |
| App Servers | Database Servers | 5432 | Autorisé |
| Database Servers | Database Servers | 5432 | Réplication |
| Admin | Tous les serveurs | 22 | SSH |

## Contraintes Techniques

- **VMs**: 7 maximum
- **CPU**: 2 vCPU par VM
- **RAM**: 4GB par VM
- **Stockage**: 20GB par VM
- **Déploiement**: < 15 minutes

## Scripts Disponibles

| Script | Description |
|--------|-------------|
| `deploy.sh` | Déploiement complet ou partiel |
| `destroy.sh` | Destruction de l'infrastructure |
| `health-check.sh` | Vérification de santé |
| `backup-db.sh` | Backup de la base de données |

## Documentation

- [Guide d'installation](docs/installation.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Architecture détaillée](docs/architecture.md)
