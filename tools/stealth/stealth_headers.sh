#!/bin/bash
# CYRAX STEALTH HEADERS - Anti-detecção total
echo "=== CYRAX STEALTH MODE - ZERO SIGNATURE ==="

# User-Agents de ferramentas conhecidas (para mascarar)
LEGIT_UAS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/121.0"
)

# Headers para parecer navegador real
get_stealth_headers() {
    local ua="${LEGIT_UAS[$RANDOM % ${#LEGIT_UAS[@]}]}"
    
    echo "-H 'User-Agent: $ua'"
    echo "-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'"
    echo "-H 'Accept-Language: en-US,en;q=0.5'"
    echo "-H 'Accept-Encoding: gzip, deflate, br'"
    echo "-H 'DNT: 1'"
    echo "-H 'Connection: keep-alive'"
    echo "-H 'Upgrade-Insecure-Requests: 1'"
    echo "-H 'Sec-Fetch-Dest: document'"
    echo "-H 'Sec-Fetch-Mode: navigate'"
    echo "-H 'Sec-Fetch-Site: none'"
    echo "-H 'Cache-Control: max-age=0'"
}

# Função para request stealth
stealth_request() {
    local url="$1"
    local method="${2:-GET}"
    
    local headers=$(get_stealth_headers)
    eval "proxychains4 -q curl -s -m 15 $headers '$url' 2>/dev/null"
}

# Exportar função
export -f stealth_request
export -f get_stealth_headers