#!/bin/bash
# CYRAX OPSEC CHECKER - Verifica segurança operacional
echo "=== CYRAX OPSEC CHECKER ==="

TEMP_DIR="/tmp/cyrax_opsec_$(date +%s)"
mkdir -p "$TEMP_DIR"

# Verificar vazamentos de IP
check_ip_leaks() {
    echo "🔍 Verificando vazamentos de IP..."
    
    # IP real
    local real_ip=$(curl -s --connect-timeout 5 http://httpbin.org/ip 2>/dev/null | jq -r '.origin' 2>/dev/null)
    
    # IP via Tor
    local tor_ip=$(proxychains4 -q curl -s --connect-timeout 10 http://httpbin.org/ip 2>/dev/null | jq -r '.origin' 2>/dev/null)
    
    if [ -n "$real_ip" ] && [ -n "$tor_ip" ]; then
        if [ "$real_ip" = "$tor_ip" ]; then
            echo "⚠️  VAZAMENTO DE IP: Tor não está funcionando!"
            echo "IP_LEAK:$real_ip" >> "$TEMP_DIR/opsec_issues.txt"
        else
            echo "✅ IP mascarado: $real_ip -> $tor_ip"
        fi
    fi
}

# Verificar DNS leaks
check_dns_leaks() {
    echo "🔍 Verificando vazamentos de DNS..."
    
    # Verificar se DNS está sendo roteado pelo Tor
    local dns_test=$(proxychains4 -q nslookup google.com 2>&1 | grep -i "server")
    
    if echo "$dns_test" | grep -q "127.0.0.1\|localhost"; then
        echo "✅ DNS roteado localmente"
    else
        echo "⚠️  POSSÍVEL VAZAMENTO DE DNS"
        echo "DNS_LEAK" >> "$TEMP_DIR/opsec_issues.txt"
    fi
}

# Verificar logs do sistema
check_system_logs() {
    echo "🔍 Verificando logs do sistema..."
    
    # Verificar se há logs recentes das nossas atividades
    local recent_logs=$(journalctl --since "1 hour ago" 2>/dev/null | grep -i "cyrax\|nmap\|sqlmap\|nikto" | wc -l)
    
    if [ "$recent_logs" -gt 0 ]; then
        echo "⚠️  LOGS SUSPEITOS ENCONTRADOS: $recent_logs entradas"
        echo "SYSTEM_LOGS:$recent_logs" >> "$TEMP_DIR/opsec_issues.txt"
    else
        echo "✅ Logs limpos"
    fi
}

# Verificar histórico de comandos
check_command_history() {
    echo "🔍 Verificando histórico de comandos..."
    
    local suspicious_cmds=$(history | grep -i "nmap\|sqlmap\|nikto\|hydra\|john\|hashcat" | wc -l)
    
    if [ "$suspicious_cmds" -gt 0 ]; then
        echo "⚠️  COMANDOS SUSPEITOS NO HISTÓRICO: $suspicious_cmds"
        echo "CMD_HISTORY:$suspicious_cmds" >> "$TEMP_DIR/opsec_issues.txt"
    else
        echo "✅ Histórico limpo"
    fi
}

# Verificar processos suspeitos
check_suspicious_processes() {
    echo "🔍 Verificando processos suspeitos..."
    
    local suspicious_procs=("nmap" "sqlmap" "nikto" "hydra" "john" "hashcat" "metasploit")
    local found_procs=0
    
    for proc in "${suspicious_procs[@]}"; do
        if pgrep -f "$proc" >/dev/null 2>&1; then
            echo "⚠️  PROCESSO SUSPEITO ATIVO: $proc"
            echo "SUSPICIOUS_PROC:$proc" >> "$TEMP_DIR/opsec_issues.txt"
            found_procs=$((found_procs + 1))
        fi
    done
    
    if [ "$found_procs" -eq 0 ]; then
        echo "✅ Nenhum processo suspeito ativo"
    fi
}

# Verificar arquivos temporários
check_temp_files() {
    echo "🔍 Verificando arquivos temporários..."
    
    local temp_files=$(find /tmp -name "*cyrax*" -o -name "*nmap*" -o -name "*sqlmap*" 2>/dev/null | wc -l)
    
    if [ "$temp_files" -gt 0 ]; then
        echo "⚠️  ARQUIVOS TEMPORÁRIOS SUSPEITOS: $temp_files"
        echo "TEMP_FILES:$temp_files" >> "$TEMP_DIR/opsec_issues.txt"
    else
        echo "✅ Arquivos temporários limpos"
    fi
}

# Verificar conexões de rede ativas
check_network_connections() {
    echo "🔍 Verificando conexões de rede..."
    
    local suspicious_connections=$(netstat -tuln 2>/dev/null | grep -E ":4444|:1337|:31337|:8080" | wc -l)
    
    if [ "$suspicious_connections" -gt 0 ]; then
        echo "⚠️  CONEXÕES SUSPEITAS: $suspicious_connections"
        echo "SUSPICIOUS_CONN:$suspicious_connections" >> "$TEMP_DIR/opsec_issues.txt"
    else
        echo "✅ Conexões normais"
    fi
}

# Executar verificações
check_ip_leaks
check_dns_leaks
check_system_logs
check_command_history
check_suspicious_processes
check_temp_files
check_network_connections

# Gerar relatório
echo ""
echo "📊 RELATÓRIO OPSEC:"

if [ -f "$TEMP_DIR/opsec_issues.txt" ]; then
    local issue_count=$(wc -l < "$TEMP_DIR/opsec_issues.txt")
    echo "⚠️  $issue_count PROBLEMAS DE OPSEC ENCONTRADOS!"
    echo ""
    echo "🛠️  AÇÕES RECOMENDADAS:"
    
    if grep -q "IP_LEAK" "$TEMP_DIR/opsec_issues.txt"; then
        echo "• Reiniciar Tor: sudo systemctl restart tor"
    fi
    
    if grep -q "DNS_LEAK" "$TEMP_DIR/opsec_issues.txt"; then
        echo "• Configurar DNS no proxychains4"
    fi
    
    if grep -q "SYSTEM_LOGS" "$TEMP_DIR/opsec_issues.txt"; then
        echo "• Limpar logs: sudo journalctl --vacuum-time=1d"
    fi
    
    if grep -q "CMD_HISTORY" "$TEMP_DIR/opsec_issues.txt"; then
        echo "• Limpar histórico: history -c && history -w"
    fi
    
    if grep -q "TEMP_FILES" "$TEMP_DIR/opsec_issues.txt"; then
        echo "• Limpar /tmp: rm -rf /tmp/*cyrax* /tmp/*nmap*"
    fi
    
else
    echo "✅ OPSEC SEGURO - Nenhum problema encontrado!"
fi

echo ""
echo "Detalhes em: $TEMP_DIR"