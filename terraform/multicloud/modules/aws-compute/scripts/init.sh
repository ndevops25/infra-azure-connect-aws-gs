#!/bin/bash

# Log de início
echo "$(date): Iniciando configuração AWS EC2" >> /var/log/user-data.log

# Atualizar sistema
apt-get update -y 2>&1 | tee -a /var/log/user-data.log

# ✅ GARANTIR que SSH está rodando
# Aguardar rede estar pronta
sleep 10

# Atualizar sistema (mínimo necessário)
apt-get update -y >> /var/log/user-data.log 2>&1

# Instalar apenas o essencial para SSH funcionar
apt-get install -y openssh-server >> /var/log/user-data.log 2>&1

# Garantir que SSH está rodando
systemctl enable ssh >> /var/log/user-data.log 2>&1
systemctl start ssh >> /var/log/user-data.log 2>&1

# ✅ VERIFICAR se usuário ubuntu existe
id ubuntu >> /var/log/user-data.log

# ✅ GARANTIR que diretório SSH existe
mkdir -p /home/ubuntu/.ssh
chown ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Instalar ferramentas básicas
apt-get install -y \
    curl \
    wget \
    net-tools \
    htop \
    unzip \
    awscli \
    git \
    openssh-server 2>&1 | tee -a /var/log/user-data.log

# Configurar timezone
timedatectl set-timezone America/Sao_Paulo

# ✅ CRIAR script de debug SSH
cat << 'EOF' > /home/ubuntu/debug-ssh.sh
#!/bin/bash
echo "=== DEBUG SSH ==="
echo "1. Status SSH:"
systemctl status ssh

echo "2. Usuário atual:"
whoami
id

echo "3. Chaves SSH:"
ls -la ~/.ssh/

echo "4. Configuração SSH:"
sudo cat /etc/ssh/sshd_config | grep -E "PasswordAuthentication|PubkeyAuthentication|PermitRootLogin"

echo "5. Logs SSH:"
sudo tail -20 /var/log/auth.log

echo "6. Conectividade:"
curl -s http://checkip.amazonaws.com
EOF

chmod +x /home/ubuntu/debug-ssh.sh
chown ubuntu:ubuntu /home/ubuntu/debug-ssh.sh

# Script de teste de rede original...
cat << 'EOF' > /home/ubuntu/test-network.sh
#!/bin/bash
echo "=== Teste de Rede AWS EC2 ==="
echo "Data: $(date)"
echo ""

echo "1. IP Público:"
curl -s http://checkip.amazonaws.com
echo ""

echo "2. Informações da interface:"
ip addr show
echo ""

echo "3. Tabela de rotas:"
ip route show
echo ""

echo "4. Teste de conectividade externa:"
ping -c 3 8.8.8.8
echo ""

echo "5. Teste DNS:"
nslookup google.com
echo ""

if [ -n "${azure_vm_ip}" ]; then
    echo "6. Teste conectividade com Azure VM:"
    ping -c 3 ${azure_vm_ip} || echo "Conectividade com Azure falhou (VPN pode não estar ativa)"
fi

echo "7. Status SSH:"
systemctl status ssh --no-pager
EOF

chmod +x /home/ubuntu/test-network.sh
chown ubuntu:ubuntu /home/ubuntu/test-network.sh

# ✅ TESTAR conectividade imediatamente
curl -s http://checkip.amazonaws.com >> /var/log/user-data.log
echo "IP público obtido" >> /var/log/user-data.log

# Log de conclusão
echo "$(date): AWS EC2 configurado com sucesso" >> /var/log/user-data.log
echo "SSH Status: $(systemctl is-active ssh)" >> /var/log/user-data.log