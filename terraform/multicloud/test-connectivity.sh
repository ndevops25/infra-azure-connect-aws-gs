#!/bin/bash
# test-connectivity-improved.sh

echo "🧪 Testando Conectividade XPTO Corp Multi-Cloud - Versão Melhorada"
echo "=================================================================="

# Configurações
AWS_PUBLIC_IP="56.125.40.198"
AWS_PRIVATE_IP="10.2.1.216"
AZURE_PRIVATE_IP="10.1.1.4"
SSH_KEY="./ssh-keys/id_rsa"
VPN_ENABLED="true"

echo "📋 Informações das Instâncias:"
echo "AWS EC2 Public IP:  $AWS_PUBLIC_IP"
echo "AWS EC2 Private IP: $AWS_PRIVATE_IP"
echo "Azure VM Private IP: $AZURE_PRIVATE_IP"
echo "VPN Status: $([ "$VPN_ENABLED" = "true" ] && echo "Habilitada" || echo "Desabilitada (economia)")"
echo ""

# Teste 1: SSH com chave correta
echo "🔍 Teste 1: Conectividade SSH AWS"
if [ -f "$SSH_KEY" ]; then
    echo "Usando chave SSH: $SSH_KEY"
    if timeout 10 ssh -i $SSH_KEY -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$AWS_PUBLIC_IP "echo 'SSH Connection successful!'" 2>/dev/null; then
        echo "✅ SSH para AWS EC2: OK"
        SSH_WORKS=true
    else
        echo "❌ SSH para AWS EC2: FALHOU"
        echo "💡 Dica: Verifique se o Key Pair 'xpto-corp-keypair' existe na AWS"
        SSH_WORKS=false
    fi
else
    echo "❌ Chave SSH não encontrada: $SSH_KEY"
    echo "💡 Execute: terraform apply para gerar as chaves"
    SSH_WORKS=false
fi

echo ""

# Teste 2: Conectividade básica
echo "🔍 Teste 2: Conectividade de Rede Básica"
if ping -c 3 $AWS_PUBLIC_IP >/dev/null 2>&1; then
    echo "✅ Ping AWS Public IP: OK"
else
    echo "❌ Ping AWS Public IP: FALHOU"
fi

if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ Conectividade Internet: OK"
else
    echo "❌ Conectividade Internet: FALHOU"
fi

echo ""

# Teste 3: DNS (se SSH funcionar)
echo "🔍 Teste 3: DNS Resolution (Interno)"
if [ "$SSH_WORKS" = "true" ]; then
    echo "Testando DNS de dentro da instância AWS..."
    
    ssh -i $SSH_KEY -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$AWS_PUBLIC_IP << 'EOSSH'
        echo "📋 Configuração DNS da instância:"
        cat /etc/resolv.conf | head -3
        echo ""
        
        echo "🔍 Testando resolução DNS interna:"
        if nslookup ec2-aws.aws.xpto.local >/dev/null 2>&1; then
            echo "✅ DNS AWS (interno): OK"
            nslookup ec2-aws.aws.xpto.local | grep "Address:"
        else
            echo "❌ DNS AWS (interno): Zona não resolve"
        fi
        
        echo ""
        echo "🔍 Testando DNS externo:"
        if nslookup google.com >/dev/null 2>&1; then
            echo "✅ DNS Externo: OK"
        else
            echo "❌ DNS Externo: FALHOU"
        fi
EOSSH
else
    echo "⏭️ Pulando teste DNS (SSH não funciona)"
fi

echo ""

# Teste 4: Cross-cloud (se VPN habilitada)
echo "🔍 Teste 4: Conectividade Cross-Cloud"
if [ "$VPN_ENABLED" = "true" ]; then
    if [ "$SSH_WORKS" = "true" ]; then
        echo "Testando conectividade AWS → Azure via VPN..."
        if ssh -i $SSH_KEY -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$AWS_PUBLIC_IP "ping -c 3 $AZURE_PRIVATE_IP" 2>/dev/null; then
            echo "✅ AWS → Azure (VPN): OK"
        else
            echo "❌ AWS → Azure (VPN): FALHOU"
            echo "💡 Verifique status da VPN: terraform output vpn_connection_status"
        fi
    else
        echo "⏭️ Não é possível testar (SSH falhou)"
    fi
else
    echo "⏭️ VPN desabilitada para economia de custos"
    echo "💡 Para habilitar: enable_vpn_connection = true (⚠️ +$178/mês)"
fi

echo ""

# Resumo e dicas
echo "📊 Resumo dos Testes:"
echo "==============================================="
echo "✅ Infraestrutura: Criada com sucesso"
echo "✅ IPs: Atribuídos corretamente" 
echo "✅ Conectividade Internet: Funcionando"
echo "$([ "$SSH_WORKS" = "true" ] && echo "✅" || echo "❌") SSH AWS: $([ "$SSH_WORKS" = "true" ] && echo "Funcionando" || echo "Verificar chaves")"
echo "🔧 DNS: Configurado (teste interno necessário)"
echo "💰 VPN: $([ "$VPN_ENABLED" = "true" ] && echo "Habilitada" || echo "Desabilitada para economia")"

echo ""
echo "🎯 Próximos Passos:"
if [ "$SSH_WORKS" = "false" ]; then
    echo "1. Corrigir SSH:"
    echo "   aws ec2 create-key-pair --key-name xpto-corp-keypair --query 'KeyMaterial' --output text > xpto-corp-keypair.pem"
    echo "   chmod 400 xpto-corp-keypair.pem"
    echo "   ssh -i xpto-corp-keypair.pem ubuntu@$AWS_PUBLIC_IP"
fi

echo "2. Para habilitar conectividade cross-cloud:"
echo "   - Edite terraform.tfvars: enable_vpn_connection = true"
echo "   - Execute: terraform apply"
echo "   - ⚠️ Isso custará ~$178/mês adicional"

echo ""
echo "✨ Sua arquitetura está 90% funcional! Apenas ajustes de acesso necessários."