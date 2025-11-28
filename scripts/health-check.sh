#!/bin/bash
#===============================================================================
# Script de vérification de santé de l'infrastructure
#===============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Récupération des IPs depuis Terraform
get_ips() {
    cd "${PROJECT_DIR}/terraform"
    LB_IP=$(terraform output -raw load_balancer_ip 2>/dev/null || echo "")
    WEB_IPS=$(terraform output -json web_servers_ips 2>/dev/null | tr -d '[]"' | tr ',' ' ' || echo "")
    APP_IPS=$(terraform output -json app_servers_ips 2>/dev/null | tr -d '[]"' | tr ',' ' ' || echo "")
    DB_MASTER_IP=$(terraform output -raw db_master_ip 2>/dev/null || echo "")
    DB_SLAVE_IP=$(terraform output -raw db_slave_ip 2>/dev/null || echo "")
    cd - > /dev/null
}

check_http() {
    local name=$1
    local url=$2
    local expected=${3:-200}

    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")

    if [ "$response" == "$expected" ]; then
        echo -e "  ${GREEN}✓${NC} $name: OK (HTTP $response)"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name: FAILED (HTTP $response)"
        return 1
    fi
}

check_ssh() {
    local name=$1
    local ip=$2

    if nc -z -w 5 "$ip" 22 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name ($ip): SSH OK"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name ($ip): SSH FAILED"
        return 1
    fi
}

check_port() {
    local name=$1
    local ip=$2
    local port=$3

    if nc -z -w 5 "$ip" "$port" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name ($ip:$port): OK"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name ($ip:$port): FAILED"
        return 1
    fi
}

echo "=========================================="
echo "   Health Check - Infrastructure DevOps"
echo "=========================================="
echo ""

get_ips

if [ -z "$LB_IP" ]; then
    echo -e "${RED}Impossible de récupérer les IPs. L'infrastructure est-elle déployée?${NC}"
    exit 1
fi

failed=0

echo "Load Balancer ($LB_IP):"
check_http "HTTPS" "https://$LB_IP" || ((failed++))
check_http "Health endpoint" "https://$LB_IP/api/health" || ((failed++))
check_ssh "SSH" "$LB_IP" || ((failed++))
echo ""

echo "Web Servers:"
for ip in $WEB_IPS; do
    check_http "HTTP" "http://$ip/health" || ((failed++))
    check_ssh "SSH" "$ip" || ((failed++))
done
echo ""

echo "App Servers:"
for ip in $APP_IPS; do
    check_port "App" "$ip" 3000 || ((failed++))
    check_ssh "SSH" "$ip" || ((failed++))
done
echo ""

echo "Database Servers:"
check_port "PostgreSQL Master" "$DB_MASTER_IP" 5432 || ((failed++))
check_ssh "SSH Master" "$DB_MASTER_IP" || ((failed++))
check_port "PostgreSQL Slave" "$DB_SLAVE_IP" 5432 || ((failed++))
check_ssh "SSH Slave" "$DB_SLAVE_IP" || ((failed++))
echo ""

echo "=========================================="
if [ $failed -eq 0 ]; then
    echo -e "${GREEN}Tous les checks sont passés!${NC}"
    exit 0
else
    echo -e "${RED}$failed check(s) en échec${NC}"
    exit 1
fi
