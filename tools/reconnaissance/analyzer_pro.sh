#!/bin/bash
# ANALYZER PRO - Análise inteligente com IA e multi-threading
echo "=== ANALYZER PRO - AI POWERED ==="

TARGET="$1"
THREADS="${2:-10}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL> [THREADS]"
    echo "Exemplo: $0 https://target.com 15"
    exit 1
fi

DOMAIN=$(echo "$TARGET" | sed 's|https\?://||' | cut -d'/' -f1)
TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/analyzer_pro_$TIMESTAMP"
mkdir -p "$TEMP_DIR"

echo "🎯 Target: $TARGET"
echo "🧵 Threads: $THREADS"
echo "📁 Temp: $TEMP_DIR"

# Função para análise paralela
analyze_parallel() {
    local url="$1"
    local output_file="$2"
    
    {
        echo "=== ANÁLISE: $url ==="
        
        # Headers inteligentes
        headers=$(proxychains4 -q curl -s -I "$url" --connect-timeout 10 2>/dev/null)
        echo "HEADERS:"
        echo "$headers"
        
        # Detectar tecnologias
        echo -e "\nTECNOLOGIAS DETECTADAS:"
        echo "$headers" | grep -i "server:" | sed 's/server: //i'
        echo "$headers" | grep -i "x-powered-by:" | sed 's/x-powered-by: //i'
        echo "$headers" | grep -i "x-framework:" | sed 's/x-framework: //i'
        
        # Análise de conteúdo
        content=$(proxychains4 -q curl -s "$url" --connect-timeout 15 2>/dev/null)
        
        if [ -n "$content" ]; then
            # Detectar CMS
            echo -e "\nCMS DETECTION:"
            if echo "$content" | grep -qi "wp-content\|wordpress"; then
                echo "🔍 WordPress detectado"
                wp_version=$(echo "$content" | grep -o 'wp-includes/js/[^"]*' | head -1)
                echo "   Versão: $wp_version"
            fi
            
            if echo "$content" | grep -qi "joomla"; then
                echo "🔍 Joomla detectado"
            fi
            
            if echo "$content" | grep -qi "drupal"; then
                echo "🔍 Drupal detectado"
            fi
            
            # JavaScript analysis com IA
            echo -e "\nJAVASCRIPT INTELLIGENCE:"
            js_files=$(echo "$content" | grep -oP 'src="[^"]*\.js[^"]*"' | sed 's/src="//;s/"//' | head -10)
            
            if [ -n "$js_files" ]; then
                echo "$js_files" | while read js_file; do
                    if [[ "$js_file" == /* ]]; then
                        js_url="$TARGET$js_file"
                    elif [[ "$js_file" == http* ]]; then
                        js_url="$js_file"
                    else
                        js_url="$TARGET/$js_file"
                    fi
                    
                    echo "📄 Analisando: $js_file"
                    js_content=$(proxychains4 -q curl -s "$js_url" --connect-timeout 10 2>/dev/null)
                    
                    if [ -n "$js_content" ]; then
                        # Endpoints com IA
                        endpoints=$(echo "$js_content" | grep -oP '["\x27]/[a-zA-Z0-9/_.-]+["\x27]' | sed 's/["\x27]//g' | sort -u | head -15)
                        if [ -n "$endpoints" ]; then
                            echo "   🔗 Endpoints: $(echo "$endpoints" | tr '\n' ' ')"
                        fi
                        
                        # Credenciais
                        creds=$(echo "$js_content" | grep -oiP '(password|token|key|secret|api)["\s]*[:=]["\s]*[^"\s,}]{3,20}' | head -5)
                        if [ -n "$creds" ]; then
                            echo "   🔑 Possíveis credenciais: $creds"
                        fi
                        
                        # URLs externas
                        external_urls=$(echo "$js_content" | grep -oP 'https?://[^"'\'']+' | grep -v "$DOMAIN" | sort -u | head -5)
                        if [ -n "$external_urls" ]; then
                            echo "   🌐 URLs externas: $(echo "$external_urls" | tr '\n' ' ')"
                        fi
                    fi
                done
            fi
            
            # Formulários inteligentes
            echo -e "\nFORM ANALYSIS:"
            forms=$(echo "$content" | grep -oiP '<form[^>]*action="[^"]*"[^>]*>' | head -5)
            if [ -n "$forms" ]; then
                echo "$forms" | while read form; do
                    action=$(echo "$form" | grep -oP 'action="[^"]*"' | sed 's/action="//;s/"//')
                    method=$(echo "$form" | grep -oP 'method="[^"]*"' | sed 's/method="//;s/"//' | tr '[:lower:]' '[:upper:]')
                    echo "📝 Form: $action (${method:-GET})"
                done
            fi
            
            # Comentários HTML com segredos
            echo -e "\nHTML COMMENTS:"
            comments=$(echo "$content" | grep -oP '<!--.*?-->' | head -10)
            if [ -n "$comments" ]; then
                echo "$comments" | while read comment; do
                    if echo "$comment" | grep -qi "password\|key\|secret\|todo\|bug\|test"; then
                        echo "💬 Interessante: $comment"
                    fi
                done
            fi
        fi
        
    } > "$output_file" 2>&1
}

# Lista de URLs para testar
URLS=(
    "$TARGET"
    "$TARGET/admin"
    "$TARGET/login"
    "$TARGET/api"
    "$TARGET/config"
    "$TARGET/test"
    "$TARGET/dev"
    "$TARGET/backup"
    "$TARGET/robots.txt"
    "$TARGET/sitemap.xml"
    "$TARGET/.env"
    "$TARGET/config.json"
    "$TARGET/package.json"
    "$TARGET/composer.json"
    "$TARGET/.git/config"
)

# Adicionar subdomínios comuns
SUBDOMAINS=("www" "api" "admin" "test" "dev" "staging" "mail" "blog")
for sub in "${SUBDOMAINS[@]}"; do
    URLS+=("https://$sub.$DOMAIN")
    URLS+=("http://$sub.$DOMAIN")
done

echo -e "\n🚀 Iniciando análise paralela de ${#URLS[@]} URLs..."

# Executar análises em paralelo
pids=()
for i in "${!URLS[@]}"; do
    url="${URLS[$i]}"
    output_file="$TEMP_DIR/analysis_$i.txt"
    
    analyze_parallel "$url" "$output_file" &
    pids+=($!)
    
    # Controlar número de threads
    if [ ${#pids[@]} -ge $THREADS ]; then
        wait ${pids[0]}
        pids=("${pids[@]:1}")
    fi
done

# Aguardar todos terminarem
for pid in "${pids[@]}"; do
    wait $pid
done

echo "✅ Análise paralela concluída!"

# Consolidar resultados com IA
echo -e "\n🧠 Consolidando resultados com IA..."

FINAL_REPORT="$TEMP_DIR/CONSOLIDATED_REPORT.txt"

cat > "$FINAL_REPORT" <<EOF
ANALYZER PRO - RELATÓRIO INTELIGENTE
===================================
Target: $TARGET
Timestamp: $(date)
URLs analisadas: ${#URLS[@]}

EOF

# Análise inteligente dos resultados
echo "🔍 DESCOBERTAS CRÍTICAS:" >> "$FINAL_REPORT"
grep -h "🔑\|💬\|🔍" "$TEMP_DIR"/analysis_*.txt | sort -u >> "$FINAL_REPORT"

echo -e "\n📊 TECNOLOGIAS IDENTIFICADAS:" >> "$FINAL_REPORT"
grep -h "server:\|x-powered-by:\|WordPress\|Joomla\|Drupal" "$TEMP_DIR"/analysis_*.txt | sort -u >> "$FINAL_REPORT"

echo -e "\n🔗 ENDPOINTS DESCOBERTOS:" >> "$FINAL_REPORT"
grep -h "Endpoints:" "$TEMP_DIR"/analysis_*.txt | sed 's/.*Endpoints: //' | tr ' ' '\n' | sort -u | head -20 >> "$FINAL_REPORT"

echo -e "\n🌐 URLs EXTERNAS:" >> "$FINAL_REPORT"
grep -h "URLs externas:" "$TEMP_DIR"/analysis_*.txt | sed 's/.*URLs externas: //' | tr ' ' '\n' | sort -u | head -15 >> "$FINAL_REPORT"

echo -e "\n📝 FORMULÁRIOS:" >> "$FINAL_REPORT"
grep -h "Form:" "$TEMP_DIR"/analysis_*.txt | sort -u >> "$FINAL_REPORT"

# Scoring inteligente
SCORE=0
if grep -q "WordPress\|Joomla\|Drupal" "$FINAL_REPORT"; then
    SCORE=$((SCORE + 20))
fi

if grep -q "🔑" "$FINAL_REPORT"; then
    SCORE=$((SCORE + 50))
fi

if grep -q "admin\|login" "$FINAL_REPORT"; then
    SCORE=$((SCORE + 30))
fi

echo -e "\n🎯 SCORE DE INTERESSE: $SCORE/100" >> "$FINAL_REPORT"

if [ $SCORE -gt 70 ]; then
    echo "🔥 ALVO ALTAMENTE INTERESSANTE!" >> "$FINAL_REPORT"
elif [ $SCORE -gt 40 ]; then
    echo "⚠️  Alvo com potencial" >> "$FINAL_REPORT"
else
    echo "ℹ️  Alvo padrão" >> "$FINAL_REPORT"
fi

# Mostrar resultado
echo -e "\n📋 RELATÓRIO FINAL:"
cat "$FINAL_REPORT"

echo -e "\n📁 Arquivos detalhados em: $TEMP_DIR"
echo "🎯 Score final: $SCORE/100"

# Sugestões automáticas
echo -e "\n💡 PRÓXIMOS PASSOS SUGERIDOS:"
if grep -q "WordPress" "$FINAL_REPORT"; then
    echo "   → Executar: wpscan --url $TARGET"
fi

if grep -q "admin\|login" "$FINAL_REPORT"; then
    echo "   → Executar: ./brute.sh http $TARGET/login"
    echo "   → Executar: ./bypass.sh $TARGET/admin"
fi

if grep -q "🔑" "$FINAL_REPORT"; then
    echo "   → Investigar credenciais encontradas manualmente"
fi

if grep -q "/api" "$FINAL_REPORT"; then
    echo "   → Executar: ./parser.sh $TARGET/api endpoints"
fi