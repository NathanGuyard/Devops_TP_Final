# ============================================================================
# VARIABLES PROXMOX
# ============================================================================
variable "proxmox_api_url" {
  description = "URL de l'API Proxmox"
  type        = string
  default     = "https://proxmox.local:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "Token ID pour l'API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Token Secret pour l'API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nom du node Proxmox"
  type        = string
  default     = "pve"
}

# ============================================================================
# VARIABLES TEMPLATES
# ============================================================================
variable "web_template_name" {
  description = "Nom du template Packer pour les serveurs web"
  type        = string
  default     = "web-server-template"
}

variable "app_template_name" {
  description = "Nom du template Packer pour les serveurs app"
  type        = string
  default     = "app-server-template"
}

variable "db_template_name" {
  description = "Nom du template Packer pour les serveurs database"
  type        = string
  default     = "db-server-template"
}

# ============================================================================
# VARIABLES VMS
# ============================================================================
variable "vm_cores" {
  description = "Nombre de CPU cores par VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "RAM en MB par VM"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Taille du disque par VM"
  type        = string
  default     = "20G"
}

variable "storage_pool" {
  description = "Pool de stockage Proxmox"
  type        = string
  default     = "local-lvm"
}

# ============================================================================
# VARIABLES RÉSEAU
# ============================================================================
variable "network_bridge" {
  description = "Bridge réseau Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Passerelle par défaut"
  type        = string
  default     = "192.168.1.1"
}

variable "lb_ip" {
  description = "Adresse IP du Load Balancer"
  type        = string
  default     = "192.168.1.10"
}

variable "web_ips" {
  description = "Adresses IP des serveurs Web"
  type        = list(string)
  default     = ["192.168.1.11", "192.168.1.12"]
}

variable "app_ips" {
  description = "Adresses IP des serveurs App"
  type        = list(string)
  default     = ["192.168.1.21", "192.168.1.22"]
}

variable "db_master_ip" {
  description = "Adresse IP du serveur Database Master"
  type        = string
  default     = "192.168.1.31"
}

variable "db_slave_ip" {
  description = "Adresse IP du serveur Database Slave"
  type        = string
  default     = "192.168.1.32"
}

# ============================================================================
# VARIABLES SSH
# ============================================================================
variable "ssh_user" {
  description = "Utilisateur SSH pour les VMs"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "Clé publique SSH"
  type        = string
  default     = ""
}
