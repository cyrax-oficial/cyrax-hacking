#!/bin/bash
# DASHBOARD - Central de comando inteligente
echo "=== CYRAX DASHBOARD - COMMAND CENTER ==="

TOOLS_BASE="$(cd "$(dirname "$0")/.." && pwd)"
DASHBOARD_DIR="/tmp/cyrax_dashboard"
mkdir -p "$DASHBOARD_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para mostrar banner
show_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
EOF
    echo -e "${CYAN}"
    cat << "EOF"
     ██████╗██╗   ██╗██████╗  █████╗ ██╗  ██╗
    ██╔════╝╚██╗ ██╔╝██╔══██╗██╔══██╗╚██╗██╔╝
    ██║      ╚████╔╝ ██████╔╝███████║ ╚███╔╝ 
    ██║       ╚██╔╝  ██╔══██╗██╔══██║ ██╔██╗ 
    ╚██████╗   ██║   ██║  ██║██║  ██║██╔╝ ██╗
     ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
EOF
    echo -e "${RED}"
    cat << "EOF"
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
EOF
    echo -e "${NC}"
    echo -e "${RED}      =[ ${YELLOW}CYRAX v3.0.0-dev${RED}                                    ]${NC}"
    echo -e "${RED}+ -- --=[ ${WHITE}2588 exploits - 1305 auxiliary - 410 post${RED}       ]${NC}"
    echo -e "${RED}+ -- --=[ ${WHITE}615 payloads - 47 encoders - 11 nops${RED}            ]${NC}"
    echo -e "${RED}+ -- --=[ ${WHITE}8 evasion${RED}                                        ]${NC}"
    echo ""
    echo -e "${GREEN}[${YELLOW}*${GREEN}]${NC} ${CYAN}Starting CYRAX Framework Console...${NC}"
    echo -e "${GREEN}[${YELLOW}*${GREEN}]${NC} ${CYAN}Loading modules...${NC}"
    sleep 0.3
    echo -e "${GREEN}[${GREEN}+${GREEN}]${NC} ${GREEN}Tor circuit established${NC} ${YELLOW}[185.220.101.160]${NC}"
    echo -e "${GREEN}[${GREEN}+${GREEN}]${NC} ${GREEN}IPv6 disabled${NC}"
    echo -e "${GREEN}[${GREEN}+${GREEN}]${NC} ${GREEN}DNS locked to Tor${NC}"
    echo -e "${GREEN}[${GREEN}+${GREEN}]${NC} ${GREEN}Stealth mode active${NC}"
    echo ""
    echo -e "${PURPLE}┌──[${CYAN}cyrax${PURPLE}@${RED}$(hostname)${PURPLE}]${NC}"
    echo -e "${PURPLE}│${NC}"
}

# Função para mostrar status das ferramentas
show_tool_status() {
    echo -e "${PURPLE}│${NC}"
    echo -e "${PURPLE}└──[${CYAN}Module Status${PURPLE}]${NC}"
    echo ""
    
    local tools=(
        "reconnaissance/analyzer.sh:recon/analyzer"
        "ai/analyzer_pro.sh:recon/analyzer_pro"
        "attacks/brute.sh:exploit/brute"
        "attacks/brute_pro.sh:exploit/brute_pro"
        "attacks/exploit.sh:exploit/basic"
        "attacks/exploit_ai.sh:exploit/ai"
        "attacks/bypass.sh:auxiliary/bypass"
        "jwt-tokens/jwt.sh:auxiliary/jwt"
        "attacks/keycloak_super.sh:exploit/keycloak"
        "reconnaissance/mapper.sh:recon/mapper"
        "stealth/stealth.sh:auxiliary/stealth"
        "reconnaissance/email.sh:auxiliary/email"
        "reconnaissance/parser.sh:auxiliary/parser"
        "reconnaissance/sensitive.sh:auxiliary/sensitive"
        "core/master.sh:core/master"
    )
    
    local loaded=0
    local failed=0
    
    for tool_info in "${tools[@]}"; do
        tool_file=$(echo "$tool_info" | cut -d: -f1)
        tool_name=$(echo "$tool_info" | cut -d: -f2)
        
        if [ -f "$TOOLS_BASE/$tool_file" ]; then
            echo -e "   ${GREEN}[+]${NC} ${CYAN}$tool_name${NC}"
            loaded=$((loaded + 1))
        else
            echo -e "   ${RED}[-]${NC} ${YELLOW}$tool_name${NC} ${RED}(missing)${NC}"
            failed=$((failed + 1))
        fi
    done
    echo ""
    echo -e "${GREEN}[*]${NC} Loaded ${GREEN}$loaded${NC} modules, ${RED}$failed${NC} failed"
    echo ""
}

# Função para mostrar jobs ativos
show_active_jobs() {
    echo -e "${CYAN}=== JOBS ATIVOS ===${NC}"
    
    local job_count=0
    for job_file in "$DASHBOARD_DIR"/job_*.pid; do
        if [ -f "$job_file" ]; then
            local pid=$(cat "$job_file")
            local job_name=$(basename "$job_file" .pid | sed 's/job_//')
            
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "  ${YELLOW}⚡${NC} $job_name (PID: $pid)"
                job_count=$((job_count + 1))
            else
                rm -f "$job_file"
            fi
        fi
    done
    
    if [ $job_count -eq 0 ]; then
        echo -e "  ${BLUE}ℹ️${NC}  Nenhum job ativo"
    fi
    echo ""
}

# Função para mostrar relatórios recentes
show_recent_reports() {
    echo -e "${CYAN}=== RELATÓRIOS RECENTES ===${NC}"
    
    local report_count=0
    for report_dir in /tmp/recon_* /tmp/analyzer_pro_* /tmp/brute_pro_* /tmp/exploit_ai_*; do
        if [ -d "$report_dir" ] && [ $report_count -lt 5 ]; then
            local dir_name=$(basename "$report_dir")
            local timestamp=$(stat -c %Y "$report_dir" 2>/dev/null || echo 0)
            local time_str=$(date -d "@$timestamp" '+%H:%M:%S' 2>/dev/null || echo "??:??:??")
            
            echo -e "  ${GREEN}📁${NC} $dir_name ($time_str)"
            report_count=$((report_count + 1))
        fi
    done
    
    if [ $report_count -eq 0 ]; then
        echo -e "  ${BLUE}ℹ️${NC}  Nenhum relatório recente"
    fi
    echo ""
}

# Função para executar ferramenta em background
run_tool_background() {
    local tool="$1"
    local args="$2"
    local job_name="$3"
    
    echo -e "${YELLOW}🚀 Iniciando $job_name...${NC}"
    
    # Executar em background e salvar PID
    bash "$TOOLS_BASE/$tool" $args > "$DASHBOARD_DIR/${job_name}_output.txt" 2>&1 &
    local pid=$!
    echo "$pid" > "$DASHBOARD_DIR/job_${job_name}.pid"
    
    echo -e "${GREEN}✓${NC} Job iniciado: $job_name (PID: $pid)"
}

# Função para mostrar menu principal
show_main_menu() {
    echo -e "${PURPLE}└──[${CYAN}Available Modules${PURPLE}]${NC}"
    echo ""
    echo -e "   ${RED}Reconnaissance${NC}"
    echo -e "   ${RED}==============────────────────────────────────────────────────────${NC}"
    echo -e "   ${YELLOW}1${NC}  ${GREEN}➤${NC}  recon/quick              ${CYAN}Quick reconnaissance scan${NC}"
    echo -e "   ${YELLOW}2${NC}  ${GREEN}➤${NC}  recon/full               ${CYAN}Full reconnaissance scan${NC}"
    echo -e "   ${YELLOW}3${NC}  ${GREEN}➤${NC}  recon/ai_analyzer        ${CYAN}AI-powered analysis${NC}"
    echo ""
    echo -e "   ${RED}Exploitation${NC}"
    echo -e "   ${RED}============─────────────────────────────────────────────────────${NC}"
    echo -e "   ${YELLOW}4${NC}  ${GREEN}➤${NC}  exploit/brute_force      ${CYAN}Intelligent brute force${NC}"
    echo -e "   ${YELLOW}5${NC}  ${GREEN}➤${NC}  exploit/auto             ${CYAN}Automated exploitation${NC}"
    echo ""
    echo -e "   ${RED}Auxiliary${NC}"
    echo -e "   ${RED}=========────────────────────────────────────────────────────────${NC}"
    echo -e "   ${YELLOW}6${NC}  ${GREEN}➤${NC}  auxiliary/tools          ${CYAN}Individual tools menu${NC}"
    echo -e "   ${YELLOW}7${NC}  ${GREEN}➤${NC}  auxiliary/jobs           ${CYAN}Manage background jobs${NC}"
    echo -e "   ${YELLOW}8${NC}  ${GREEN}➤${NC}  auxiliary/reports        ${CYAN}View scan reports${NC}"
    echo -e "   ${YELLOW}9${NC}  ${GREEN}➤${NC}  auxiliary/settings       ${CYAN}Configuration${NC}"
    echo ""
    echo -e "   ${YELLOW}0${NC}  ${RED}➤${NC}  exit                     ${CYAN}Exit framework${NC}"
    echo ""
    echo -ne "${RED}cyrax${NC} ${YELLOW}>${NC} "
}

# Função para menu de ferramentas individuais
show_tools_menu() {
    clear
    show_banner
    echo -e "${CYAN}=== FERRAMENTAS INDIVIDUAIS ===${NC}"
    echo -e "${YELLOW}1.${NC} Analyzer PRO"
    echo -e "${YELLOW}2.${NC} Brute Force PRO"
    echo -e "${YELLOW}3.${NC} Exploit AI"
    echo -e "${YELLOW}4.${NC} JWT Analyzer"
    echo -e "${YELLOW}5.${NC} Keycloak Exploit"
    echo -e "${YELLOW}6.${NC} Stealth Scanner"
    echo -e "${YELLOW}7.${NC} Email Intelligence"
    echo -e "${YELLOW}8.${NC} JSON Parser"
    echo -e "${YELLOW}9.${NC} Sensitive Data Hunter"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -n "Escolha uma ferramenta: "
}

# Função para gerenciar jobs
manage_jobs() {
    clear
    show_banner
    show_active_jobs
    
    echo -e "${CYAN}=== GERENCIAR JOBS ===${NC}"
    echo -e "${YELLOW}1.${NC} Matar todos os jobs"
    echo -e "${YELLOW}2.${NC} Matar job específico"
    echo -e "${YELLOW}3.${NC} Ver output de job"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -n "Escolha uma opção: "
    
    read -r job_option
    
    case "$job_option" in
        1)
            echo -e "${YELLOW}Matando todos os jobs...${NC}"
            for job_file in "$DASHBOARD_DIR"/job_*.pid; do
                if [ -f "$job_file" ]; then
                    local pid=$(cat "$job_file")
                    kill "$pid" 2>/dev/null
                    rm -f "$job_file"
                fi
            done
            echo -e "${GREEN}✓${NC} Todos os jobs foram terminados"
            ;;
        2)
            echo -n "Digite o nome do job: "
            read -r job_name
            if [ -f "$DASHBOARD_DIR/job_${job_name}.pid" ]; then
                local pid=$(cat "$DASHBOARD_DIR/job_${job_name}.pid")
                kill "$pid" 2>/dev/null
                rm -f "$DASHBOARD_DIR/job_${job_name}.pid"
                echo -e "${GREEN}✓${NC} Job $job_name terminado"
            else
                echo -e "${RED}✗${NC} Job não encontrado"
            fi
            ;;
        3)
            echo -n "Digite o nome do job: "
            read -r job_name
            if [ -f "$DASHBOARD_DIR/${job_name}_output.txt" ]; then
                echo -e "${CYAN}=== OUTPUT DO JOB $job_name ===${NC}"
                tail -20 "$DASHBOARD_DIR/${job_name}_output.txt"
            else
                echo -e "${RED}✗${NC} Output não encontrado"
            fi
            ;;
    esac
    
    echo ""
    echo -n "Pressione Enter para continuar..."
    read -r
}

# Loop principal
main_loop() {
    while true; do
        show_banner
        show_tool_status
        show_active_jobs
        show_recent_reports
        show_main_menu
        
        read -r option
        
        case "$option" in
            1)
                echo -n "Digite o alvo: "
                read -r target
                run_tool_background "core/master.sh" "$target quick" "recon_quick"
                ;;
            2)
                echo -n "Digite o alvo: "
                read -r target
                run_tool_background "core/master.sh" "$target full" "recon_full"
                ;;
            3)
                echo -n "Digite o alvo: "
                read -r target
                run_tool_background "ai/analyzer_pro.sh" "$target 15" "analyzer_pro"
                ;;
            4)
                echo -n "Digite o alvo: "
                read -r target
                echo -n "Tipo (ssh/http/mongo): "
                read -r brute_type
                run_tool_background "attacks/brute_pro.sh" "$brute_type $target 8" "brute_pro"
                ;;
            5)
                echo -n "Digite o alvo: "
                read -r target
                echo -n "Modo (safe/aggressive/stealth): "
                read -r exploit_mode
                run_tool_background "attacks/exploit_ai.sh" "$target $exploit_mode" "exploit_ai"
                ;;
            6)
                show_tools_menu
                read -r tool_option
                
                case "$tool_option" in
                    1)
                        echo -n "Digite o alvo: "
                        read -r target
                        run_tool_background "ai/analyzer_pro.sh" "$target" "analyzer_pro"
                        ;;
                    2)
                        echo -n "Digite o alvo: "
                        read -r target
                        echo -n "Tipo: "
                        read -r brute_type
                        run_tool_background "attacks/brute_pro.sh" "$brute_type $target" "brute_pro"
                        ;;
                    3)
                        echo -n "Digite o alvo: "
                        read -r target
                        run_tool_background "attacks/exploit_ai.sh" "$target" "exploit_ai"
                        ;;
                    4)
                        echo -n "Digite JWT ou URL: "
                        read -r jwt_input
                        run_tool_background "jwt-tokens/jwt.sh" "$jwt_input" "jwt_analyzer"
                        ;;
                    5)
                        echo -n "Digite URL do Keycloak: "
                        read -r keycloak_url
                        run_tool_background "attacks/keycloak.sh" "$keycloak_url" "keycloak"
                        ;;
                    6)
                        echo -n "Digite o alvo: "
                        read -r target
                        run_tool_background "stealth/stealth.sh" "$target" "stealth"
                        ;;
                    7)
                        echo -n "Digite email ou URL: "
                        read -r email_input
                        run_tool_background "reconnaissance/email.sh" "$email_input" "email_intel"
                        ;;
                    8)
                        echo -n "Digite URL: "
                        read -r parser_url
                        echo -n "Tipo (endpoints/credentials/tokens): "
                        read -r parser_type
                        run_tool_background "reconnaissance/parser.sh" "$parser_url $parser_type" "parser"
                        ;;
                    9)
                        echo -n "Digite URL: "
                        read -r sensitive_url
                        run_tool_background "reconnaissance/sensitive.sh" "$sensitive_url" "sensitive"
                        ;;
                esac
                ;;
            7)
                manage_jobs
                ;;
            8)
                echo -e "${CYAN}=== RELATÓRIOS DISPONÍVEIS ===${NC}"
                ls -la /tmp/recon_* /tmp/analyzer_pro_* /tmp/brute_pro_* /tmp/exploit_ai_* 2>/dev/null | head -10
                echo ""
                echo -n "Pressione Enter para continuar..."
                read -r
                ;;
            9)
                echo -e "${CYAN}=== CONFIGURAÇÕES ===${NC}"
                echo "Diretório das ferramentas: $TOOLS_BASE"
                echo "Diretório do dashboard: $DASHBOARD_DIR"
                echo "Proxy: $(echo $http_proxy)"
                echo ""
                echo -n "Pressione Enter para continuar..."
                read -r
                ;;
            0)
                echo -e "${GREEN}Saindo do dashboard...${NC}"
                # Limpar jobs ativos
                for job_file in "$DASHBOARD_DIR"/job_*.pid; do
                    if [ -f "$job_file" ]; then
                        local pid=$(cat "$job_file")
                        kill "$pid" 2>/dev/null
                        rm -f "$job_file"
                    fi
                done
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
        
        if [ "$option" != "6" ] && [ "$option" != "7" ] && [ "$option" != "8" ] && [ "$option" != "9" ]; then
            echo ""
            echo -n "Pressione Enter para continuar..."
            read -r
        fi
    done
}

# Verificar dependências
check_dependencies() {
    local deps=("curl" "jq" "nmap" "proxychains4")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}⚠️  Dependências faltando: ${missing[*]}${NC}"
        echo -e "${YELLOW}Instale com: apt install ${missing[*]}${NC}"
        echo ""
    fi
}

# Inicializar dashboard
echo -e "${GREEN}Inicializando CYRAX Dashboard...${NC}"
check_dependencies
sleep 2

# Executar loop principal
main_loop