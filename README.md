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

Serviço de Monitoramento de Microserviços - Checkpoint 3
========================================================

Este documento contém as explicações e os comandos necessários para implementar o serviço de monitoramento centralizado para a plataforma de e-commerce com microserviços.

Visão Geral
-----------

O serviço de monitoramento (`status-service`) é responsável por verificar a saúde de todos os microserviços da plataforma e consolidar os resultados em um único endpoint. Ele:

-   Faz consultas a cada microserviço através de seus endpoints `/health`
-   Expõe uma API `/health` que retorna o status consolidado do sistema
-   Roda como um container Docker leve, seguro e otimizado
-   Usa Docker Networks para comunicação segura entre containers
-   Monta volumes para persistência de logs
-   É parametrizável via variáveis de ambiente

Estrutura de Arquivos
---------------------

```
projetos/e-commerce/
├── status-service/             # Novo diretório para o serviço de monitoramento
│   ├── app.py                  # Código principal do serviço
│   ├── healthcheck.py          # Script para verificação de saúde do container
│   ├── requirements.txt        # Dependências Python
│   └── Dockerfile              # Instruções para build da imagem
└── docker-compose.rm.cp3.yml   # Composição Docker para produção (substituir rm pelo seu RM)

```

Passos para Implementação
-------------------------

### 1\. Clonar o repositório

```
# Clonar o repositório
git clone https://github.com/CodeCaman/cloud-developer-2TCNPZ.git
cd cloud-developer-2TCNPZ

```

### 2\. Criar uma branch com o RM no nome

```
# Criar uma branch com o RM no nome
git checkout -b checkpoint3-RM1234567

```

### 3\. Criar o diretório para o serviço de monitoramento

```
# Criar o diretório para o serviço
mkdir -p projetos/e-commerce/status-service
cd projetos/e-commerce/status-service

```

### 4\. Criar o arquivo app.py

```
# Criar o arquivo app.py
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os
import requests
import datetime
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
import json

app = Flask(__name__)

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("status.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# RA do aluno configurado via variável de ambiente
RA = os.getenv("RA", "RM1234567")

# Lista de serviços a serem monitorados com suas respectivas portas
SERVICES = [
    {"name": "avaliacoes-service", "port": 8081},
    {"name": "categorias-service", "port": 8082},
    {"name": "clientes-service", "port": 8083},
    {"name": "estoque-service", "port": 8084},
    {"name": "fornecedores-service", "port": 8085},
    {"name": "frete-services", "port": 8086},
    {"name": "items-service", "port": 8087},
    {"name": "lojas-service", "port": 8088},
    {"name": "orcamento-services", "port": 8089},
    {"name": "pagamentos-service", "port": 8090},
    {"name": "permissoes-services", "port": 8091},
    {"name": "produtos-service", "port": 8092},
    {"name": "usuarios-service", "port": 8093}
]

# Timeout para as requisições em segundos
REQUEST_TIMEOUT = 5

# Endpoint base de health check que todos os serviços implementam
HEALTH_ENDPOINT = "/health"

def check_service_health(service):
    """Verifica a saúde de um serviço específico."""
    service_name = service["name"]
    service_port = service["port"]
    service_host = service_name  # Usando o nome do serviço como hostname (funcionará com docker-compose)

    url = f"http://{service_host}:{service_port}{HEALTH_ENDPOINT}"

    try:
        logger.info(f"Verificando serviço: {service_name} em {url}")
        response = requests.get(url, timeout=REQUEST_TIMEOUT)

        if response.status_code == 200:
            try:
                data = response.json()
                return {
                    "service": service_name,
                    "status": data.get("status", "UNKNOWN"),
                    "ra": data.get("ra", "N/A"),
                    "checked_at": data.get("checked_at", "N/A"),
                    "healthy": True
                }
            except json.JSONDecodeError:
                logger.error(f"Erro ao decodificar JSON do serviço {service_name}")
                return {
                    "service": service_name,
                    "status": "ERROR",
                    "healthy": False,
                    "error": "Invalid JSON response"
                }
        else:
            logger.warning(f"Serviço {service_name} respondeu com status code: {response.status_code}")
            return {
                "service": service_name,
                "status": "DOWN",
                "healthy": False,
                "error": f"Status code: {response.status_code}"
            }
    except requests.RequestException as e:
        logger.error(f"Erro ao verificar serviço {service_name}: {str(e)}")
        return {
            "service": service_name,
            "status": "UNREACHABLE",
            "healthy": False,
            "error": str(e)
        }

@app.route('/health', methods=['GET'])
def health():
    """
    Endpoint de health check do serviço de monitoramento.
    Verifica a saúde de todos os microserviços e retorna um status consolidado.
    """
    logger.info(f"[{RA}] Recebido requisição de health check")

    now = datetime.datetime.utcnow().isoformat() + "Z"  # Timestamp UTC no formato ISO 8601

    # Verifica a saúde de todos os serviços em paralelo
    results = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        future_to_service = {executor.submit(check_service_health, service): service for service in SERVICES}
        for future in as_completed(future_to_service):
            results.append(future.result())

    # Conta quantos serviços estão saudáveis
    healthy_services = sum(1 for result in results if result.get("healthy", False))
    total_services = len(SERVICES)

    # Determina o status geral com base na proporção de serviços saudáveis
    overall_status = "UP" if healthy_services == total_services else "DEGRADED" if healthy_services > 0 else "DOWN"

    response = {
        "status": overall_status,
        "ra": RA,
        "checked_at": now,
        "services": results,
        "summary": {
            "total": total_services,
            "healthy": healthy_services,
            "unhealthy": total_services - healthy_services
        }
    }

    logger.info(f"Status geral do sistema: {overall_status} - Saudáveis: {healthy_services}/{total_services}")
    return jsonify(response)

# Rota raiz para informação básica sobre o serviço
@app.route('/', methods=['GET'])
def index():
    return jsonify({
        "service": "status-service",
        "description": "Serviço de monitoramento de microserviços",
        "ra": RA,
        "endpoints": [
            {
                "path": "/health",
                "method": "GET",
                "description": "Verificar a saúde de todos os microserviços"
            }
        ]
    })

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    host = os.getenv("HOST", "0.0.0.0")
    logger.info(f"Iniciando serviço de monitoramento na porta {port}")
    app.run(host=host, port=port)
EOF

```

### 5\. Criar o script de healthcheck

```
# Criar o script de healthcheck.py
cat > healthcheck.py << 'EOF'
#!/usr/bin/env python3
import requests
import sys

try:
    response = requests.get("http://localhost:8080/health", timeout=5)
    if response.status_code == 200:
        data = response.json()
        overall_status = data.get("status")

        # Verificamos se o status é UP ou DEGRADED (com pelo menos alguns serviços funcionando)
        # É importante que o container continue rodando mesmo se alguns serviços estiverem inacessíveis
        if overall_status in ["UP", "DEGRADED"]:
            sys.exit(0)  # Sucesso - O serviço de monitoramento está funcionando
        else:
            sys.exit(1)  # Falha - O serviço está completamente down
    else:
        sys.exit(1)  # Falha - Status code não é 200
except Exception as e:
    sys.exit(1)  # Falha - Exceção ao tentar acessar o endpoint
EOF

# Tornar o script executável
chmod +x healthcheck.py

```

### 6\. Criar o arquivo de requisitos

```
# Criar o arquivo requirements.txt
cat > requirements.txt << 'EOF'
flask==2.3.3
requests==2.31.0
gunicorn==21.2.0
EOF

```

### 7\. Criar o Dockerfile

```
# Criar o Dockerfile
cat > Dockerfile << 'EOF'
# Estágio de build - imagem base mais leve para Python
FROM python:3.11-slim AS builder

# Definir variáveis de ambiente para não criar arquivos .pyc
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Instalar dependências de compilação (se necessário)
RUN apt-get update && apt-get install -y --no-install-recommends gcc

# Criar diretório de trabalho e instalar dependências
WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Estágio de produção - Imagem final otimizada
FROM python:3.11-slim

# Criar usuário não-root para mais segurança
RUN groupadd -g 1000 appuser &&\
    useradd -u 1000 -g appuser -s /bin/bash -m appuser

# Definir variáveis de ambiente
ENV PYTHONDONTWRITEBYTECODE=1\
    PYTHONUNBUFFERED=1\
    PORT=8080\
    HOST=0.0.0.0\
    RA=RM1234567

# Criar diretório de logs com permissões corretas
RUN mkdir -p /app/logs &&\
    chown -R appuser:appuser /app

# Copiar apenas os wheels necessários do estágio de build
WORKDIR /app
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# Instalar dependências
RUN pip install --no-cache /wheels/* &&\
    rm -rf /wheels &&\
    rm -rf /root/.cache/pip/*

# Copiar o código da aplicação
COPY app.py .
COPY healthcheck.py .

# Mudar para usuário não-root
USER appuser

# Expor a porta
EXPOSE 8080

# Script para verificação de saúde
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3\
  CMD python healthcheck.py || exit 1

# Comando para iniciar a aplicação
CMD ["python", "app.py"]
EOF

```

### 8\. Criar o arquivo docker-compose para produção

```
# Voltar para o diretório e-commerce
cd ..

# Criar o docker-compose.rm.cp3.yml (substituir rm pelo seu RM)
cat > docker-compose.rm.cp3.yml << 'EOF'
version: '3.8'

networks:
  ecommerce-network:
    driver: bridge

volumes:
  status-logs:
    driver: local

services:
  # Serviço de monitoramento
  status-service:
    build:
      context: ./status-service
      dockerfile: Dockerfile
    image: ecommerce/status-service:${TAG:-latest}
    container_name: status-service
    restart: unless-stopped
    environment:
      - PORT=8080
      - HOST=0.0.0.0
      - RA=RM1234567
    ports:
      - "8080:8080"
    volumes:
      - status-logs:/app/logs
    networks:
      - ecommerce-network
    healthcheck:
      test: ["CMD", "python", "healthcheck.py"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 5s
    depends_on:
      - avaliacoes-service
      - categorias-service
      - clientes-service
      - estoque-service
      - fornecedores-service
      - frete-services
      - items-service
      - lojas-service
      - orcamento-services
      - pagamentos-service
      - permissoes-services
      - produtos-service
      - usuarios-service

  # Utilizamos os serviços existentes através da rede Docker
  # Os microserviços já existentes no repositório
  avaliacoes-service:
    networks:
      - ecommerce-network
    ports:
      - "8081:8081"

  categorias-service:
    networks:
      - ecommerce-network
    ports:
      - "8082:8082"

  clientes-service:
    networks:
      - ecommerce-network
    ports:
      - "8083:8083"

  estoque-service:
    networks:
      - ecommerce-network
    ports:
      - "8084:8084"

  fornecedores-service:
    networks:
      - ecommerce-network
    ports:
      - "8085:8085"

  frete-services:
    networks:
      - ecommerce-network
    ports:
      - "8086:8086"

  items-service:
    networks:
      - ecommerce-network
    ports:
      - "8087:8087"

  lojas-service:
    networks:
      - ecommerce-network
    ports:
      - "8088:8088"

  orcamento-services:
    networks:
      - ecommerce-network
    ports:
      - "8089:8089"

  pagamentos-service:
    networks:
      - ecommerce-network
    ports:
      - "8090:8090"

  permissoes-services:
    networks:
      - ecommerce-network
    ports:
      - "8091:8091"

  produtos-service:
    networks:
      - ecommerce-network
    ports:
      - "8092:8092"

  usuarios-service:
    networks:
      - ecommerce-network
    ports:
      - "8093:8093"
EOF

```

### 9\. Testar a implementação localmente (opcional)

```
# Validar o arquivo docker-compose
docker-compose -f docker-compose.rm.cp3.yml config

# Construir e iniciar os containers
docker-compose -f docker-compose.rm.cp3.yml up -d --build

# Verificar os logs
docker logs status-service

# Testar o endpoint de health check
curl http://localhost:8080/health

```

### 10\. Preparar e enviar as alterações para o GitHub

```
# Voltar para o diretório raiz do repositório
cd ../..

# Adicionar arquivos alterados para commit
git add projetos/e-commerce/status-service/
git add projetos/e-commerce/docker-compose.rm.cp3.yml

# Commit com mensagem contendo o RM
git commit -m "[RM1234567] Implementa checkpoint 3: health check, dockerfile e compose"

# Enviar branch para o GitHub
git push origin checkpoint3-RM1234567

```

### 11\. Criar Pull Request no GitHub

1.  Acesse o repositório no GitHub
2.  Vá para a seção "Pull requests"
3.  Clique em "New pull request"
4.  Selecione a branch `checkpoint3-RM1234567` como source
5.  Selecione a branch principal como target
6.  Adicione uma descrição detalhando as alterações
7.  Clique em "Create pull request"

Explicação dos Arquivos
-----------------------

### app.py

Este é o arquivo principal do serviço de monitoramento. Ele:

-   Configura um servidor web com Flask
-   Mantém uma lista de todos os microserviços a serem monitorados
-   Implementa uma função para verificar a saúde de cada serviço individualmente
-   Expõe um endpoint `/health` que verifica todos os serviços em paralelo
-   Agrupa os resultados e retorna um status consolidado
-   Registra logs para acompanhamento
-   Usa variáveis de ambiente para configuração

### healthcheck.py

Script para verificar a saúde do próprio serviço de monitoramento. O Docker executa este script periodicamente para garantir que o serviço está funcionando corretamente.

### requirements.txt

Lista as dependências Python necessárias para o serviço:

-   `flask`: Framework web para criar a API
-   `requests`: Biblioteca para fazer requisições HTTP
-   `gunicorn`: Servidor WSGI de produção

### Dockerfile

Define como construir a imagem Docker do serviço de monitoramento:

-   Usa uma abordagem multi-stage para otimizar o tamanho da imagem
-   Cria um usuário não-root para maior segurança
-   Configura variáveis de ambiente para parametrização
-   Define um healthcheck para auto-monitoramento
-   Expõe a porta necessária para acesso externo

### docker-compose.rm.cp3.yml

Arquivo de composição Docker para ambiente de produção que:

-   Define uma rede para comunicação entre os serviços
-   Cria um volume para persistência de logs
-   Configura o serviço de monitoramento e sua integração com os outros microserviços
-   Referencia os microserviços existentes (que já estão no repositório)

Resultado Esperado
------------------

Após a implementação, o serviço de monitoramento deverá:

1.  Ser construído e executado como um container Docker
2.  Verificar periodicamente a saúde de todos os microserviços
3.  Expor um endpoint `/health` que retorna o status consolidado do sistema
4.  Registrar logs para acompanhamento
5.  Auto-monitorar sua própria saúde via Docker healthcheck

Quando acessado, o endpoint `/health` retornará um JSON com:

```
{
  "status": "UP|DEGRADED|DOWN",
  "ra": "RM1234567",
  "checked_at": "2025-05-22T10:30:45Z",
  "services": [
    {
      "service": "avaliacoes-service",
      "status": "UP",
      "ra": "RM1234567",
      "checked_at": "2025-05-22T10:30:44Z",
      "healthy": true
    },
    // ... outros serviços
  ],
  "summary": {
    "total": 13,
    "healthy": 13,
    "unhealthy": 0
  }
}

```

Boas Práticas Implementadas
---------------------------

1.  **Contêinerização**: Docker para empacotar a aplicação
2.  **Monitoramento**: Verificação constante da saúde dos serviços
3.  **Segurança**: Uso de usuário não-root no container
4.  **Otimização**: Multi-stage build para reduzir o tamanho da imagem
5.  **Orquestração**: Docker Compose para gerenciar múltiplos serviços
6.  **Persistência**: Volume para armazenar logs
7.  **Isolamento**: Rede dedicada para comunicação entre serviços
8.  **Alta disponibilidade**: Configuração de restart para recuperação automática
9.  **Paralelismo**: Uso de ThreadPoolExecutor para verificações simultâneas🏗️ **Como Funciona a Arquitetura Detalhadamente**
--------------------------------------------------

### 📋 **Visão Geral do Fluxo**

```
Internet → Azure/AWS → VPN Site-to-Site → Comunicação Cross-Cloud
```

### 🔷 **Lado Azure - Funcionamento Detalhado**

#### **1\. Hub and Spoke Topology**

```
VNET Hub (10.1.0.0/16) - Centro de conectividade
├── Hub Subnet (10.1.1.0/24) - Serviços compartilhados
├── Gateway Subnet (10.1.3.0/27) - VPN Gateway (obrigatório)
├── Firewall Subnet (10.1.4.0/26) - Azure Firewall (opcional)
└── Bastion Subnet (10.1.5.0/26) - Azure Bastion (opcional)

VNET Spoke (10.1.10.0/24) - Workloads
└── Spoke Subnet (10.1.10.0/25) - VMs de aplicação
```

#### **2\. Fluxo de Tráfego Azure**

```
VM Spoke → Route Table → Azure Firewall → VPN Gateway → AWS
         ↓
    NSG (filtro local) → Firewall (filtro centralizado) → VPN (criptografia)
```

#### **3\. Peering Hub-Spoke**

-   **Hub permite Gateway Transit**: `allow_gateway_transit = true`
-   **Spoke usa Remote Gateways**: `use_remote_gateways = true`
-   **Resultado**: Spoke acessa internet e VPN através do Hub

### 🔶 **Lado AWS - Funcionamento Detalhado**

#### **1\. VPC Structure**

```
VPC (10.2.0.0/16)
├── Public Subnet (10.2.1.0/24) - Internet accessible
│   ├── EC2 Instance
│   ├── Internet Gateway
│   └── Elastic IP
└── Private Subnet (10.2.2.0/24) - Future expansion
    └── Database tier (opcional)
```

#### **2\. Fluxo de Tráfego AWS**

```
EC2 → Security Group → Route Table → VPN Gateway → Azure
    ↓
  Filtro local → Roteamento → Criptografia
```

### 🔗 **VPN Site-to-Site - Funcionamento Detalhado**

#### **1\. Estabelecimento da Conexão**

```
Azure VPN Gateway ←→ AWS VPN Gateway
      ↑                    ↑
   Public IP          Customer Gateway
      ↑                    ↑
  IKE Negotiation ←→ IPsec Tunnels (2x)
```

#### **2\. Processo de Conexão**

1.  **IKE Phase 1**: Estabelece canal seguro
2.  **IKE Phase 2**: Negocia parâmetros IPsec
3.  **Tunnel Creation**: Cria túneis redundantes
4.  **Route Propagation**: Distribui rotas automaticamente

#### **3\. Roteamento Cross-Cloud**

```
Azure: 10.1.0.0/16, 10.1.10.0/24 → AWS: 10.2.0.0/16
AWS: 10.2.0.0/16 → Azure: 10.1.0.0/16, 10.1.10.0/24
```

### 🌐 **DNS Privado - Funcionamento Detalhado**

#### **1\. Zona Azure (2tcnpz.local)**

```
Private DNS Zone: 2tcnpz.local
├── Linked to Hub VNET (registration enabled)
├── Linked to Spoke VNET (registration enabled)
└── Records:
    ├── vm-azure.2tcnpz.local → 10.1.10.x
    └── Auto-registered VMs
```

#### **2\. Zona AWS (aws.2tcnpz.local)**

```
Route 53 Private Zone: aws.2tcnpz.local
├── Associated with VPC
└── Records:
    ├── ec2-aws.aws.2tcnpz.local → 10.2.1.x
    └── vm-azure.aws.2tcnpz.local → 10.1.10.x (cross-reference)
```

#### **3\. Resolução Cross-Cloud**

```
Azure VM query: ec2-aws.aws.2tcnpz.local
└── Azure DNS → No record → Internet resolver → Route 53 → 10.2.1.x

AWS EC2 query: vm-azure.2tcnpz.local
└── Route 53 → Local record → 10.1.10.x
```

### 🔒 **Segurança - Camadas de Proteção**

#### **1\. Perímetro (Firewall)**

```
Azure Firewall (se habilitado)
├── Network Rules: Allow Azure ↔ AWS traffic
├── Application Rules: HTTP/HTTPS to specific FQDNs
└── DNAT Rules: Port forwarding (opcional)
```

#### **2\. Subnet Level (NSG/Security Groups)**

```
Azure NSG:
├── SSH (22/tcp) - Inbound from anywhere
├── ICMP - Inbound from AWS CIDR
└── HTTP/HTTPS (80,443/tcp) - Inbound from anywhere

AWS Security Group:
├── SSH (22/tcp) - Inbound from 0.0.0.0/0
├── ICMP - Inbound from Azure CIDRs only
└── All outbound traffic allowed
```

#### **3\. Transport (VPN)**

```
IPsec Encryption:
├── AES-256 encryption
├── SHA-256 hashing
├── DH Group 14
└── PFS (Perfect Forward Secrecy)
```

### 📊 **Fluxo de Dados Completo**

#### **Exemplo: VM Azure pinga EC2 AWS**

```
1\. VM Spoke (10.1.10.5) → ping 10.2.1.10
2. Route Table Spoke → Next hop: Azure Firewall (10.1.4.4)
3. Azure Firewall → Allow rule → Forward to VPN Gateway
4. VPN Gateway Azure → IPsec tunnel → VPN Gateway AWS
5. VPN Gateway AWS → Route Table → EC2 subnet
6. Security Group AWS → Allow ICMP from 10.1.10.0/24
7. EC2 receives ping → Reply follows reverse path
```

🏰 **Sobre o Bastion Host - É Necessário?**
-------------------------------------------

### ❌ **NÃO é obrigatório nesta arquitetura**

#### **Motivos:**

1.  **VMs têm IPs públicos**: Acesso SSH direto possível
2.  **Security Groups protegem**: SSH apenas de IPs específicos
3.  **VPN fornece conectividade**: Acesso interno via túnel
4.  **Custo adicional**: ~$140/mês para Azure Bastion

### ✅ **Quando seria recomendado:**

#### **Produção Enterprise:**

```
Cenários que justificam Bastion:
├── VMs sem IP público (mais seguro)
├── Compliance rigoroso (PCI-DSS, SOC2)
├── Auditoria centralizada de acesso
├── MFA obrigatório
└── Gravação de sessões SSH
```

#### **Configuração atual (sem Bastion):**

```
Acesso SSH:
├── Azure VM: Via VPN ou jumpbox na rede corporativa
├── AWS EC2: Via IP público com Security Group restritivo
└── Segurança: Chaves SSH + Security Groups + Firewall
```

### 🔐 **Alternativas ao Bastion Host:**

#### **1\. Jumpbox Manual**

hcl

```
# VM dedicada no Hub subnet
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name = "vm-jumpbox"
  # Configuração mínima
  # IP público apenas para esta VM
}
```

#### **2\. VPN Client-to-Site**

hcl

```
# Point-to-Site VPN
resource "azurerm_point_to_site_vpn_gateway" "client_vpn" {
  # Permite acesso direto via cliente VPN
  # Sem necessidade de Bastion
}
```

#### **3\. Azure AD Application Proxy**

hcl

```
# Acesso via Azure AD sem VPN
# Integração com identidade corporativa
```

🎯 **Recomendação para sua Arquitetura:**
-----------------------------------------

### **Para Apresentação/Estudo:**

-   ✅ **Manter sem Bastion**: Mais econômico e direto
-   ✅ **Usar Security Groups**: Proteção adequada
-   ✅ **Acesso via SSH + chaves**: Método padrão
-   ✅ **Demonstrar conectividade VPN**: Foco principal

### **Para Produção Real:**

-   🤔 **Considerar Bastion se**:
    -   Budget permite (~$140/mês)
    -   Compliance exige
    -   Múltiplas VMs sem IP público
    -   Auditoria centralizada necessária

### **Configuração Atual é Adequada porque:**

1.  **Security Groups** filtram acesso SSH
2.  **VPN** permite conectividade segura entre clouds
3.  **NSGs** adicionam camada extra de proteção
4.  **Chaves SSH** (não senhas) são mais seguras
5.  **Azure Firewall** (opcional) centraliza políticas

📋 **Resumo do Funcionamento:**
-------------------------------

Esta arquitetura cria uma **rede híbrida segura** onde:

-   **Azure Hub** centraliza conectividade
-   **Azure Spoke** hospeda workloads
-   **AWS VPC** complementa com serviços específicos
-   **VPN Site-to-Site** conecta as clouds de forma criptografada
-   **DNS Privado** permite resolução cross-cloud
-   **Múltiplas camadas de segurança** protegem sem necessidade de Bastion

**É uma arquitetura enterprise-ready, escalável e econômica!** 🚀

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