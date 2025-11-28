#!/bin/bash
#===============================================================================
# Script de backup de la base de données
#===============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Création du répertoire de backup
mkdir -p "${BACKUP_DIR}"

# Récupération de l'IP du master DB
cd "${PROJECT_DIR}/terraform"
DB_MASTER_IP=$(terraform output -raw db_master_ip)
cd - > /dev/null

log_info "Backup de la base de données depuis ${DB_MASTER_IP}..."

# Variables de connexion (à adapter selon votre configuration)
DB_USER="${DB_USER:-appuser}"
DB_NAME="${DB_NAME:-appdb}"
SSH_USER="${SSH_USER:-ubuntu}"

# Exécution du backup via SSH
ssh "${SSH_USER}@${DB_MASTER_IP}" "sudo -u postgres pg_dump ${DB_NAME}" | gzip > "${BACKUP_DIR}/backup_${TIMESTAMP}.sql.gz"

log_success "Backup créé: ${BACKUP_DIR}/backup_${TIMESTAMP}.sql.gz"

# Nettoyage des anciens backups (garder 7 jours)
find "${BACKUP_DIR}" -name "backup_*.sql.gz" -mtime +7 -delete
log_info "Anciens backups nettoyés"

# Liste des backups disponibles
echo ""
log_info "Backups disponibles:"
ls -lh "${BACKUP_DIR}"/*.sql.gz 2>/dev/null || echo "Aucun backup trouvé"
