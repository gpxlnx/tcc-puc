# 🔍 Auditoria de VMs no Proxmox com Ansible

Este projeto realiza auditoria de segurança em VMs virtualizadas no Proxmox usando **Ansible** com **inventário dinâmico via API**, executando os seguintes testes em cada VM:

- ⚙️ Varredura de vulnerabilidades com `nmap --script vuln`
- 📋 Enumeração de segurança local com `linPEAS`
- 📥 Armazenamento dos logs localmente no host que roda o Ansible

---

## 📦 Requisitos

- Python 3 com `requests`
- Acesso SSH com chave para as VMs
- QEMU Guest Agent habilitado nas VMs
- Ansible 2.9+

---

## 🔧 Instalação

Clone este repositório e torne o script executável:

```bash
git clone https://github.com/seuusuario/proxmox-auditor.git
cd proxmox-auditor
chmod +x inventory_proxmox.py
```

## ⚙️ Variáveis de ambiente necessárias
Antes de executar, exporte as seguintes variáveis para que o inventário dinâmico consiga se autenticar na API do Proxmox:

```bash
export PROXMOX_API_URL='https://<IP-DO-PROXMOX>:8006/api2/json'
export PROXMOX_API_TOKEN_ID='root@pam!packer'
export PROXMOX_API_TOKEN_SECRET='SEU_TOKEN'
export PROXMOX_NODE='px01'  # nome do nó onde as VMs estão rodando
```

## 🚀 Executando o playbook
Rode o seguinte comando para iniciar a varredura nas VMs:

```bash
ansible-playbook -i ./inventory_proxmox.py scan.yml
```

## 📂 Saída dos logs
Os resultados da auditoria são salvos localmente em:

```bash
/tmp/scan_logs/
├── linpeas_k3s-control-plane.log
├── linpeas_k3s-worker-node-01.log
├── linpeas_k3s-worker-node-02.log
├── nmap_k3s-control-plane.txt
├── nmap_k3s-worker-node-01.txt
├── nmap_k3s-worker-node-02.txt
```

## 🛠 Estrutura dos arquivos

```bash
.
├── inventory_proxmox.py   # Script de inventário dinâmico Proxmox
├── scan.yml               # Playbook Ansible que roda nmap e linPEAS
├── README.md              # Este guia
└── .env                   # (Opcional) Variáveis de ambiente com token e URL
```

```bash
📌 Observações
O inventário é construído dinamicamente com base nas VMs encontradas via API.

As VMs precisam ter IP visível pelo QEMU Agent (agent = 1 no Terraform ou ativado via GUI).

A chave SSH usada deve já estar autorizada nas VMs (~/.ssh/packer_key).
```
