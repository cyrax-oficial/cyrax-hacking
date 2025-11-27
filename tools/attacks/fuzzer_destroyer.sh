#!/bin/bash
# CYRAX FUZZER DESTROYER - Fuzzer definitivo mais rápido que ffuf
echo "=== CYRAX FUZZER DESTROYER - ULTIMATE FAST FUZZER ==="

TARGET="$1"
WORDLIST="$2"
THREADS="${3:-50}"
MODE="${4:-dir}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL> [WORDLIST] [THREADS] [MODE]"
    echo "Modos: dir, file, param, vhost, all"
    echo "Wordlists builtin: financial, api, admin, database"
    echo "Exemplo: $0 https://site.com financial 50 dir"
    exit 1
fi

# Wordlist padrão
if [ -z "$WORDLIST" ]; then
    WORDLIST="financial"
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/cyrax_fuzz_$TIMESTAMP"
mkdir -p "$TEMP_DIR"

echo "🎯 Target: $TARGET"
echo "📝 Wordlist: $WORDLIST"
echo "🧵 Threads: $THREADS"
echo "🔧 Mode: $MODE"
echo "📁 Output: $TEMP_DIR"

# Criar wordlists builtin
case "$WORDLIST" in
    "financial")
        WORDLIST="$TEMP_DIR/financial.txt"
        cat > "$WORDLIST" <<'WEOF'
reports
perfin
companies
plans
alerts
users
my-profile
credit
transactions
payments
invoices
balance
financial
finance
accounts
billing
WEOF
        ;;
    "api")
        WORDLIST="$TEMP_DIR/api.txt"
        cat > "$WORDLIST" <<'WEOF'
api
v1
v2
v3
graphql
swagger
docs
api-docs
openapi.json
health
status
version
metrics
WEOF
        ;;
    "admin")
        WORDLIST="$TEMP_DIR/admin.txt"
        cat > "$WORDLIST" <<'WEOF'
admin
administrator
manager
panel
dashboard
console
backend
cp
control
WEOF
        ;;
    "database")
        WORDLIST="$TEMP_DIR/database.txt"
        cat > "$WORDLIST" <<'WEOF'
users
accounts
customers
passwords
credentials
login
auth
tokens
sessions
WEOF
        ;;
esac

# Verificar se wordlist existe
if [ ! -f "$WORDLIST" ]; then
    echo "❌ Wordlist não encontrada: $WORDLIST"
    exit 1
fi

# Função para logging
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "SUCCESS") echo "🎉 [$timestamp] $msg" | tee -a "$TEMP_DIR/fuzzer.log" ;;
        "FOUND") echo "🔍 [$timestamp] $msg" | tee -a "$TEMP_DIR/fuzzer.log" ;;
        "INFO") echo "ℹ️  [$timestamp] $msg" | tee -a "$TEMP_DIR/fuzzer.log" ;;
        "CRITICAL") echo "🔥 [$timestamp] $msg" | tee -a "$TEMP_DIR/fuzzer.log" ;;
    esac
}

# Função para fazer request otimizado
make_fast_request() {
    local url="$1"
    local method="${2:-GET}"
    
    # Pool de User-Agents para rotação
    local user_agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        "Mozilla/5.0 (compatible; Googlebot/2.1)"
        "Mozilla/5.0 (compatible; Bingbot/2.0)"
    )
    
    local ua="${user_agents[$RANDOM % ${#user_agents[@]}]}"
    
    # Request otimizado com timeouts agressivos
    proxychains4 -q curl -s -m 8 --connect-timeout 5 --max-time 8 \
        -H "User-Agent: $ua" \
        -H "Accept: */*" \
        -H "Connection: close" \
        -w "%{http_code}|%{size_download}|%{time_total}" \
        -o /dev/null \
        "$url" 2>/dev/null
}

# Obter baseline do target
get_baseline() {
    log "INFO" "Obtendo baseline do target"
    
    # Testar página inexistente para obter 404 padrão
    local random_string=$(openssl rand -hex 16)
    local test_404_url="$TARGET/$random_string"
    
    local baseline_404=$(make_fast_request "$test_404_url")
    local status_404=$(echo "$baseline_404" | cut -d'|' -f1)
    local size_404=$(echo "$baseline_404" | cut -d'|' -f2)
    
    echo "$status_404:$size_404" > "$TEMP_DIR/baseline_404.txt"
    log "INFO" "Baseline 404: HTTP $status_404 ($size_404 bytes)"
    
    # Testar página principal para obter 200 padrão
    local baseline_200=$(make_fast_request "$TARGET/")
    local status_200=$(echo "$baseline_200" | cut -d'|' -f1)
    local size_200=$(echo "$baseline_200" | cut -d'|' -f2)
    
    echo "$status_200:$size_200" > "$TEMP_DIR/baseline_200.txt"
    log "INFO" "Baseline 200: HTTP $status_200 ($size_200 bytes)"
}

# Fuzzing de diretórios ultra rápido
fuzz_directories() {
    log "INFO" "Iniciando fuzzing de diretórios CYRAX"
    
    # Ler baseline
    local baseline_404=$(cat "$TEMP_DIR/baseline_404.txt" 2>/dev/null || echo "404:0")
    local baseline_404_status=$(echo "$baseline_404" | cut -d':' -f1)
    local baseline_404_size=$(echo "$baseline_404" | cut -d':' -f2)
    
    # Função de fuzzing paralelo
    fuzz_worker() {
        local word="$1"
        local worker_id="$2"
        
        # Testar diferentes variações
        local test_urls=(
            "$TARGET/$word"
            "$TARGET/$word/"
            "$TARGET/${word}.php"
            "$TARGET/${word}.html"
            "$TARGET/${word}.asp"
            "$TARGET/${word}.aspx"
            "$TARGET/${word}.jsp"
        )
        
        for test_url in "${test_urls[@]}"; do
            local result=$(make_fast_request "$test_url")
            local status=$(echo "$result" | cut -d'|' -f1)
            local size=$(echo "$result" | cut -d'|' -f2)
            local time=$(echo "$result" | cut -d'|' -f3)
            
            # Filtrar resultados interessantes
            if [ "$status" != "$baseline_404_status" ] && [ "$status" != "000" ]; then
                # Verificar se não é falso positivo por tamanho
                local size_diff=$((size - baseline_404_size))
                if [ ${size_diff#-} -gt 50 ]; then  # Diferença significativa
                    echo "$status|$size|$time|$test_url" >> "$TEMP_DIR/results_worker_$worker_id.txt"
                    log "FOUND" "[$worker_id] $test_url -> HTTP $status ($size bytes)"
                fi
            fi
        done
    }
    
    # Dividir wordlist em chunks para processamento paralelo
    local total_words=$(wc -l < "$WORDLIST")
    local chunk_size=$((total_words / THREADS + 1))
    
    log "INFO" "Processando $total_words palavras em $THREADS threads ($chunk_size por thread)"
    
    # Criar chunks da wordlist
    split -l "$chunk_size" "$WORDLIST" "$TEMP_DIR/chunk_"
    
    # Processar chunks em paralelo
    local pids=()
    local worker_id=0
    
    for chunk_file in "$TEMP_DIR"/chunk_*; do
        {
            while IFS= read -r word; do
                if [ -n "$word" ]; then
                    fuzz_worker "$word" "$worker_id"
                fi
            done < "$chunk_file"
        } &
        
        pids+=($!)
        worker_id=$((worker_id + 1))
        
        # Controlar número de processos
        if [ ${#pids[@]} -ge "$THREADS" ]; then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")
        fi
    done
    
    # Aguardar todos os workers
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Consolidar resultados
    cat "$TEMP_DIR"/results_worker_*.txt 2>/dev/null | sort -t'|' -k1,1nr > "$TEMP_DIR/dir_results.txt"
    
    # Limpar arquivos temporários
    rm -f "$TEMP_DIR"/chunk_* "$TEMP_DIR"/results_worker_*.txt
}

# Fuzzing de arquivos
fuzz_files() {
    log "INFO" "Iniciando fuzzing de arquivos"
    
    # Extensões comuns para testar
    local extensions=(
        "php" "html" "htm" "asp" "aspx" "jsp" "js" "css" "txt" "xml"
        "json" "pdf" "doc" "docx" "xls" "xlsx" "zip" "rar" "tar" "gz"
        "sql" "db" "bak" "backup" "old" "orig" "tmp" "log" "conf" "config"
    )
    
    # Função de fuzzing de arquivos
    fuzz_files_worker() {
        local word="$1"
        local worker_id="$2"
        
        # Testar palavra base
        local base_result=$(make_fast_request "$TARGET/$word")
        local base_status=$(echo "$base_result" | cut -d'|' -f1)
        local base_size=$(echo "$base_result" | cut -d'|' -f2)
        
        if [ "$base_status" = "200" ] || [ "$base_status" = "301" ] || [ "$base_status" = "302" ]; then
            echo "$base_status|$base_size|$TARGET/$word" >> "$TEMP_DIR/file_results_worker_$worker_id.txt"
        fi
        
        # Testar com extensões
        for ext in "${extensions[@]}"; do
            local file_url="$TARGET/$word.$ext"
            local result=$(make_fast_request "$file_url")
            local status=$(echo "$result" | cut -d'|' -f1)
            local size=$(echo "$result" | cut -d'|' -f2)
            
            if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
                echo "$status|$size|$file_url" >> "$TEMP_DIR/file_results_worker_$worker_id.txt"
                log "FOUND" "[$worker_id] $file_url -> HTTP $status ($size bytes)"
            fi
        done
    }
    
    # Processar em paralelo
    local pids=()
    local worker_id=0
    
    while IFS= read -r word; do
        if [ -n "$word" ]; then
            fuzz_files_worker "$word" "$worker_id" &
            pids+=($!)
            worker_id=$((worker_id + 1))
            
            # Controlar threads
            if [ ${#pids[@]} -ge "$THREADS" ]; then
                wait "${pids[0]}"
                pids=("${pids[@]:1}")
            fi
        fi
    done < "$WORDLIST"
    
    # Aguardar todos
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Consolidar resultados
    cat "$TEMP_DIR"/file_results_worker_*.txt 2>/dev/null | sort -t'|' -k1,1nr > "$TEMP_DIR/file_results.txt"
    rm -f "$TEMP_DIR"/file_results_worker_*.txt
}

# Fuzzing de parâmetros
fuzz_parameters() {
    log "INFO" "Iniciando fuzzing de parâmetros"
    
    # Valores de teste para parâmetros
    local test_values=(
        "1"
        "test"
        "admin"
        "true"
        "false"
        "../../../etc/passwd"
        "' OR '1'='1"
        "<script>alert(1)</script>"
        "{{7*7}}"
        "\${7*7}"
    )
    
    # Função de fuzzing de parâmetros
    fuzz_param_worker() {
        local param="$1"
        local worker_id="$2"
        
        for value in "${test_values[@]}"; do
            # Testar GET
            local get_url="$TARGET?$param=$value"
            local get_result=$(make_fast_request "$get_url")
            local get_status=$(echo "$get_result" | cut -d'|' -f1)
            local get_size=$(echo "$get_result" | cut -d'|' -f2)
            
            if [ "$get_status" = "200" ] && [ "$get_size" -gt 100 ]; then
                echo "GET|$get_status|$get_size|$get_url" >> "$TEMP_DIR/param_results_worker_$worker_id.txt"
                log "FOUND" "[$worker_id] Parâmetro GET: $param=$value -> HTTP $get_status"
            fi
            
            # Testar POST
            local post_result=$(proxychains4 -q curl -s -m 8 --connect-timeout 5 \
                -X POST -d "$param=$value" \
                -H "Content-Type: application/x-www-form-urlencoded" \
                -w "%{http_code}|%{size_download}" \
                -o /dev/null \
                "$TARGET" 2>/dev/null)
            
            local post_status=$(echo "$post_result" | cut -d'|' -f1)
            local post_size=$(echo "$post_result" | cut -d'|' -f2)
            
            if [ "$post_status" = "200" ] && [ "$post_size" -gt 100 ]; then
                echo "POST|$post_status|$post_size|$param=$value" >> "$TEMP_DIR/param_results_worker_$worker_id.txt"
                log "FOUND" "[$worker_id] Parâmetro POST: $param=$value -> HTTP $post_status"
            fi
        done
    }
    
    # Processar em paralelo
    local pids=()
    local worker_id=0
    
    while IFS= read -r param; do
        if [ -n "$param" ]; then
            fuzz_param_worker "$param" "$worker_id" &
            pids+=($!)
            worker_id=$((worker_id + 1))
            
            if [ ${#pids[@]} -ge "$THREADS" ]; then
                wait "${pids[0]}"
                pids=("${pids[@]:1}")
            fi
        fi
    done < "$WORDLIST"
    
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Consolidar resultados
    cat "$TEMP_DIR"/param_results_worker_*.txt 2>/dev/null > "$TEMP_DIR/param_results.txt"
    rm -f "$TEMP_DIR"/param_results_worker_*.txt
}

# Fuzzing de virtual hosts
fuzz_vhosts() {
    log "INFO" "Iniciando fuzzing de virtual hosts"
    
    # Extrair domínio base
    local base_domain=$(echo "$TARGET" | sed 's|https\?://||' | cut -d'/' -f1)
    
    # Função de fuzzing de vhosts
    fuzz_vhost_worker() {
        local subdomain="$1"
        local worker_id="$2"
        
        local vhost_domain="$subdomain.$base_domain"
        
        # Testar com Host header
        local result=$(proxychains4 -q curl -s -m 8 --connect-timeout 5 \
            -H "Host: $vhost_domain" \
            -w "%{http_code}|%{size_download}" \
            -o /dev/null \
            "$TARGET" 2>/dev/null)
        
        local status=$(echo "$result" | cut -d'|' -f1)
        local size=$(echo "$result" | cut -d'|' -f2)
        
        if [ "$status" = "200" ] && [ "$size" -gt 100 ]; then
            echo "$status|$size|$vhost_domain" >> "$TEMP_DIR/vhost_results_worker_$worker_id.txt"
            log "FOUND" "[$worker_id] VHost: $vhost_domain -> HTTP $status ($size bytes)"
        fi
        
        # Testar acesso direto se possível
        local direct_result=$(make_fast_request "https://$vhost_domain")
        local direct_status=$(echo "$direct_result" | cut -d'|' -f1)
        local direct_size=$(echo "$direct_result" | cut -d'|' -f2)
        
        if [ "$direct_status" = "200" ] && [ "$direct_size" -gt 100 ]; then
            echo "$direct_status|$direct_size|https://$vhost_domain" >> "$TEMP_DIR/vhost_results_worker_$worker_id.txt"
            log "FOUND" "[$worker_id] VHost direto: https://$vhost_domain -> HTTP $direct_status"
        fi
    }
    
    # Processar em paralelo
    local pids=()
    local worker_id=0
    
    while IFS= read -r subdomain; do
        if [ -n "$subdomain" ]; then
            fuzz_vhost_worker "$subdomain" "$worker_id" &
            pids+=($!)
            worker_id=$((worker_id + 1))
            
            if [ ${#pids[@]} -ge "$THREADS" ]; then
                wait "${pids[0]}"
                pids=("${pids[@]:1}")
            fi
        fi
    done < "$WORDLIST"
    
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Consolidar resultados
    cat "$TEMP_DIR"/vhost_results_worker_*.txt 2>/dev/null > "$TEMP_DIR/vhost_results.txt"
    rm -f "$TEMP_DIR"/vhost_results_worker_*.txt
}

# Gerar relatório final
generate_report() {
    log "INFO" "Gerando relatório final"
    
    local report_file="$TEMP_DIR/CYRAX_FUZZER_REPORT.md"
    
    cat > "$report_file" <<EOF
# CYRAX FUZZER DESTROYER - RELATÓRIO FINAL

**Target:** $TARGET  
**Wordlist:** $WORDLIST  
**Threads:** $THREADS  
**Mode:** $MODE  
**Timestamp:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 RESUMO EXECUTIVO

EOF
    
    # Contar resultados
    local dir_count=0
    local file_count=0
    local param_count=0
    local vhost_count=0
    
    [ -f "$TEMP_DIR/dir_results.txt" ] && dir_count=$(wc -l < "$TEMP_DIR/dir_results.txt")
    [ -f "$TEMP_DIR/file_results.txt" ] && file_count=$(wc -l < "$TEMP_DIR/file_results.txt")
    [ -f "$TEMP_DIR/param_results.txt" ] && param_count=$(wc -l < "$TEMP_DIR/param_results.txt")
    [ -f "$TEMP_DIR/vhost_results.txt" ] && vhost_count=$(wc -l < "$TEMP_DIR/vhost_results.txt")
    
    echo "- **Diretórios encontrados:** $dir_count" >> "$report_file"
    echo "- **Arquivos encontrados:** $file_count" >> "$report_file"
    echo "- **Parâmetros encontrados:** $param_count" >> "$report_file"
    echo "- **VHosts encontrados:** $vhost_count" >> "$report_file"
    
    # Adicionar resultados detalhados
    if [ $dir_count -gt 0 ]; then
        echo -e "\n## 📁 DIRETÓRIOS ENCONTRADOS" >> "$report_file"
        echo '```' >> "$report_file"
        head -20 "$TEMP_DIR/dir_results.txt" | while IFS='|' read -r status size time url; do
            echo "HTTP $status ($size bytes) - $url"
        done >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ $file_count -gt 0 ]; then
        echo -e "\n## 📄 ARQUIVOS ENCONTRADOS" >> "$report_file"
        echo '```' >> "$report_file"
        head -20 "$TEMP_DIR/file_results.txt" | while IFS='|' read -r status size url; do
            echo "HTTP $status ($size bytes) - $url"
        done >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ $param_count -gt 0 ]; then
        echo -e "\n## 🔧 PARÂMETROS ENCONTRADOS" >> "$report_file"
        echo '```' >> "$report_file"
        head -20 "$TEMP_DIR/param_results.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    if [ $vhost_count -gt 0 ]; then
        echo -e "\n## 🌐 VHOSTS ENCONTRADOS" >> "$report_file"
        echo '```' >> "$report_file"
        head -20 "$TEMP_DIR/vhost_results.txt" | while IFS='|' read -r status size vhost; do
            echo "HTTP $status ($size bytes) - $vhost"
        done >> "$report_file"
        echo '```' >> "$report_file"
    fi
    
    echo -e "\n## 📁 ARQUIVOS GERADOS" >> "$report_file"
    echo "Todos os arquivos estão em: \`$TEMP_DIR\`" >> "$report_file"
    
    # Mostrar relatório
    echo -e "\n📊 RELATÓRIO FINAL:"
    cat "$report_file"
    
    # Resumo no terminal
    echo -e "\n🎯 RESUMO:"
    echo "📁 Diretórios: $dir_count"
    echo "📄 Arquivos: $file_count"
    echo "🔧 Parâmetros: $param_count"
    echo "🌐 VHosts: $vhost_count"
    echo "⏱️  Tempo total: $SECONDS segundos"
    
    local total_found=$((dir_count + file_count + param_count + vhost_count))
    if [ $total_found -gt 0 ]; then
        echo -e "\n🔥 TOTAL ENCONTRADO: $total_found itens!"
    fi
}

# Obter baseline
get_baseline

# Execução principal baseada no modo
case "$MODE" in
    "dir")
        fuzz_directories
        ;;
    "file")
        fuzz_files
        ;;
    "param")
        fuzz_parameters
        ;;
    "vhost")
        fuzz_vhosts
        ;;
    "all")
        fuzz_directories
        fuzz_files
        fuzz_parameters
        fuzz_vhosts
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ CYRAX FUZZER DESTROYER CONCLUÍDO!"
echo "📁 Resultados em: $TEMP_DIR"