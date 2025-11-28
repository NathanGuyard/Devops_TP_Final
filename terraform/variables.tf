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
  default     = "alpine-web-template"
}

variable "app_template_name" {
  description = "Nom du template Packer pour les serveurs app"
  type        = string
  default     = "alpine-app-template"
}

variable "db_template_name" {
  description = "Nom du template Packer pour les serveurs database"
  type        = string
  default     = "alpine-db-template"
}

# ============================================================================
# VARIABLES VMS (Optimisé pour Alpine Linux)
# ============================================================================
variable "vm_cores" {
  description = "Nombre de CPU cores par VM"
  type        = number
  default     = 1
}

variable "vm_memory" {
  description = "RAM en MB par VM (512MB pour web/app, 1024MB pour db)"
  type        = number
  default     = 512
}

variable "vm_memory_db" {
  description = "RAM en MB pour les serveurs DB"
  type        = number
  default     = 1024
}

variable "vm_disk_size" {
  description = "Taille du disque par VM"
  type        = string
  default     = "2G"
}

variable "vm_disk_size_db" {
  description = "Taille du disque pour les serveurs DB"
  type        = string
  default     = "4G"
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
