#!/bin/bash
# modules/aws-compute/scripts/init.sh
# Script básico de inicialização para EC2

# Atualizar sistema
apt-get update -y

# Instalar ferramentas básicas
apt-get install -y \
    curl \
    wget \
    net-tools \
    htop \
    unzip \
    awscli \
    git

# Configurar timezone
timedatectl set-timezone America/Sao_Paulo

# Criar script de teste de conectividade
cat << 'EOF' > /home/ubuntu/test-network.sh
#!/bin/bash
echo "=== Teste de Rede AWS EC2 ==="
echo "Data: $(date)"
echo ""

echo "1. Informações da interface:"
ip addr show
echo ""

echo "2. Tabela de rotas:"
ip route show
echo ""

echo "3. Teste de conectividade externa:"
ping -c 3 8.8.8.8
echo ""

echo "4. Teste DNS:"
nslookup google.com
echo ""

if [ -n "${azure_vm_ip}" ]; then
    echo "5. Teste conectividade com Azure VM:"
    ping -c 3 ${azure_vm_ip} || echo "Conectividade com Azure falhou (VPN pode não estar ativa)"
fi
EOF

chmod +x /home/ubuntu/test-network.sh
chown ubuntu:ubuntu /home/ubuntu/test-network.sh

# Criar script de monitoramento básico
cat << 'EOF' > /home/ubuntu/monitor.sh
#!/bin/bash
echo "=== Monitor AWS EC2 ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4"%"}'

echo ""
echo "Memory Usage:"
free -h

echo ""
echo "Disk Usage:"
df -h /

echo ""
echo "Network Connections:"
netstat -tuln
EOF

chmod +x /home/ubuntu/monitor.sh
chown ubuntu:ubuntu /home/ubuntu/monitor.sh

# Log de conclusão
echo "$(date): AWS EC2 initialized successfully" >> /var/log/ec2-init.log