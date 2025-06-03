# Ubuntu Server Template for Proxmox (Packer HCL2)
# -------------------------------------------------
# Builds an Ubuntu Server 22.04 LTS (Jammy) image on a Proxmox node
# using the **proxmox‑iso** builder, autoinstall (cloud‑init) and **zero interação**.

# ────────────────────────────────────────────────────────────────────────────────
# Variables (fill via credentials.pkr.hcl)
# ────────────────────────────────────────────────────────────────────────────────
variable "proxmox_api_url"          { type = string }
variable "proxmox_api_token_id"     { type = string }
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

# ────────────────────────────────────────────────────────────────────────────────
# Plugin requirement
# ────────────────────────────────────────────────────────────────────────────────
packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.2.0"
    }
  }
}
# ────────────────────────────────────────────────────────────────────────────────
# Builder: proxmox‑iso (modern syntax)
# ────────────────────────────────────────────────────────────────────────────────
source "proxmox-iso" "ubuntu-server-jammy" {
  # Proxmox API creds
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  # Target node / template meta
  node                 = "pmx01"
  vm_id                = 901
  vm_name              = "ubuntu-server-jammy"
  template_description = "Ubuntu 22.04 LTS – autoinstall & cloud‑init"

  # Hardware
  qemu_agent      = true
  scsi_controller = "virtio-scsi-pci"

  disks {
    type         = "virtio"
    storage_pool = "rbd"
    disk_size    = "20G"
  }

  cores  = 2
  memory = 2048

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr615"
    firewall = false
  }

  # Cloud‑Init integration
  cloud_init              = true
  cloud_init_storage_pool = "rbd"

  # ISO download + storage (no interação manual)
  boot_iso {
    iso_url          = "https://releases.ubuntu.com/releases/jammy/ubuntu-22.04.5-live-server-amd64.iso"
    iso_checksum     = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"
    iso_storage_pool = "cephfs"
  }

  # Boot automation para GRUB do live‑server
  boot_wait         = "5s"
  boot_key_interval = "500ms"
  boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"                  # boot
  ]

  # Packer HTTP server para user-data/meta-data
  http_directory = "http"  # coloque seus cloud‑init files aqui

  # SSH para provisão
  ssh_username         = "automation"
  ssh_private_key_file = "~/.ssh/packer_key"
  ssh_timeout          = "60m"
}

# ────────────────────────────────────────────────────────────────────────────────
# Build & Provision
# ────────────────────────────────────────────────────────────────────────────────
build {
  name    = "ubuntu-server-jammy"
  sources = ["source.proxmox-iso.ubuntu-server-jammy"]

  # Espera cloud-init e faz cleanup
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud‑init…'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  # Tweaks Proxmox cloud‑init
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"
    ]
  }
}
