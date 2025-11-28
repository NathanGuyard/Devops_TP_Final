# ============================================================================
# OUTPUTS - INFORMATIONS DE L'INFRASTRUCTURE
# ============================================================================

output "load_balancer_ip" {
  description = "Adresse IP du Load Balancer"
  value       = var.lb_ip
}

output "web_servers_ips" {
  description = "Adresses IP des serveurs Web"
  value       = var.web_ips
}

output "app_servers_ips" {
  description = "Adresses IP des serveurs App"
  value       = var.app_ips
}

output "db_master_ip" {
  description = "Adresse IP du serveur Database Master"
  value       = var.db_master_ip
}

output "db_slave_ip" {
  description = "Adresse IP du serveur Database Slave"
  value       = var.db_slave_ip
}

output "ssh_connection_lb" {
  description = "Commande SSH pour se connecter au Load Balancer"
  value       = "ssh ${var.ssh_user}@${var.lb_ip}"
}

output "ssh_connection_web" {
  description = "Commandes SSH pour se connecter aux serveurs Web"
  value       = [for ip in var.web_ips : "ssh ${var.ssh_user}@${ip}"]
}

output "ssh_connection_app" {
  description = "Commandes SSH pour se connecter aux serveurs App"
  value       = [for ip in var.app_ips : "ssh ${var.ssh_user}@${ip}"]
}

output "ssh_connection_db_master" {
  description = "Commande SSH pour se connecter au serveur DB Master"
  value       = "ssh ${var.ssh_user}@${var.db_master_ip}"
}

output "ssh_connection_db_slave" {
  description = "Commande SSH pour se connecter au serveur DB Slave"
  value       = "ssh ${var.ssh_user}@${var.db_slave_ip}"
}

output "application_url" {
  description = "URL de l'application"
  value       = "https://${var.lb_ip}"
}

output "total_vms" {
  description = "Nombre total de VMs déployées"
  value       = 7
}

output "infrastructure_summary" {
  description = "Résumé de l'infrastructure"
  value = {
    load_balancer   = 1
    web_servers     = 2
    app_servers     = 2
    database_master = 1
    database_slave  = 1
    total           = 7
  }
}
