#!/bin/bash
#===============================================================================
# Script de déploiement complet
# Ce script orchestre le déploiement de l'infrastructure et de l'application
#===============================================================================

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Répertoire du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Fonctions utilitaires
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."

    local missing=()

    command -v terraform >/dev/null 2>&1 || missing+=("terraform")
    command -v ansible >/dev/null 2>&1 || missing+=("ansible")
    command -v packer >/dev/null 2>&1 || missing+=("packer")

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Outils manquants: ${missing[*]}"
        exit 1
    fi

    log_success "Tous les prérequis sont installés"
}

# Construction des images Packer
build_images() {
    log_info "Construction des images Packer..."
    cd "${PROJECT_DIR}/packer"

    for image in web app db; do
        log_info "Construction de l'image ${image}..."
        packer build -var-file=variables.pkrvars.hcl ${image}.json
        log_success "Image ${image} construite avec succès"
    done

    cd "${PROJECT_DIR}"
}

# Provisionnement avec Terraform
provision_infrastructure() {
    log_info "Provisionnement de l'infrastructure avec Terraform..."
    cd "${PROJECT_DIR}/terraform"

    log_info "Initialisation de Terraform..."
    terraform init

    log_info "Planification des changements..."
    terraform plan -out=tfplan

    log_info "Application des changements..."
    terraform apply tfplan

    log_success "Infrastructure provisionnée avec succès"

    # Récupération des outputs
    terraform output -json > "${PROJECT_DIR}/terraform/outputs.json"

    cd "${PROJECT_DIR}"
}

# Configuration avec Ansible
configure_servers() {
    log_info "Configuration des serveurs avec Ansible..."
    cd "${PROJECT_DIR}/ansible"

    # Attente que les VMs soient accessibles
    log_info "Attente de la disponibilité des serveurs..."
    sleep 30

    # Ping des serveurs
    log_info "Test de connectivité..."
    ansible all -m ping

    # Exécution du playbook principal
    log_info "Exécution du playbook de configuration..."
    ansible-playbook playbooks/site.yml

    log_success "Serveurs configurés avec succès"

    cd "${PROJECT_DIR}"
}

# Déploiement de l'application
deploy_application() {
    log_info "Déploiement de l'application..."
    cd "${PROJECT_DIR}/ansible"

    ansible-playbook playbooks/deploy-app.yml

    log_success "Application déployée avec succès"

    cd "${PROJECT_DIR}"
}

# Vérification du déploiement
verify_deployment() {
    log_info "Vérification du déploiement..."

    # Récupération de l'IP du load balancer
    LB_IP=$(cd "${PROJECT_DIR}/terraform" && terraform output -raw load_balancer_ip)

    log_info "Test de l'endpoint de santé..."
    if curl -ks "https://${LB_IP}/api/health" | grep -q "healthy"; then
        log_success "L'application répond correctement"
    else
        log_warning "L'application ne répond pas comme attendu"
    fi

    log_info "URL de l'application: https://${LB_IP}"
}

# Affichage de l'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all              Déploiement complet (images + infra + config + app)"
    echo "  --images           Construction des images Packer uniquement"
    echo "  --infra            Provisionnement Terraform uniquement"
    echo "  --config           Configuration Ansible uniquement"
    echo "  --app              Déploiement de l'application uniquement"
    echo "  --verify           Vérification du déploiement"
    echo "  --help             Affiche cette aide"
}

# Point d'entrée principal
main() {
    echo "=========================================="
    echo "   DevOps Project - Script de déploiement"
    echo "=========================================="
    echo ""

    case "${1:-}" in
        --all)
            check_prerequisites
            build_images
            provision_infrastructure
            configure_servers
            deploy_application
            verify_deployment
            ;;
        --images)
            check_prerequisites
            build_images
            ;;
        --infra)
            check_prerequisites
            provision_infrastructure
            ;;
        --config)
            check_prerequisites
            configure_servers
            ;;
        --app)
            check_prerequisites
            deploy_application
            verify_deployment
            ;;
        --verify)
            verify_deployment
            ;;
        --help|"")
            show_help
            ;;
        *)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac

    echo ""
    log_success "Opération terminée!"
}

main "$@"
