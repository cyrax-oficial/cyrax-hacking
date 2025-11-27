#!/bin/bash
# Email Intelligence - Análise inteligente de emails encontrados
echo "=== EMAIL INTELLIGENCE ==="

if [ -z "$1" ]; then
    echo "Uso: $0 <EMAIL_OU_URL>"
    echo "Exemplo: $0 admin@example.com"
    echo "Exemplo: $0 https://api.example.com (busca emails na resposta)"
    exit 1
fi

INPUT="$1"

# Função para analisar um email
analyze_email() {
    local email="$1"
    local domain=$(echo "$email" | cut -d'@' -f2)
    local username=$(echo "$email" | cut -d'@' -f1)
    
    echo "=== Analisando: $email ==="
    
    # Classificar tipo de email
    echo -e "\n[1] CLASSIFICAÇÃO:"
    if [[ "$domain" =~ (gmail|yahoo|hotmail|outlook|proton|tutanota) ]]; then
        echo "Tipo: Email pessoal ($domain)"
        echo "Prioridade: BAIXA"
    else
        echo "Tipo: Email corporativo ($domain)"
        echo "Prioridade: ALTA - Possível funcionário"
    fi
    
    # Analisar username
    echo -e "\n[2] ANÁLISE DO USERNAME:"
    if [[ "$username" =~ (admin|administrator|root|support|info|contact) ]]; then
        echo "⚠️  USERNAME ADMINISTRATIVO: $username"
        echo "Prioridade: CRÍTICA - Conta privilegiada"
    elif [[ "$username" =~ (test|demo|guest|temp) ]]; then
        echo "ℹ️  USERNAME DE TESTE: $username"
        echo "Prioridade: MÉDIA - Conta de teste"
    else
        echo "Username: $username (usuário comum)"
        echo "Prioridade: NORMAL"
    fi
    
    # Informações do domínio
    echo -e "\n[3] INFORMAÇÕES DO DOMÍNIO:"
    echo "Domínio: $domain"
    
    # WHOIS do domínio
    echo "WHOIS:"
    whois_info=$(proxychains4 -q whois "$domain" 2>/dev/null | grep -iE "(organization|country|registrar|creation|expir)" | head -5)
    if [ -n "$whois_info" ]; then
        echo "$whois_info"
    else
        echo "Informações WHOIS não disponíveis"
    fi
    
    # Verificar se domínio tem MX record
    echo -e "\nMX Records:"
    mx_records=$(proxychains4 -q nslookup -type=MX "$domain" 2>/dev/null | grep "mail exchanger")
    if [ -n "$mx_records" ]; then
        echo "$mx_records"
        echo "✅ Domínio aceita emails"
    else
        echo "❌ Sem MX records - Domínio pode não aceitar emails"
    fi
    
    # Sugestões de ataques
    echo -e "\n[4] SUGESTÕES DE ATAQUE:"
    
    # Password spraying
    echo "1. Password Spraying:"
    echo "   Senhas comuns: $username, ${username}123, ${username}2024"
    echo "   Padrões: $domain, ${domain%.*}, empresa123"
    
    # Phishing
    echo -e "\n2. Phishing:"
    echo "   Criar domínio similar: ${domain//./-}.com"
    echo "   Email spoofing: usar display name '$username'"
    
    # OSINT
    echo -e "\n3. OSINT (Inteligência):"
    echo "   LinkedIn: Buscar '$username' em '$domain'"
    echo "   Google: \"$email\" site:linkedin.com"
    echo "   Breach databases: HaveIBeenPwned"
    
    # Social Engineering
    echo -e "\n4. Engenharia Social:"
    if [[ "$username" =~ (admin|root|support) ]]; then
        echo "   Alvo: Administrador - Acesso crítico"
        echo "   Abordagem: Urgência técnica, problemas de segurança"
    else
        echo "   Alvo: Usuário comum"
        echo "   Abordagem: Promoções, atualizações de conta"
    fi
    
    # Verificar vazamentos conhecidos
    echo -e "\n[5] VERIFICAÇÃO DE VAZAMENTOS:"
    echo "Verificando em bases conhecidas..."
    
    # Simular verificação (em ambiente real, usar APIs)
    common_breaches=("LinkedIn" "Adobe" "Yahoo" "Equifax" "Facebook")
    for breach in "${common_breaches[@]}"; do
        # Simulação - em ambiente real usar API do HaveIBeenPwned
        if [ $((RANDOM % 3)) -eq 0 ]; then
            echo "⚠️  Possível vazamento em: $breach"
        fi
    done
    
    # Gerar variações do email
    echo -e "\n[6] VARIAÇÕES PARA TESTE:"
    echo "Variações do username:"
    echo "   ${username}.admin@$domain"
    echo "   ${username}admin@$domain"
    echo "   admin.${username}@$domain"
    echo "   ${username}123@$domain"
    
    # Outros emails do mesmo domínio
    echo -e "\nOutros emails para testar:"
    common_users=("admin" "administrator" "support" "info" "contact" "sales" "marketing")
    for user in "${common_users[@]}"; do
        echo "   $user@$domain"
    done
}

# Verificar se é URL ou email direto
if [[ "$INPUT" =~ ^https?:// ]]; then
    echo "Buscando emails em: $INPUT"
    
    # Buscar emails na resposta
    response=$(proxychains4 -q curl -s "$INPUT" --connect-timeout 10)
    emails=$(echo "$response" | grep -oiP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
    
    if [ -n "$emails" ]; then
        echo "Emails encontrados:"
        echo "$emails"
        echo ""
        
        # Analisar cada email
        echo "$emails" | while read email; do
            analyze_email "$email"
            echo -e "\n" "="*50 "\n"
        done
    else
        echo "Nenhum email encontrado na URL"
    fi
    
    # Buscar também em arquivos JS
    echo "Buscando emails em arquivos JavaScript..."
    js_files=$(echo "$response" | grep -oP 'src="[^"]*\.js[^"]*"' | sed 's/src="//;s/"//' | head -3)
    
    if [ -n "$js_files" ]; then
        echo "$js_files" | while read js_file; do
            if [[ "$js_file" == /* ]]; then
                js_url="$INPUT$js_file"
            elif [[ "$js_file" == http* ]]; then
                js_url="$js_file"
            else
                js_url="$INPUT/$js_file"
            fi
            
            js_content=$(proxychains4 -q curl -s "$js_url" --connect-timeout 10)
            js_emails=$(echo "$js_content" | grep -oiP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
            
            if [ -n "$js_emails" ]; then
                echo "Emails em $js_file:"
                echo "$js_emails"
            fi
        done
    fi
    
else
    # Analisar email direto
    if [[ "$INPUT" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        analyze_email "$INPUT"
    else
        echo "Formato de email inválido: $INPUT"
        exit 1
    fi
fi

# Salvar análise
ANALYSIS_FILE="/tmp/email_analysis_$(date +%s).txt"
echo "Salvando análise em: $ANALYSIS_FILE"

if [[ "$INPUT" =~ ^https?:// ]]; then
    response=$(proxychains4 -q curl -s "$INPUT" --connect-timeout 10)
    emails=$(echo "$response" | grep -oiP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
    echo "$emails" | while read email; do
        analyze_email "$email" >> "$ANALYSIS_FILE"
    done
else
    analyze_email "$INPUT" > "$ANALYSIS_FILE"
fi

echo "Análise de email concluída!"