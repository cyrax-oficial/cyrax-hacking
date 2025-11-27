#!/bin/bash
# Sensitive Data Hunter - Caça dados sensíveis
echo "=== SENSITIVE DATA HUNTER ==="

if [ -z "$1" ]; then
    echo "Uso: $0 <URL_OU_TEXTO>"
    echo "Exemplo: $0 https://api.example.com/config"
    echo "Exemplo: $0 'texto com dados sensíveis'"
    exit 1
fi

INPUT="$1"

# Função para analisar texto
analyze_text() {
    local text="$1"
    local source="$2"
    
    echo "Analisando: $source"
    
    # JWT Tokens
    echo -e "\n[JWT TOKENS]"
    JWT_TOKENS=$(echo "$text" | grep -oP 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+')
    if [ -n "$JWT_TOKENS" ]; then
        echo "$JWT_TOKENS" | while read jwt; do
            echo "🔑 JWT: ${jwt:0:50}..."
            # Decodificar payload rapidamente
            payload=$(echo "$jwt" | cut -d'.' -f2)
            case $((${#payload} % 4)) in
                2) payload="${payload}==" ;;
                3) payload="${payload}=" ;;
            esac
            payload=$(echo "$payload" | tr '_-' '/+' | base64 -d 2>/dev/null)
            echo "   Payload: $payload" | head -1
        done
    else
        echo "Nenhum JWT encontrado"
    fi
    
    # Emails
    echo -e "\n[EMAILS]"
    EMAILS=$(echo "$text" | grep -oiP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
    if [ -n "$EMAILS" ]; then
        echo "$EMAILS" | while read email; do
            echo "📧 $email"
            # Verificar se é email corporativo ou pessoal
            domain=$(echo "$email" | cut -d'@' -f2)
            if [[ "$domain" =~ (gmail|yahoo|hotmail|outlook|proton) ]]; then
                echo "   Tipo: Email pessoal"
            else
                echo "   Tipo: Email corporativo - ALVO PRIORITÁRIO"
            fi
        done
    else
        echo "Nenhum email encontrado"
    fi
    
    # CPF (Brasil)
    echo -e "\n[CPF BRASIL]"
    CPFS=$(echo "$text" | grep -oP '[0-9]{3}\.?[0-9]{3}\.?[0-9]{3}-?[0-9]{2}' | grep -E '^[0-9]{3}\.?[0-9]{3}\.?[0-9]{3}-?[0-9]{2}$')
    if [ -n "$CPFS" ]; then
        echo "$CPFS" | while read cpf; do
            echo "🆔 CPF: $cpf"
            echo "   ⚠️  DADO PESSOAL SENSÍVEL - LGPD"
        done
    else
        echo "Nenhum CPF encontrado"
    fi
    
    # CNPJ (Brasil)
    echo -e "\n[CNPJ BRASIL]"
    CNPJS=$(echo "$text" | grep -oP '[0-9]{2}\.?[0-9]{3}\.?[0-9]{3}/?[0-9]{4}-?[0-9]{2}')
    if [ -n "$CNPJS" ]; then
        echo "$CNPJS" | while read cnpj; do
            echo "🏢 CNPJ: $cnpj"
            echo "   💡 Usar para consultas na Receita Federal"
        done
    else
        echo "Nenhum CNPJ encontrado"
    fi
    
    # Telefones Brasil
    echo -e "\n[TELEFONES BRASIL]"
    PHONES=$(echo "$text" | grep -oP '\(?[0-9]{2}\)?\s?[0-9]{4,5}-?[0-9]{4}')
    if [ -n "$PHONES" ]; then
        echo "$PHONES" | while read phone; do
            echo "📱 Telefone: $phone"
        done
    else
        echo "Nenhum telefone encontrado"
    fi
    
    # API Keys
    echo -e "\n[API KEYS]"
    API_KEYS=$(echo "$text" | grep -oiP '(api[_-]?key|apikey|access[_-]?token|secret[_-]?key)["\s]*[:=]["\s]*[A-Za-z0-9_-]{20,}')
    if [ -n "$API_KEYS" ]; then
        echo "$API_KEYS" | while read key; do
            echo "🔐 API Key: $key"
            echo "   ⚠️  CREDENCIAL SENSÍVEL"
        done
    else
        echo "Nenhuma API key óbvia encontrada"
    fi
    
    # Passwords
    echo -e "\n[PASSWORDS]"
    PASSWORDS=$(echo "$text" | grep -oiP '(password|passwd|pwd|pass)["\s]*[:=]["\s]*[^"\s,}]{3,}')
    if [ -n "$PASSWORDS" ]; then
        echo "$PASSWORDS" | while read pass; do
            echo "🔒 Password: $pass"
            echo "   ⚠️  CREDENCIAL CRÍTICA"
        done
    else
        echo "Nenhuma password óbvia encontrada"
    fi
    
    # URLs sensíveis
    echo -e "\n[URLs SENSÍVEIS]"
    SENSITIVE_URLS=$(echo "$text" | grep -oiP 'https?://[^"\s]+' | grep -iE '(admin|login|api|auth|config|backup|test|dev)')
    if [ -n "$SENSITIVE_URLS" ]; then
        echo "$SENSITIVE_URLS" | sort -u | while read url; do
            echo "🌐 URL: $url"
        done
    else
        echo "Nenhuma URL sensível encontrada"
    fi
    
    # IPs privados
    echo -e "\n[IPs PRIVADOS]"
    PRIVATE_IPS=$(echo "$text" | grep -oP '\b(?:10\.|172\.(?:1[6-9]|2[0-9]|3[01])\.|192\.168\.)[0-9]{1,3}\.[0-9]{1,3}\b')
    if [ -n "$PRIVATE_IPS" ]; then
        echo "$PRIVATE_IPS" | sort -u | while read ip; do
            echo "🖥️  IP Privado: $ip"
            echo "   💡 Possível rede interna"
        done
    else
        echo "Nenhum IP privado encontrado"
    fi
}

# Verificar se é URL ou texto
if [[ "$INPUT" =~ ^https?:// ]]; then
    echo "Obtendo dados de: $INPUT"
    
    # Tentar diferentes endpoints
    ENDPOINTS=("" "/config" "/.env" "/api/config" "/admin/config")
    
    for endpoint in "${ENDPOINTS[@]}"; do
        url="$INPUT$endpoint"
        echo -e "\n=== Testando: $url ==="
        
        response=$(proxychains4 -q curl -s "$url" -H "Accept: application/json, text/plain" --connect-timeout 10)
        
        if [ -n "$response" ] && [ "$response" != "404" ]; then
            analyze_text "$response" "$url"
        else
            echo "Sem resposta ou 404"
        fi
        
        sleep 2
    done
    
    # Tentar JavaScript files
    echo -e "\n=== Analisando arquivos JavaScript ==="
    js_files=$(proxychains4 -q curl -s "$INPUT" | grep -oP 'src="[^"]*\.js[^"]*"' | sed 's/src="//;s/"//' | head -5)
    
    if [ -n "$js_files" ]; then
        echo "$js_files" | while read js_file; do
            if [[ "$js_file" == /* ]]; then
                js_url="$INPUT$js_file"
            elif [[ "$js_file" == http* ]]; then
                js_url="$js_file"
            else
                js_url="$INPUT/$js_file"
            fi
            
            echo -e "\n--- Analisando JS: $js_url ---"
            js_content=$(proxychains4 -q curl -s "$js_url" --connect-timeout 10)
            if [ -n "$js_content" ]; then
                analyze_text "$js_content" "$js_url"
            fi
        done
    fi
    
else
    # Analisar texto direto
    analyze_text "$INPUT" "texto fornecido"
fi

# Salvar resultado
RESULT_FILE="/tmp/sensitive_data_$(date +%s).txt"
echo -e "\n[SALVANDO RESULTADO]"
echo "Arquivo: $RESULT_FILE"

# Re-executar análise e salvar
if [[ "$INPUT" =~ ^https?:// ]]; then
    response=$(proxychains4 -q curl -s "$INPUT" --connect-timeout 10)
    analyze_text "$response" "$INPUT" > "$RESULT_FILE"
else
    analyze_text "$INPUT" "texto fornecido" > "$RESULT_FILE"
fi

echo "Análise de dados sensíveis concluída!"