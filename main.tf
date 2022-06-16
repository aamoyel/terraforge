######################################## Requirements
terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.6.0"
    }
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.10"
    }
    phpipam = {
      source = "lord-kyron/phpipam"
      version = "1.2.12"
    }
    powerdns = {
      source = "pan-net/powerdns"
      version = "1.5.0"
    }
  }
}




######################################## Variables
variable "vault_address" {}
variable "vault_role_id" {}
variable "vault_secret_id" {}
variable "phpipam_app_id" {}
variable "phpipam_endpoint" {}
variable "phpipam_password" {}
variable "phpipam_username" {}
variable "proxmox_api_url" {}
variable "proxmox_api_token_id" {}
variable "proxmox_api_token_secret" {}
variable "powerdns_api_key" {}
variable "powerdns_server_url" {}




######################################## Providers configurations
provider "vault" {
  address = var.vault_address
  auth_login {
    path = "auth/approle/login"
    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}

provider "phpipam" {
  app_id   = var.phpipam_app_id
  endpoint = var.phpipam_endpoint
  password = var.phpipam_password
  username = var.phpipam_username
}

provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
}

provider "powerdns" {
  server_url = var.powerdns_server_url
  api_key = var.powerdns_api_key
}




######################################## Resources
# Gen root password for vm instance
resource "vault_generic_endpoint" "gen_passwd" {
  for_each = local.vm_instances
  path = "/gen/password"
  disable_read = true
  disable_delete = true
  ignore_absent_fields = true
  write_fields = ["value"]
  data_json = <<EOT
{
  "symbols": "0",
  "length": "18"
}
EOT
}
# Write password in Vault
resource "vault_generic_secret" "root_passwd" {
  for_each = local.vm_instances
  path = "vms/${each.key}"
  delete_all_versions = "true"
  data_json = <<EOT
{
  "root-password": "${vault_generic_endpoint.gen_passwd[each.key].write_data.value}"
}
EOT
}


# Get ID of phpIPAM section
data "phpipam_section" "section" {
  name = "Home"
}
# Get ID of the subnet
data "phpipam_subnet" "subnet" {
  for_each = local.vm_instances
  section_id = data.phpipam_section.section.id
  description = each.value.subnet
}
# Get the first available address and reserve it. Note that we use ignore_changes here to ensure that we don't end up re-allocating this address on future Terraform runs.
resource "phpipam_first_free_address" "new_ip" {
  for_each = local.vm_instances
  subnet_id = data.phpipam_subnet.subnet[each.key].subnet_id
  hostname = "${each.key}.${each.value.domain}"
  description = "Managed by Terraform"
  lifecycle {
    ignore_changes = [
      subnet_id,
    ]
  }
}
# Get the subnet gateway IP
data "phpipam_address" "gateway" {
  for_each = local.vm_instances
  address_id = data.phpipam_subnet.subnet[each.key].gateway_id
}


# Create vm on Proxmox
resource "proxmox_vm_qemu" "vm" {
  for_each          = local.vm_instances
  name              = each.key
  onboot            = true
  target_node       = "hyp-pve01"
  clone             = "tmpl-debian11"
  cores             = each.value.cores
  sockets           = each.value.sockets
  cpu               = "host"
  memory            = each.value.memory
  scsihw            = "virtio-scsi-pci"
  agent             = 1
  network {
    model           = "virtio"
    bridge          = each.value.network
  }
  disk {
    slot    = 0
    size    = "16G"
    storage = "VMFS2"
    type    = "scsi"
  }
  lifecycle {
    ignore_changes = [
      disk
    ]
  }

  # CloudInit config
  ciuser = "root"
  cipassword = "${vault_generic_endpoint.gen_passwd[each.key].write_data.value}"
  ipconfig0 = "ip=${resource.phpipam_first_free_address.new_ip[each.key].ip_address}/24,gw=${data.phpipam_address.gateway[each.key].ip_address}"
  connection {
    type        = "ssh"
    user        = "root"
    private_key = "${file("~/.ssh/id_rsa")}"
    host        = self.ssh_host
  }
  # Change hostname and DNS config
  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname ${each.key}.${each.value.domain}",
      "echo -n '    dns-nameservers 172.16.2.254\n    dns-search amoyel.loc' >> /etc/network/interfaces.d/50-cloud-init",
      "shutdown -r +0"
    ]
  }
}


# Add A record in PowerDNS
resource "powerdns_record" "vm_record" {
  for_each = local.vm_instances
  zone     = "${each.value.domain}."
  name     = "${each.key}.${each.value.domain}."
  type     = "A"
  ttl      = 300
  records  = ["${resource.phpipam_first_free_address.new_ip[each.key].ip_address}"]
}




######################################## VMs
locals {
  vm_instances = jsondecode(file("./vm-instances.json"))
}
