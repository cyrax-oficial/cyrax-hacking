#!/bin/bash
# CYRAX INSTALLER - Instalação das superferramentas
echo "=== CYRAX INSTALLER - ULTIMATE TOOLS SETUP ==="

TOOLS_DIR="$(dirname "$0")/tools"

# Banner CYRAX
echo -e "\033[0;36m"
cat << "EOF"
     ██████╗██╗   ██╗██████╗  █████╗ ██╗  ██╗
    ██╔════╝╚██╗ ██╔╝██╔══██╗██╔══██╗╚██╗██╔╝
    ██║      ╚████╔╝ ██████╔╝███████║ ╚███╔╝ 
    ██║       ╚██╔╝  ██╔══██╗██╔══██║ ██╔██╗ 
    ╚██████╗   ██║   ██║  ██║██║  ██║██╔╝ ██╗
     ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
              ULTIMATE PENETRATION SUITE v3.0
EOF
echo -e "\033[0m"

echo "🚀 Instalando CYRAX - As ferramentas mais poderosas de pentest"
echo ""

# Verificar se estamos no diretório correto
if [ ! -d "$TOOLS_DIR" ]; then
    echo "❌ Diretório tools não encontrado!"
    exit 1
fi

# Tornar todos os scripts executáveis
echo "🔧 Configurando permissões..."
find "$TOOLS_DIR" -name "*.sh" -exec chmod +x {} \;

# ========================================
# FASE 1: TUDO QUE PRECISA DE INTERNET
# ========================================

echo "🌐 FASE 1: Instalando dependências (requer internet)"

# Instalar dependências críticas
echo "📦 Instalando dependências do sistema..."
if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y curl wget jq nmap proxychains4 tor sshpass mysql-client mongodb-clients whois dnsutils net-tools
fi

# Baixar wordlists essenciais
echo "📥 Baixando wordlists..."
mkdir -p "$HOME/.cyrax/wordlists"

WORDLISTS=(
    "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt:passwords_top1000.txt"
    "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt:usernames_top.txt"
    "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt:directories_medium.txt"
    "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt:directories_common.txt"
)

for wordlist_info in "${WORDLISTS[@]}"; do
    url=$(echo "$wordlist_info" | cut -d: -f1-2)
    filename=$(echo "$wordlist_info" | cut -d: -f3)
    filepath="$HOME/.cyrax/wordlists/$filename"
    
    echo -n "  📥 $filename... "
    if curl -s -L "$url" -o "$filepath" 2>/dev/null && [ -s "$filepath" ]; then
        echo "✅"
    else
        echo "❌"
    fi
done

# Testar conectividade final
echo "🌐 Testando conectividade..."
echo -n "  🔗 Internet... "
if curl -s --connect-timeout 5 http://httpbin.org/ip >/dev/null 2>&1; then
    echo "✅"
else
    echo "❌ (sem internet - algumas funcionalidades limitadas)"
fi

echo ""
echo "🎉 FASE 1 CONCLUÍDA - Todas as dependências de internet instaladas!"
echo "📴 Agora você pode desconectar da internet se necessário"
echo ""
read -p "Pressione Enter para continuar com configurações locais..."

# ========================================
# FASE 2: CONFIGURAÇÕES LOCAIS (SEM INTERNET)
# ========================================

echo "🔧 FASE 2: Configurações locais (sem internet necessária)"

# Verificar ferramentas CYRAX
echo "📋 Verificando ferramentas CYRAX..."

CYRAX_TOOLS=(
    "attacks/keycloak_super.sh:CYRAX Keycloak Destroyer"
    "databases/database_super.sh:CYRAX Database Destroyer"
    "attacks/cors_super.sh:CYRAX CORS Super Tester"
    "attacks/bypass_super.sh:CYRAX Bypass Super Tool"
    "wordpress/wordpress_destroyer.sh:CYRAX WordPress Destroyer"
    "attacks/fuzzer_destroyer.sh:CYRAX Fuzzer Destroyer"
    "attacks/waf_destroyer.sh:CYRAX WAF Destroyer"
    "ai/analyzer_pro.sh:CYRAX Analyzer PRO"
    "attacks/brute_pro.sh:CYRAX Brute Force PRO"
    "ai/exploit_ai.sh:CYRAX Exploit AI"
    "core/dashboard.sh:CYRAX Dashboard"
    "core/master.sh:CYRAX Master Tool"
)

for tool_info in "${CYRAX_TOOLS[@]}"; do
    tool_file=$(echo "$tool_info" | cut -d: -f1)
    tool_desc=$(echo "$tool_info" | cut -d: -f2)
    
    if [ -f "$TOOLS_DIR/$tool_file" ]; then
        echo "  ✅ $tool_desc"
    else
        echo "  ❌ $tool_desc (não encontrado)"
    fi
done

# Criar aliases CYRAX
echo ""
echo "🔗 Criando aliases CYRAX..."

CYRAX_ALIASES="
# CYRAX Aliases - Ultimate Pentest Tools
alias cyrax='cd $(pwd) && ./tools/core/dashboard.sh'
alias cyrax-keycloak='cd $(pwd) && ./tools/attacks/keycloak_super.sh'
alias cyrax-database='cd $(pwd) && ./tools/databases/database_super.sh'
alias cyrax-cors='cd $(pwd) && ./tools/attacks/cors_super.sh'
alias cyrax-bypass='cd $(pwd) && ./tools/attacks/bypass_super.sh'
alias cyrax-wordpress='cd $(pwd) && ./tools/wordpress/wordpress_destroyer.sh'
alias cyrax-fuzzer='cd $(pwd) && ./tools/attacks/fuzzer_destroyer.sh'
alias cyrax-waf='cd $(pwd) && ./tools/attacks/waf_destroyer.sh'
alias cyrax-analyzer='cd $(pwd) && ./tools/ai/analyzer_pro.sh'
alias cyrax-brute='cd $(pwd) && ./tools/attacks/brute_pro.sh'
alias cyrax-exploit='cd $(pwd) && ./tools/ai/exploit_ai.sh'
alias cyrax-master='cd $(pwd) && ./tools/core/master.sh'
"

# Adicionar ao bashrc se não existir
if ! grep -q "CYRAX Aliases" ~/.bashrc 2>/dev/null; then
    echo "$CYRAX_ALIASES" >> ~/.bashrc
    echo "  ✅ Aliases adicionados ao ~/.bashrc"
else
    echo "  ℹ️  Aliases já existem no ~/.bashrc"
fi

# Adicionar ao zshrc se existir
if [ -f ~/.zshrc ]; then
    if ! grep -q "CYRAX Aliases" ~/.zshrc 2>/dev/null; then
        echo "$CYRAX_ALIASES" >> ~/.zshrc
        echo "  ✅ Aliases adicionados ao ~/.zshrc"
    fi
fi

# Criar diretórios de trabalho CYRAX
echo ""
echo "📁 Criando diretórios CYRAX..."

CYRAX_DIRS=(
    "/tmp/cyrax_logs"
    "/tmp/cyrax_reports"
    "/tmp/cyrax_wordlists"
    "$HOME/.cyrax"
    "$HOME/.cyrax/configs"
    "$HOME/.cyrax/wordlists"
    "$HOME/.cyrax/exploits"
)

for dir in "${CYRAX_DIRS[@]}"; do
    if mkdir -p "$dir" 2>/dev/null; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir (erro na criação)"
    fi
done





# Criar arquivo de configuração CYRAX
echo ""
echo "⚙️  Criando configuração CYRAX..."

cat > "$HOME/.cyrax/cyrax.conf" <<EOF
# CYRAX Configuration File
# Generated on $(date)

[GENERAL]
version=3.0
install_date=$(date +%Y-%m-%d)
tools_dir=$(pwd)/tools
wordlists_dir=$HOME/.cyrax/wordlists

[NETWORK]
use_tor=true
default_timeout=15
max_threads=50
user_agent_rotation=true

[EVASION]
waf_bypass=true
rate_limiting_evasion=true
randomize_delays=true
header_rotation=true

[REPORTING]
auto_report=true
report_format=markdown
save_location=/tmp/cyrax_reports
EOF

echo "  ✅ Configuração salva em $HOME/.cyrax/cyrax.conf"

# Mostrar resumo final
echo ""
echo "🎉 INSTALAÇÃO CYRAX CONCLUÍDA!"
echo ""
echo "📋 RESUMO:"
echo "  🛠️  Ferramentas instaladas: $(find "$TOOLS_DIR" -name "*.sh" | wc -l)"
echo "  📁 Diretórios criados: ${#CYRAX_DIRS[@]}"
echo "  📝 Wordlists baixadas: ${#WORDLISTS[@]}"
echo "  🔗 Aliases criados: $(echo "$CYRAX_ALIASES" | grep -c "alias")"

echo ""
echo "🚀 COMANDOS CYRAX:"
echo "  cyrax                 - Dashboard principal"
echo "  cyrax-keycloak        - Keycloak Destroyer"
echo "  cyrax-database        - Database Destroyer"
echo "  cyrax-wordpress       - WordPress Destroyer"
echo "  cyrax-fuzzer          - Fuzzer Destroyer (melhor que ffuf)"
echo "  cyrax-waf             - WAF Destroyer"
echo "  cyrax-bypass          - Bypass Super Tool"
echo "  cyrax-cors            - CORS Super Tester"

echo ""
echo "💡 PRÓXIMOS PASSOS:"
echo "  1. Execute: source ~/.bashrc"
echo "  2. Inicie com: cyrax"
echo "  3. Para dependências: sudo apt install curl jq nmap proxychains4 tor"

echo ""
echo "⚡ CYRAX ESTÁ PRONTO PARA DESTRUIR! ⚡"
echo ""
echo "Happy Hacking! 🔥"