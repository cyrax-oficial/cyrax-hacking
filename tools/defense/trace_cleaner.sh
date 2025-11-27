#!/bin/bash
# CYRAX TRACE CLEANER - Limpa rastros e evidências
echo "=== CYRAX TRACE CLEANER ==="

if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Execute como root para limpeza completa"
    echo "Uso: sudo $0"
fi

# Limpar logs do sistema
clean_system_logs() {
    echo "🧹 Limpando logs do sistema..."
    
    if [ "$EUID" -eq 0 ]; then
        # Limpar journalctl
        journalctl --vacuum-time=1h >/dev/null 2>&1
        
        # Limpar logs específicos
        > /var/log/auth.log
        > /var/log/syslog
        > /var/log/kern.log
        > /var/log/daemon.log
        > /var/log/user.log
        
        echo "✅ Logs do sistema limpos"
    else
        echo "⚠️  Requer root para limpar logs do sistema"
    fi
}

# Limpar histórico de comandos
clean_command_history() {
    echo "🧹 Limpando histórico de comandos..."
    
    # Bash history
    history -c
    history -w
    > ~/.bash_history
    
    # Zsh history
    > ~/.zsh_history 2>/dev/null
    
    # Fish history
    rm -rf ~/.local/share/fish/fish_history 2>/dev/null
    
    echo "✅ Histórico de comandos limpo"
}

# Limpar arquivos temporários
clean_temp_files() {
    echo "🧹 Limpando arquivos temporários..."
    
    # Arquivos CYRAX
    rm -rf /tmp/*cyrax* 2>/dev/null
    rm -rf /tmp/*nmap* 2>/dev/null
    rm -rf /tmp/*sqlmap* 2>/dev/null
    rm -rf /tmp/*nikto* 2>/dev/null
    rm -rf /tmp/*hydra* 2>/dev/null
    
    # Arquivos de reconhecimento
    rm -rf /tmp/recon_* 2>/dev/null
    rm -rf /tmp/analyzer_* 2>/dev/null
    rm -rf /tmp/brute_* 2>/dev/null
    rm -rf /tmp/exploit_* 2>/dev/null
    
    echo "✅ Arquivos temporários limpos"
}

# Limpar cache DNS
clean_dns_cache() {
    echo "🧹 Limpando cache DNS..."
    
    if [ "$EUID" -eq 0 ]; then
        # systemd-resolved
        systemctl flush-dns 2>/dev/null
        
        # nscd
        nscd -i hosts 2>/dev/null
        
        echo "✅ Cache DNS limpo"
    else
        echo "⚠️  Requer root para limpar cache DNS"
    fi
}

# Limpar conexões de rede
clean_network_connections() {
    echo "🧹 Limpando conexões de rede..."
    
    # Matar conexões suspeitas
    local suspicious_ports=(4444 1337 31337 8080 8443)
    
    for port in "${suspicious_ports[@]}"; do
        local pids=$(lsof -ti:$port 2>/dev/null)
        if [ -n "$pids" ]; then
            kill -9 $pids 2>/dev/null
            echo "🔪 Conexão na porta $port terminada"
        fi
    done
    
    echo "✅ Conexões limpas"
}

# Limpar processos suspeitos
clean_suspicious_processes() {
    echo "🧹 Terminando processos suspeitos..."
    
    local suspicious_procs=("nmap" "sqlmap" "nikto" "hydra" "john" "hashcat")
    
    for proc in "${suspicious_procs[@]}"; do
        local pids=$(pgrep -f "$proc" 2>/dev/null)
        if [ -n "$pids" ]; then
            kill -9 $pids 2>/dev/null
            echo "🔪 Processo $proc terminado"
        fi
    done
    
    echo "✅ Processos limpos"
}

# Limpar swap (pode conter dados sensíveis)
clean_swap() {
    echo "🧹 Limpando swap..."
    
    if [ "$EUID" -eq 0 ]; then
        swapoff -a 2>/dev/null
        swapon -a 2>/dev/null
        echo "✅ Swap limpo"
    else
        echo "⚠️  Requer root para limpar swap"
    fi
}

# Limpar memória livre
clean_free_memory() {
    echo "🧹 Limpando memória livre..."
    
    if [ "$EUID" -eq 0 ]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches
        echo "✅ Cache de memória limpo"
    else
        echo "⚠️  Requer root para limpar cache de memória"
    fi
}

# Randomizar MAC address
randomize_mac() {
    echo "🧹 Randomizando MAC address..."
    
    if [ "$EUID" -eq 0 ] && command -v macchanger >/dev/null 2>&1; then
        local interfaces=$(ip link show | grep -E "^[0-9]+:" | grep -v "lo:" | cut -d: -f2 | tr -d ' ')
        
        for iface in $interfaces; do
            if [[ "$iface" =~ ^(eth|wlan|enp|wlp) ]]; then
                ip link set dev "$iface" down 2>/dev/null
                macchanger -r "$iface" >/dev/null 2>&1
                ip link set dev "$iface" up 2>/dev/null
                echo "🔄 MAC randomizado para $iface"
            fi
        done
        
        echo "✅ MAC addresses randomizados"
    else
        echo "⚠️  Requer root e macchanger para randomizar MAC"
    fi
}

# Renovar circuito Tor
renew_tor_circuit() {
    echo "🧹 Renovando circuito Tor..."
    
    if [ "$EUID" -eq 0 ]; then
        systemctl restart tor 2>/dev/null
        sleep 5
        echo "✅ Circuito Tor renovado"
    else
        # Tentar via control port
        echo "SIGNAL NEWNYM" | nc 127.0.0.1 9051 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Circuito Tor renovado"
        else
            echo "⚠️  Falha ao renovar circuito Tor"
        fi
    fi
}

# Menu interativo
show_menu() {
    echo ""
    echo "🧹 OPÇÕES DE LIMPEZA:"
    echo "1. Limpeza Rápida (logs, histórico, temp)"
    echo "2. Limpeza Completa (tudo)"
    echo "3. Limpeza Paranóica (completa + swap + MAC)"
    echo "4. Apenas Logs"
    echo "5. Apenas Arquivos Temporários"
    echo "6. Renovar Identidade (Tor + MAC)"
    echo "0. Sair"
    echo ""
    echo -n "Escolha uma opção: "
}

# Execução baseada em parâmetro ou menu
if [ -n "$1" ]; then
    case "$1" in
        "quick")
            clean_system_logs
            clean_command_history
            clean_temp_files
            ;;
        "full")
            clean_system_logs
            clean_command_history
            clean_temp_files
            clean_dns_cache
            clean_network_connections
            clean_suspicious_processes
            clean_free_memory
            ;;
        "paranoid")
            clean_system_logs
            clean_command_history
            clean_temp_files
            clean_dns_cache
            clean_network_connections
            clean_suspicious_processes
            clean_swap
            clean_free_memory
            randomize_mac
            renew_tor_circuit
            ;;
        *)
            echo "Uso: $0 [quick|full|paranoid]"
            exit 1
            ;;
    esac
else
    # Menu interativo
    while true; do
        show_menu
        read -r choice
        
        case "$choice" in
            1)
                clean_system_logs
                clean_command_history
                clean_temp_files
                ;;
            2)
                clean_system_logs
                clean_command_history
                clean_temp_files
                clean_dns_cache
                clean_network_connections
                clean_suspicious_processes
                clean_free_memory
                ;;
            3)
                clean_system_logs
                clean_command_history
                clean_temp_files
                clean_dns_cache
                clean_network_connections
                clean_suspicious_processes
                clean_swap
                clean_free_memory
                randomize_mac
                renew_tor_circuit
                ;;
            4)
                clean_system_logs
                ;;
            5)
                clean_temp_files
                ;;
            6)
                randomize_mac
                renew_tor_circuit
                ;;
            0)
                echo "🧹 Limpeza concluída!"
                exit 0
                ;;
            *)
                echo "Opção inválida!"
                ;;
        esac
        
        echo ""
        echo -n "Pressione Enter para continuar..."
        read -r
    done
fi

echo ""
echo "🧹 LIMPEZA CONCLUÍDA!"
echo "🛡️  Rastros removidos com sucesso"