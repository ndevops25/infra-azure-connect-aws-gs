# XPTO Corp - Infraestrutura Multi-Cloud Modular

[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-623CE4?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![AWS](https://img.shields.io/badge/AWS-FF9900?logo=amazon-aws)](https://aws.amazon.com)

Este projeto implementa uma arquitetura híbrida entre Microsoft Azure e Amazon Web Services (AWS) usando uma estrutura modular do Terraform, demonstrando conectividade segura e compartilhamento de recursos entre as duas plataformas cloud.

## 📋 Visão Geral

O projeto utiliza uma **arquitetura modular avançada** que conecta duas redes virtuais (Azure VNET e AWS VPC) através de uma VPN Site-to-Site opcional, permitindo comunicação segura entre recursos hospedados em ambas as nuvens com **controle total de custos**.

<img src="/docs/diagram/arquitecture.png" alt="Diagram">

### 🎯 Objetivos Cumpridos

- ✅ **Duas VNETs no Azure** (Hub e Spoke) com peering automático
- ✅ **Comunicação entre VNETs** através de peering bidirecional
- ✅ **Infraestrutura AWS** com VPC e instância EC2
- ✅ **VPN Site-to-Site opcional** entre Azure e AWS
- ✅ **DNS Privado** com zonas configuráveis
- ✅ **Estrutura modular** reutilizável e escalável
- ✅ **Controle de custos** com features toggleáveis
- ✅ **Azure Firewall opcional** com políticas avançadas
- ✅ **Scripts de automação** para deploy e testes

## 🏗️ Estrutura do Projeto

```
terraform/multicloud/
├── 📄 README.md                    # Esta documentação
├── 🔧 main.tf                      # Orquestração principal
├── 📋 variables.tf                 # Variáveis globais
├── 📤 outputs.tf                   # Outputs principais
├── 🔗 providers.tf                 # Configuração de providers
├── 📝 terraform.tfvars             # Configurações específicas
├── 📝 terraform.tfvars.student     # Exemplo econômico
├── 🚫 .gitignore                   # Arquivos a ignorar
├── 📁 docs/                        # Documentação adicional
├── 📁 environments/                # Configurações por ambiente
│   ├── 📁 dev/
│   ├── 📁 staging/
│   └── 📁 prod/
├── 📁 modules/                     # 🎯 MÓDULOS PRINCIPAIS
│   ├── 📁 azure-networking/        # Redes Azure (VNETs, Subnets, Peering)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── 📁 azure-compute/           # VMs Azure
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── scripts/
│   │       └── init.sh
│   ├── 📁 azure-security/          # Firewall, NSGs, Políticas
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── 📁 aws-networking/          # VPC, Subnets, IGW
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── 📁 aws-compute/             # EC2, Security Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── scripts/
│   │       └── init.sh
│   ├── 📁 vpn-connection/          # VPN Site-to-Site
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── 📁 dns-private/             # DNS Zones privadas
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── 📁 scripts/                     # Automação
│   ├── deploy-simple.sh            # Deploy automatizado
│   ├── test-connectivity.sh        # Testes de conectividade
│   └── cleanup.sh                  # Limpeza de recursos
└── 📁 tests/                       # Testes automatizados
    ├── 📁 integration/
    └── 📁 unit/
```

## 🎯 Módulos Implementados

### 🔷 **azure-networking**
**Responsabilidade**: Infraestrutura de rede Azure
- VNET Hub e Spoke com peering automático
- Subnets configuráveis (aplicação, gateway, firewall)
- Route Tables e NSGs opcionais
- Suporte a múltiplos ambientes

### 🔷 **azure-compute**
**Responsabilidade**: Recursos computacionais Azure
- VMs Linux com configuração flexível
- Network Interfaces com IP público opcional
- NSGs específicos por VM
- Scripts de inicialização automática

### 🔷 **azure-security**
**Responsabilidade**: Segurança e proteção Azure
- Azure Firewall com políticas avançadas
- Network Watcher para diagnósticos
- Application Security Groups
- Azure Bastion opcional
- DDoS Protection opcional

### 🔶 **aws-networking**
**Responsabilidade**: Infraestrutura de rede AWS
- VPC com subnets públicas/privadas
- Internet Gateway e Route Tables
- VPN Gateway opcional
- Suporte a múltiplas AZs

### 🔶 **aws-compute**
**Responsabilidade**: Recursos computacionais AWS
- Instâncias EC2 com Auto Scaling opcional
- Security Groups configuráveis
- Elastic IPs e Load Balancers
- Scripts de inicialização CloudInit

### 🔗 **vpn-connection**
**Responsabilidade**: Conectividade inter-cloud
- VPN Site-to-Site IPsec
- Customer Gateways e conexões
- Roteamento automático entre clouds
- Túneis redundantes opcionais

### 🌐 **dns-private**
**Responsabilidade**: Resolução DNS privada
- Zonas DNS privadas Azure e AWS
- Registros automáticos para VMs
- Resolução cross-cloud
- Configuração de forwarders

## 🚀 Guia de Implementação

### Pré-requisitos

```bash
# Verificar ferramentas necessárias
terraform --version  # >= 1.0
az --version         # Azure CLI
aws --version        # AWS CLI v2
ssh-keygen          # Para gerar chaves SSH
```

### Passo 1: Configuração Inicial

```bash
# 1. Clonar/criar projeto
git clone <repository> # ou mkdir terraform-multicloud
cd terraform-multicloud

# 2. Configurar credenciais
az login
aws configure

# 3. Gerar chaves SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/xpto-corp-key

# 4. Criar Key Pair na AWS
aws ec2 create-key-pair --key-name xpto-corp-keypair \
    --query 'KeyMaterial' --output text > xpto-corp-keypair.pem
chmod 400 xpto-corp-keypair.pem
```

### Passo 2: Configuração de Variáveis

Copie e edite o arquivo de configuração:

```bash
cp terraform.tfvars.student terraform.tfvars
```

**Configuração Econômica (Recomendada):**
```hcl
# terraform.tfvars - Configuração econômica
project_name = "xpto-corp"
environment  = "dev"

# Regiões próximas para menor latência
azure_location = "Brazil South"
aws_region     = "sa-east-1"

# VMs mínimas para economia
azure_vm_size     = "Standard_B1s"    # ~$8/mês
aws_instance_type = "t3.micro"        # Free tier

# SSH
ssh_public_key_path = "~/.ssh/xpto-corp-key.pub"
aws_key_pair_name   = "xpto-corp-keypair"

# 💰 CONTROLE DE CUSTOS
enable_vpn_connection = false  # Economiza $178/mês
enable_aws_dns       = true   # Baixo custo
enable_firewall      = false  # Economiza $544/mês
enable_bastion       = false  # Economiza $140/mês

# DNS
private_dns_zone_name = "xpto.local"
```

**Configuração Completa (Produção):**
```hcl
# terraform.tfvars - Configuração completa
project_name = "xpto-corp"
environment  = "prod"

# VMs robustas
azure_vm_size     = "Standard_D2s_v3"
aws_instance_type = "t3.medium"

# 🔒 SEGURANÇA MÁXIMA
enable_vpn_connection = true
enable_firewall      = true
enable_bastion       = true
enable_ddos_protection = true

# Features avançadas
firewall_sku                    = "Premium"
threat_intelligence_mode        = "Deny"
intrusion_detection_mode        = "Deny"
enable_flow_logs               = true
enable_traffic_analytics       = true
create_application_security_groups = true
```

### Passo 3: Deploy

```bash
# Deploy automatizado (recomendado)
./scripts/deploy-simple.sh plan    # Visualizar plano
./scripts/deploy-simple.sh apply   # Aplicar mudanças

# Deploy manual
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Passo 4: Verificação e Testes

```bash
# Obter informações de conectividade
terraform output connection_commands

# Executar testes automatizados
./scripts/test-connectivity.sh

# Verificar custos estimados
terraform output cost_information
```

## 💰 Análise de Custos

### 📊 Cenários de Custo

| Cenário | Descrição | Custo Mensal (USD) |
|---------|-----------|-------------------|
| **💚 Econômico** | VMs básicas, sem VPN/Firewall | ~$25 |
| **💛 Intermediário** | VMs médias + VPN | ~$203 |
| **💙 Avançado** | VMs robustas + VPN + Firewall | ~$747 |
| **💜 Enterprise** | Completo + DDoS + Bastion | ~$3,831 |

### 📈 Breakdown de Custos

#### 💚 Configuração Econômica (~$25/mês)
```
Azure:
├── VM Standard_B1s        $8.00
├── Public IP Basic        $3.00
└── DNS Private Zone       $0.50
                          ------
                          $11.50

AWS:
├── EC2 t3.micro          $9.00*
├── Elastic IP            $4.00
└── Route53 Private       $0.50
                          ------
                          $13.50

Total: $25.00/mês
*Elegível para AWS Free Tier
```

#### 💙 Configuração Avançada (~$747/mês)
```
Econômica                 $25.00
+ Azure VPN Gateway       $142.00
+ AWS VPN Gateway         $36.00
+ Azure Firewall          $544.00
                          -------
Total: $747.00/mês
```

### 🎛️ Controles de Custo

**Features Toggleáveis:**
```hcl
# Economizar dinheiro
enable_vpn_connection = false  # -$178/mês
enable_firewall      = false  # -$544/mês
enable_bastion       = false  # -$140/mês
enable_ddos_protection = false # -$2,944/mês

# Features gratuitas/baratas
enable_aws_dns           = true   # $0.50/mês
enable_network_watcher   = true   # Grátis
enable_flow_logs         = false  # $5/mês se habilitado
```

## 🔧 Configurações Detalhadas

### Endereçamento de Rede

```
🔷 Azure Networks:
├── Hub VNET:      10.1.0.0/16
│   ├── Hub Subnet:     10.1.1.0/24
│   ├── Gateway Subnet: 10.1.3.0/27
│   └── Firewall Subnet: 10.1.4.0/26
└── Spoke VNET:    10.1.10.0/24
    └── Spoke Subnet:   10.1.10.0/25

🔶 AWS Networks:
└── VPC:           10.2.0.0/16
    └── Public Subnet:  10.2.1.0/24
```

### Conectividade

```
🔗 Conexões:
├── Azure Hub ↔ Spoke:    VNET Peering
├── Azure ↔ AWS:         VPN Site-to-Site (opcional)
├── DNS Resolution:       Cross-cloud via zonas privadas
└── Security:            NSGs + Security Groups + Firewall
```

### Portas e Protocolos

**Azure NSGs:**
- SSH (22/tcp): Acesso administrativo
- ICMP: Testes de conectividade
- HTTP/HTTPS (80,443/tcp): Aplicações web

**AWS Security Groups:**
- SSH (22/tcp): De qualquer lugar
- ICMP: Apenas do Azure (10.1.0.0/16)
- HTTP/HTTPS: Apenas do Azure

**Azure Firewall (se habilitado):**
- Allow Azure ↔ AWS: Todos os protocolos
- Allow Internet: HTTP/HTTPS/DNS/NTP
- DNAT Rules: Port forwarding customizável

## 🧪 Testes e Validação

### Testes Automatizados

```bash
# Script de teste completo
./scripts/test-connectivity.sh

# Testes incluem:
# ✅ Verificação de recursos Azure
# ✅ Verificação de recursos AWS  
# ✅ Status da VPN (se habilitada)
# ✅ Resolução DNS
# ✅ Conectividade entre clouds
# ✅ Acesso SSH
```

### Testes Manuais

```bash
# 1. SSH nas instâncias
ssh ubuntu@$(terraform output -raw aws_ec2_public_ip)
ssh azureuser@<AZURE_VM_IP>

# 2. Teste de ping entre clouds
# Do Azure para AWS:
ping $(terraform output -raw aws_ec2_private_ip)

# Da AWS para Azure:
ping $(terraform output -raw azure_vm_private_ip)

# 3. Teste DNS
nslookup vm-azure.xpto.local
nslookup ec2-aws.aws.xpto.local

# 4. Verificar rotas
ip route show | grep 10.
```

### Métricas de Sucesso

- **Latência**: < 50ms entre clouds (mesma região)
- **Throughput**: Conforme SKU do VPN Gateway
- **Disponibilidade**: > 99.5% uptime
- **DNS Resolution**: < 100ms
- **Conectividade**: 100% dos testes passando

## 🔒 Segurança

### Implementações de Segurança

#### Camada de Rede
- **VPN IPsec**: Criptografia em trânsito
- **Private Networks**: Sem exposição desnecessária
- **Firewall Rules**: Políticas restritivas
- **NSGs/Security Groups**: Controle granular

#### Camada de Aplicação  
- **SSH Keys**: Autenticação por chave
- **DNS Privado**: Resolução apenas interna
- **Application Security Groups**: Segmentação de aplicações
- **Bastion Host**: Acesso seguro (opcional)

#### Camada de Monitoramento
- **Network Watcher**: Diagnósticos de rede
- **Flow Logs**: Análise de tráfego
- **Traffic Analytics**: Insights de segurança
- **Threat Intelligence**: Proteção contra ameaças

### Configurações de Segurança por Ambiente

**Desenvolvimento:**
```hcl
# Permissivo para facilitar desenvolvimento
allowed_ssh_cidrs = ["0.0.0.0/0"]
enable_firewall   = false
threat_intelligence_mode = "Alert"
```

**Produção:**
```hcl
# Restritivo para máxima segurança
allowed_ssh_cidrs = ["192.168.1.0/24"]  # Apenas rede corporativa
enable_firewall   = true
firewall_sku     = "Premium"
threat_intelligence_mode = "Deny"
intrusion_detection_mode = "Deny"
enable_ddos_protection   = true
```

## 🔄 Operações

### Comandos Frequentes

```bash
# Verificar status geral
terraform output infrastructure_status

# Parar VMs para economizar (desenvolvimento)
az vm deallocate --resource-group $(terraform output -raw resource_group_name) --name vm-spoke-dev
aws ec2 stop-instances --instance-ids $(terraform output -raw aws_ec2_instance_id)

# Religar VMs
az vm start --resource-group $(terraform output -raw resource_group_name) --name vm-spoke-dev  
aws ec2 start-instances --instance-ids $(terraform output -raw aws_ec2_instance_id)

# Atualizar infraestrutura
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"

# Destruir completamente (CUIDADO!)
terraform destroy -var-file="terraform.tfvars"
```

### Monitoramento

```bash
# Status da VPN Azure
az network vpn-connection list --resource-group $(terraform output -raw resource_group_name)

# Status da VPN AWS  
aws ec2 describe-vpn-connections --vpn-connection-ids $(terraform output -raw vpn_connection_id)

# Logs das VMs
# Azure: SSH e verificar /var/log/
# AWS: SSH e verificar /var/log/cloud-init.log
```

## 📚 Documentação dos Módulos

Cada módulo possui documentação detalhada:

- [📖 azure-networking/README.md](modules/azure-networking/README.md)
- [📖 azure-compute/README.md](modules/azure-compute/README.md)  
- [📖 azure-security/README.md](modules/azure-security/README.md)
- [📖 aws-networking/README.md](modules/aws-networking/README.md)
- [📖 aws-compute/README.md](modules/aws-compute/README.md)
- [📖 vpn-connection/README.md](modules/vpn-connection/README.md)
- [📖 dns-private/README.md](modules/dns-private/README.md)

## 🚨 Troubleshooting

### Problemas Comuns

**❌ VPN não conecta**
```bash
# Verificar status dos gateways
az network vnet-gateway show --name vpngw-xpto-corp-dev --resource-group rg-xpto-corp-dev
aws ec2 describe-vpn-gateways

# Verificar configuração
terraform output vpn_connection_status
```

**❌ DNS não resolve**
```bash
# Verificar zonas DNS
az network private-dns zone list --resource-group rg-xpto-corp-dev
aws route53 list-hosted-zones

# Testar resolução
nslookup vm-azure.xpto.local
dig ec2-aws.aws.xpto.local
```

**❌ Conectividade falha**
```bash
# Verificar security groups/NSGs
terraform output security_status

# Testar conectividade básica
telnet <IP> <PORT>
nc -zv <IP> <PORT>
```

**❌ Custos altos**
```bash
# Verificar recursos caros
terraform output cost_information

# Desabilitar features caras
# No terraform.tfvars:
enable_vpn_connection = false
enable_firewall = false
```

### Logs Importantes

```bash
# Terraform
export TF_LOG=DEBUG
terraform apply

# Azure
az monitor activity-log list --resource-group rg-xpto-corp-dev

# AWS
aws logs describe-log-groups
aws ec2 describe-flow-logs
```

## 🎯 Próximos Passos

### Melhorias Sugeridas

1. **CI/CD Pipeline**
   ```yaml
   # .github/workflows/terraform.yml
   name: Terraform CI/CD
   on: [push, pull_request]
   jobs:
     terraform:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: hashicorp/setup-terraform@v2
         - run: terraform init
         - run: terraform plan
   ```

2. **Monitoring Avançado**
   ```hcl
   # Adicionar ao main.tf
   module "monitoring" {
     source = "./modules/monitoring"
     
     enable_application_insights = true
     enable_cloudwatch_dashboards = true
     alert_email = "admin@xpto-corp.com"
   }
   ```

3. **Backup Automático**
   ```hcl
   module "backup" {
     source = "./modules/backup"
     
     vm_ids = [module.azure_compute.vm_id]
     ec2_instance_ids = [module.aws_compute.instance_id]
     backup_schedule = "0 2 * * *"  # Daily 2 AM
   }
   ```

4. **Load Balancing**
   ```hcl
   module "load_balancing" {
     source = "./modules/load-balancing"
     
     enable_azure_lb = true
     enable_aws_alb = true
     health_check_path = "/health"
   }
   ```

### Expansão da Arquitetura

- **Multi-região**: Replicar em outras regiões para DR
- **Containerização**: Adicionar AKS e EKS
- **Serverless**: Integrar Azure Functions e AWS Lambda
- **Data Services**: Adicionar bancos de dados e storage
- **Edge Computing**: Implementar CDN e edge locations

## 🤝 Contribuições

### Como Contribuir

1. **Fork** o repositório
2. **Clone** localmente: `git clone <fork-url>`
3. **Crie branch**: `git checkout -b feature/nova-feature`
4. **Desenvolva** seguindo os padrões estabelecidos
5. **Teste** em ambiente de desenvolvimento
6. **Commit**: `git commit -m "feat: adiciona nova feature"`
7. **Push**: `git push origin feature/nova-feature`
8. **Pull Request** com descrição detalhada

### Padrões de Desenvolvimento

```hcl
# Nomenclatura de recursos
resource "azurerm_resource" "name" {
  name = "${var.resource_type}-${var.project_name}-${var.environment}"
}

# Variáveis sempre com descrição
variable "example_var" {
  description = "Descrição clara do propósito"
  type        = string
  default     = "valor-padrao"
}

# Outputs sempre com descrição
output "example_output" {
  description = "Descrição do que retorna"
  value       = resource.example.id
}
```

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📞 Suporte

- **📖 Documentação**: Este README e módulos individuais
- **🐛 Issues**: [GitHub Issues](https://github.com/seu-repo/issues)
- **💬 Discussões**: [GitHub Discussions](https://github.com/seu-repo/discussions)
- **📧 Email**: suporte@xpto-corp.com

---

## 🏆 Resultados Esperados

Após implementar este projeto, você terá:

✅ **Infraestrutura Multi-Cloud** profissional e escalável  
✅ **Conectividade Híbrida** entre Azure e AWS  
✅ **Estrutura Modular** reutilizável para outros projetos  
✅ **Controle de Custos** flexível e transparente  
✅ **Automação Completa** com scripts e validações  
✅ **Segurança Enterprise** com múltiplas camadas  
✅ **Documentação Profissional** para manutenção  

**Este projeto demonstra domínio avançado em infraestrutura como código e arquitetura multi-cloud! 🚀**

---

*Desenvolvido com ❤️ para demonstrar as melhores práticas em infraestrutura multi-cloud e Terraform modular.*