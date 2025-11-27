#!/bin/bash
# JSON Parser - Extrai dados específicos de JSONs gigantes
echo "=== JSON PARSER ==="

if [ -z "$2" ]; then
    echo "Uso: $0 <URL> <TIPO>"
    echo "Tipos: endpoints, credentials, tokens, emails, ips, domains, keys"
    echo "Exemplo: $0 https://api.example.com/config endpoints"
    exit 1
fi

URL="$1"
TYPE="$2"

echo "Analisando JSON de: $URL"
echo "Extraindo: $TYPE"

# Baixar JSON
echo -e "\n[1] Baixando JSON..."
JSON_DATA=$(proxychains4 -q curl -s "$URL" -H "Accept: application/json")

if [ -z "$JSON_DATA" ]; then
    echo "Erro: Não foi possível obter dados JSON"
    exit 1
fi

echo "JSON obtido ($(echo "$JSON_DATA" | wc -c) caracteres)"

case "$TYPE" in
    "endpoints")
        echo -e "\n[ENDPOINTS ENCONTRADOS]"
        # Procurar URLs e paths
        echo "$JSON_DATA" | grep -oP '["'"'"'](https?://[^"'"'"']+|/[a-zA-Z0-9/_.-]+)["'"'"']' | \
        sed 's/["\x27]//g' | sort -u | grep -E "^(https?://|/)" | head -20
        
        # Procurar endpoints em propriedades
        echo -e "\n[PROPRIEDADES COM ENDPOINTS]"
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | $p + [getpath($p)] | @tsv' 2>/dev/null | \
        grep -E "(url|endpoint|api|path|route)" | head -10
        ;;
        
    "credentials")
        echo -e "\n[CREDENCIAIS ENCONTRADAS]"
        # Passwords
        echo "=== PASSWORDS ==="
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("password|pass|pwd"; "i")) | $p + [getpath($p)] | @tsv' 2>/dev/null
        
        # Usernames
        echo -e "\n=== USERNAMES ==="
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("user|username|login|email"; "i")) | $p + [getpath($p)] | @tsv' 2>/dev/null
        
        # API Keys
        echo -e "\n=== API KEYS ==="
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("key|token|secret|auth"; "i")) | $p + [getpath($p)] | @tsv' 2>/dev/null
        ;;
        
    "tokens")
        echo -e "\n[TOKENS ENCONTRADOS]"
        # JWT tokens
        echo "=== JWT TOKENS ==="
        echo "$JSON_DATA" | grep -oP 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+' | head -5
        
        # Bearer tokens
        echo -e "\n=== BEARER TOKENS ==="
        echo "$JSON_DATA" | grep -oP 'Bearer [A-Za-z0-9_-]+' | head -5
        
        # Access tokens
        echo -e "\n=== ACCESS TOKENS ==="
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("access_token|accessToken|bearer"; "i")) | getpath($p)' 2>/dev/null
        ;;
        
    "emails")
        echo -e "\n[EMAILS ENCONTRADOS]"
        echo "$JSON_DATA" | grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u | head -20
        ;;
        
    "ips")
        echo -e "\n[IPs ENCONTRADOS]"
        # IPv4
        echo "=== IPv4 ==="
        echo "$JSON_DATA" | grep -oP '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort -u | head -20
        
        # IPv6
        echo -e "\n=== IPv6 ==="
        echo "$JSON_DATA" | grep -oP '([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}' | sort -u | head -10
        ;;
        
    "domains")
        echo -e "\n[DOMÍNIOS ENCONTRADOS]"
        echo "$JSON_DATA" | grep -oP 'https?://([a-zA-Z0-9.-]+)' | sed 's|https\?://||' | sort -u | head -20
        
        # Domínios sem protocolo
        echo -e "\n[DOMÍNIOS SEM PROTOCOLO]"
        echo "$JSON_DATA" | grep -oP '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | grep -v '@' | sort -u | head -20
        ;;
        
    "keys")
        echo -e "\n[CHAVES E CONFIGURAÇÕES]"
        # Database configs
        echo "=== DATABASE ==="
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("db|database|mongo|mysql|postgres|redis"; "i")) | $p + [getpath($p)] | @tsv' 2>/dev/null
        
        # Server configs
        echo -e "\n=== SERVER ==="
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("host|port|server|url|endpoint"; "i")) | $p + [getpath($p)] | @tsv' 2>/dev/null
        
        # Security configs
        echo -e "\n=== SECURITY ==="
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("secret|key|token|auth|jwt|oauth"; "i")) | $p + [getpath($p)] | @tsv' 2>/dev/null
        ;;
        
    *)
        echo "Tipo não suportado: $TYPE"
        echo "Tipos disponíveis: endpoints, credentials, tokens, emails, ips, domains, keys"
        exit 1
        ;;
esac

# Salvar resultado
OUTPUT_FILE="/tmp/parsed_${TYPE}_$(date +%s).txt"
echo -e "\n[2] Salvando resultado em: $OUTPUT_FILE"

case "$TYPE" in
    "endpoints")
        echo "$JSON_DATA" | grep -oP '["'"'"'](https?://[^"'"'"']+|/[a-zA-Z0-9/_.-]+)["'"'"']' | sed 's/["\x27]//g' | sort -u > "$OUTPUT_FILE"
        ;;
    "credentials")
        echo "$JSON_DATA" | jq -r 'paths(scalars) as $p | select(($p | join(".")) | test("password|pass|pwd|user|username|key|token|secret|auth"; "i")) | $p + [getpath($p)] | @tsv' 2>/dev/null > "$OUTPUT_FILE"
        ;;
    "tokens")
        echo "$JSON_DATA" | grep -oP 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+' > "$OUTPUT_FILE"
        ;;
    "emails")
        echo "$JSON_DATA" | grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u > "$OUTPUT_FILE"
        ;;
    "ips")
        echo "$JSON_DATA" | grep -oP '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort -u > "$OUTPUT_FILE"
        ;;
    "domains")
        echo "$JSON_DATA" | grep -oP '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | grep -v '@' | sort -u > "$OUTPUT_FILE"
        ;;
esac

echo "Análise concluída!"