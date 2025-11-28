#!/bin/bash
#===============================================================================
# Script de destruction de l'infrastructure
#===============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=========================================="
echo "   DESTRUCTION DE L'INFRASTRUCTURE"
echo "=========================================="
echo ""

log_warning "Cette action va DÉTRUIRE toute l'infrastructure!"
log_warning "Toutes les VMs et données seront perdues."
echo ""

read -p "Êtes-vous sûr de vouloir continuer? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Opération annulée."
    exit 0
fi

cd "${PROJECT_DIR}/terraform"

log_info "Destruction de l'infrastructure Terraform..."
terraform destroy -auto-approve

log_info "Infrastructure détruite avec succès."
