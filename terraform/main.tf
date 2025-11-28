terraform {
  required_version = ">= 1.0.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

# ============================================================================
# LOAD BALANCER (1 VM)
# ============================================================================
resource "proxmox_vm_qemu" "load_balancer" {
  name        = "lb-01"
  desc        = "Load Balancer Nginx"
  target_node = var.proxmox_node
  clone       = var.web_template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.vm_cores
  sockets     = 1
  memory      = var.vm_memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot    = 0
    size    = var.vm_disk_size
    type    = "scsi"
    storage = var.storage_pool
  }

  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  ipconfig0 = "ip=${var.lb_ip}/24,gw=${var.gateway}"

  ciuser     = var.ssh_user
  sshkeys    = var.ssh_public_key

  tags = "load-balancer,nginx,production"

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# ============================================================================
# WEB SERVERS (2 VMs)
# ============================================================================
resource "proxmox_vm_qemu" "web_servers" {
  count       = 2
  name        = "web-${format("%02d", count.index + 1)}"
  desc        = "Web Server Nginx ${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.web_template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.vm_cores
  sockets     = 1
  memory      = var.vm_memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot    = 0
    size    = var.vm_disk_size
    type    = "scsi"
    storage = var.storage_pool
  }

  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  ipconfig0 = "ip=${var.web_ips[count.index]}/24,gw=${var.gateway}"

  ciuser     = var.ssh_user
  sshkeys    = var.ssh_public_key

  tags = "web-server,nginx,production"

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# ============================================================================
# APP SERVERS (2 VMs)
# ============================================================================
resource "proxmox_vm_qemu" "app_servers" {
  count       = 2
  name        = "app-${format("%02d", count.index + 1)}"
  desc        = "App Server Python ${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.app_template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.vm_cores
  sockets     = 1
  memory      = var.vm_memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot    = 0
    size    = var.vm_disk_size
    type    = "scsi"
    storage = var.storage_pool
  }

  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  ipconfig0 = "ip=${var.app_ips[count.index]}/24,gw=${var.gateway}"

  ciuser     = var.ssh_user
  sshkeys    = var.ssh_public_key

  tags = "app-server,python,production"

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# ============================================================================
# DATABASE SERVERS (2 VMs - Master + Slave)
# ============================================================================
resource "proxmox_vm_qemu" "db_master" {
  name        = "db-master"
  desc        = "Database Server PostgreSQL Master"
  target_node = var.proxmox_node
  clone       = var.db_template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.vm_cores
  sockets     = 1
  memory      = var.vm_memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot    = 0
    size    = var.vm_disk_size
    type    = "scsi"
    storage = var.storage_pool
  }

  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  ipconfig0 = "ip=${var.db_master_ip}/24,gw=${var.gateway}"

  ciuser     = var.ssh_user
  sshkeys    = var.ssh_public_key

  tags = "db-server,postgresql,master,production"

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

resource "proxmox_vm_qemu" "db_slave" {
  name        = "db-slave"
  desc        = "Database Server PostgreSQL Slave"
  target_node = var.proxmox_node
  clone       = var.db_template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.vm_cores
  sockets     = 1
  memory      = var.vm_memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot    = 0
    size    = var.vm_disk_size
    type    = "scsi"
    storage = var.storage_pool
  }

  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  ipconfig0 = "ip=${var.db_slave_ip}/24,gw=${var.gateway}"

  ciuser     = var.ssh_user
  sshkeys    = var.ssh_public_key

  tags = "db-server,postgresql,slave,production"

  depends_on = [proxmox_vm_qemu.db_master]

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# ============================================================================
# GÉNÉRATION DE L'INVENTAIRE ANSIBLE
# ============================================================================
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    lb_ip        = var.lb_ip
    web_ips      = var.web_ips
    app_ips      = var.app_ips
    db_master_ip = var.db_master_ip
    db_slave_ip  = var.db_slave_ip
    ssh_user     = var.ssh_user
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"

  depends_on = [
    proxmox_vm_qemu.load_balancer,
    proxmox_vm_qemu.web_servers,
    proxmox_vm_qemu.app_servers,
    proxmox_vm_qemu.db_master,
    proxmox_vm_qemu.db_slave
  ]
}
