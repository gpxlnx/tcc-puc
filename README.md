# 💻 Provisionamento de VMs no Proxmox com Terraform

Este projeto usa [Terraform](https://www.terraform.io/) para automatizar a criação de máquinas virtuais (VMs) no ambiente Proxmox, com base em configurações definidas em um arquivo YAML (`vm_configs.yaml`).

---

## 📂 Estrutura do Projeto

```plaintext
.
├── provider.tf          # Define o provider do Proxmox
├── full-clone.tf        # Recurso principal que cria VMs clonadas
├── vm_configs.yaml      # Configurações das VMs (nome, CPU, memória, disco, etc.)
├── terraform.tfvars     # (Opcional) Valores das variáveis sensíveis
└── README.md            # Este arquivo
```

## ⚙️ Pré-requisitos

* Terraform >= 1.0
* Acesso a um ambiente Proxmox com:
    * Template de VM existente (ex: ubuntu-server-jammy)
    * API habilitada
    * Token de API com permissões adequadas (VM.Clone, VM.Allocate, etc.)

## 🔐 Variáveis Sensíveis

Crie um arquivo terraform.tfvars (ou credentials.auto.tfvars) com:

```bash
proxmox_api_url          = "https://<PROXMOX-IP>:8006/api2/json"
proxmox_api_token_id     = "root@pam!<token-id>"
proxmox_api_token_secret = "<seu-token-secret>"
proxmox_tls_insecure     = true
```

* Nunca suba arquivos .tfvars com credenciais no Git. Use um .gitignore.

## 🛠️ Como Usar

1. Clone este repositório:

```bash
git clone https://github.com/seuusuario/terraform-proxmox-vms.git
cd terraform-proxmox-vms
```

2. Edite o vm_configs.yaml com suas configurações de VMs.

3. Rodando checkov para hardening do código

```bash
checkov --directory terraform/
```

4. Inicialize o Terraform:

```bash
terraform init
```

5. Visualize o plano de execução:

```bash
terraform plan
```

6. Provisione as VMs:

```bash
terraform apply
```

## 📑 Exemplo de Configuração YAML


```bash
k3s-control-plane:
  description: "kubernetes control-plane"
  target_node: px01
  vmid: 201
  clone: "ubuntu-server-jammy"
  tags: "k8s,k8s-control-plane"
  ipconfig0: "ip=dhcp"
  resources:
    cpu: 2
    memory: 4096
    disk: 20G
```
