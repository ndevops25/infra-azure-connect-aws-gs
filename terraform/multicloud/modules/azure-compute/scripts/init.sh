#!/bin/bash
# modules/azure-compute/scripts/init.sh
# Script básico de inicialização para VM Azure

# Atualizar sistema
apt-get update -y

# Instalar ferramentas básicas
apt-get install -y \
    curl \
    wget \
    net-tools \
    htop \
    unzip \
    git

# Configurar timezone
timedatectl set-timezone America/Sao_Paulo

# Aguardar rede estar pronta
sleep 10

# Atualizar sistema (mínimo necessário)
apt-get update -y >> /var/log/user-data.log 2>&1

# Instalar apenas o essencial para SSH funcionar
apt-get install -y openssh-server >> /var/log/user-data.log 2>&1

# Garantir que SSH está rodando
systemctl enable ssh >> /var/log/user-data.log 2>&1
systemctl start ssh >> /var/log/user-data.log 2>&1

# Criar script de teste de conectividade
cat << 'EOF' > /home/${admin_username}/test-network.sh
#!/bin/bash
echo "=== Teste de Rede Azure VM ==="
echo "Data: $(date)"
echo ""

echo "1. Informações da interface:"
ip addr show
echo ""

echo "2. Tabela de rotas:"
ip route show
echo ""

echo "3. DNS configurado:"
cat /etc/resolv.conf
echo ""

echo "4. Teste de conectividade externa:"
ping -c 3 8.8.8.8
echo ""

echo "5. Teste DNS:"
nslookup google.com
EOF

chmod +x /home/${admin_username}/test-network.sh
chown ${admin_username}:${admin_username} /home/${admin_username}/test-network.sh

# Log de conclusão
echo "$(date): Azure VM initialized successfully" >> /var/log/vm-init.log