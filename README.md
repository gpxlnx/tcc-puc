# Infraestrutura Automatizada com Packer, Terraform e Ansible

Este projeto tem como objetivo criar e gerenciar máquinas virtuais em um ambiente Proxmox, utilizando **Packer** para gerar imagens, **Terraform** para provisionamento e **Ansible** para executar varreduras e aplicar hardening no sistema operacional e aplicações.

---

## 🔧 Requisitos

- Proxmox VE com API habilitada
- Máquina com:
  - Packer instalado
  - Terraform >= 1.1.3
  - Ansible >= 2.10
  - Python 3 com módulos `requests` e `urllib3`
  - SSH configurado com chave privada para acesso às VMs

---

## 📁 Estrutura

```bash
tcc-puc/
├── packer/
│ ├── ubuntu20.json
│ ├── http/
│ │ ├── user-data
│ │ └── meta-data
├── terraform/
│ ├── main.tf
│ ├── variables.tf
│ ├── credentials.auto.tfvars
├── ansible/
│ ├── inventory_proxmox.py
│ ├── scan.yml
│ ├── install_vuln_apps.yml
│ ├── hardening.yml
│ └── README.md
```
## 🚀 Etapas de Execução

### 1. Criar a imagem com Packer

```bash
cd packer/
packer init
packer build ubuntu-server-jammy.pkr.hcl
```

### 2. Provisionar VMs com Terraform

```bash
cd terraform/
terraform init
terraform apply
```

Isso criará as VMs no Proxmox usando a imagem gerada anteriormente.

## ⚠️ Variáveis esperadas (via arquivo ou export):

```bash
# credentials.auto.tfvars
proxmox_api_url        = "https://<PROXMOX-IP>:8006/api2/json"
proxmox_api_token_id   = "root@pam!packer"
proxmox_api_token_secret = "<TOKEN_SECRET>"
proxmox_tls_insecure   = true
```

### 3. Rodar scan de segurança nas VMs (Ansible)
```bash
cd ansible/
ansible-playbook -i inventory_proxmox.py scan.yml
```
Executa o nmap e o linPEAS de dentro de cada VM e armazena os resultados localmente.

### 4. Instalar aplicações vulneráveis
```
ansible-playbook -i inventory_proxmox.py install_vuln_apps.yml
```

Simula falhas como:
* SSH com login root habilitado
* Serviço Telnet instalado
* Firewall desabilitado
* Aplicações desatualizadas

### 5. Aplicar Hardening (correções)
```bash
ansible-playbook -i inventory_proxmox.py hardening.yml
```

Corrige as falhas aplicando:
* Desabilita login root via SSH
* Remove pacotes inseguros (ex: telnet)
* Habilita e configura firewall (UFW)
* Define permissões de /tmp
* Atualiza pacotes do sistema

### 📌 Notas
O inventário inventory_proxmox.py é dinâmico e busca IPs via Proxmox API.

Logs de varreduras são salvos em ansible/scan_logs/.

Os playbooks assumem que a imagem criada com o Packer já está preparada com:

Chave SSH autorizada para o usuário

qemu-guest-agent instalado e ativo

## ✅ Exemplo de execução final
```bash
cd packer/
packer build ubuntu20.json

cd ../terraform/
terraform apply

cd ../ansible/
ansible-playbook -i inventory_proxmox.py scan.yml
ansible-playbook -i inventory_proxmox.py install_vuln_apps.yml
ansible-playbook -i inventory_proxmox.py hardening.yml
```
