#!/usr/bin/env python3

import requests
import json
import os
import sys
import urllib3

# Suprimir warnings de certificado TLS self-signed
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Variáveis de ambiente ou padrão
PROXMOX_API_URL = os.getenv("PROXMOX_API_URL", "https://192.168.1.21:8006/api2/json")
API_TOKEN_ID = os.getenv("PROXMOX_API_TOKEN_ID", "root@pam!packer")
API_TOKEN_SECRET = os.getenv("PROXMOX_API_TOKEN_SECRET", "SEU_TOKEN")
PROXMOX_NODE = os.getenv("PROXMOX_NODE", "px01")

HEADERS = {
    "Authorization": f"PVEAPIToken {API_TOKEN_ID}={API_TOKEN_SECRET}"
}
VERIFY_TLS = False

def get_vms():
    url = f"{PROXMOX_API_URL}/nodes/{PROXMOX_NODE}/qemu"
    try:
        response = requests.get(url, headers=HEADERS, verify=VERIFY_TLS)
        return response.json().get('data', [])
    except Exception:
        return []

def get_vm_ip(vmid):
    url = f"{PROXMOX_API_URL}/nodes/{PROXMOX_NODE}/qemu/{vmid}/agent/network-get-interfaces"
    try:
        response = requests.get(url, headers=HEADERS, verify=VERIFY_TLS)
        interfaces = response.json().get('data', {}).get('result', [])
        for iface in interfaces:
            for addr in iface.get("ip-addresses", []):
                if addr.get("ip-address-type") == "ipv4" and not addr["ip-address"].startswith("127."):
                    return addr["ip-address"]
    except Exception:
        pass
    return None

def generate_inventory():
    inventory = {
        "all": {
            "hosts": [],
            "vars": {
                "ansible_user": "automation",
                "ansible_ssh_private_key_file": os.path.expanduser("~/.ssh/packer_key")
            }
        }
    }
    hostvars = {}

    vms = get_vms()
    for vm in vms:
        vmid = vm.get("vmid")
        name = vm.get("name")
        if not vmid or not name:
            continue

        ip = get_vm_ip(vmid)
        if ip:
            inventory["all"]["hosts"].append(name)
            hostvars[name] = {
                "ansible_host": ip
            }

    inventory["_meta"] = {"hostvars": hostvars}
    return inventory

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        print(json.dumps(generate_inventory(), indent=2))
    else:
        print(json.dumps({}))

