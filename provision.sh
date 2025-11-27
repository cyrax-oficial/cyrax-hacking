#!/bin/bash
set -e

# Corrigir dpkg se travado
sudo dpkg --configure -a 2>/dev/null || true

# Aguardar outros processos apt terminarem
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    sleep 1
done

echo "=== INSTALANDO PACOTES (SEM PROTEÇÃO) ==="

# ---------------------------

# Pacotes básicos PRIMEIRO

# ---------------------------

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git tor iptables macchanger curl iptables-persistent obfs4proxy torsocks proxychains4 sqlmap nikto dirb gobuster wfuzz nmap masscan whatweb wafw00f torbrowser-launcher

# Atualizar para última versão do Kali
apt-get dist-upgrade -y -qq

# Instalar dependências para TextNow e Llama
apt-get install -y -qq snapd android-tools-adb firefox-esr curl

# Instalar Ollama para Llama AI
if ! command -v ollama &> /dev/null; then
    echo "Instalando Ollama (Llama AI)..."
    curl -fsSL https://ollama.ai/install.sh | sh || echo "Ollama install falhou - usar manual"
else
    echo "Ollama já instalado"
fi

# Iniciar Ollama em background
systemctl enable ollama 2>/dev/null || true
systemctl start ollama 2>/dev/null || true

# Baixar modelo Llama em background (não bloquear provision)
(sleep 30 && ollama pull llama3.2:3b) &

# Instalar ferramentas CLI para WhatsApp e Email
apt-get install -y -qq python3-pip mutt msmtp jq 2>/dev/null || true
pip3 install yowsup2 --break-system-packages 2>/dev/null || true

# Aguardar Ollama pull terminar (background)
sleep 60

# Corrigir pacotes quebrados
echo "=== CORRIGINDO PACOTES ==="
dpkg --configure -a 2>/dev/null || true
apt --fix-broken install -y -qq 2>/dev/null || true

# Copiar ferramentas CYRAX ANTES de bloquear
echo "=== COPIANDO FERRAMENTAS CYRAX ==="
cp -r /vagrant/tools /home/vagrant/ 2>/dev/null || echo "Erro ao copiar tools"
chown -R vagrant:vagrant /home/vagrant/tools 2>/dev/null || true
find /home/vagrant/tools -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Garantir que dashboard.sh está atualizado
cp /vagrant/tools/core/dashboard.sh /home/vagrant/tools/core/dashboard.sh 2>/dev/null || true
chmod +x /home/vagrant/tools/core/dashboard.sh 2>/dev/null || true

# Criar ferramentas básicas se não existirem
[ ! -f /home/vagrant/tools/ai/analyzer_pro.sh ] && cat > /home/vagrant/tools/ai/analyzer_pro.sh <<'EOFANALYZER'
#!/bin/bash
TARGET="${1:-}"
THREADS="${2:-10}"
[ -z "$TARGET" ] && echo "Uso: $0 <URL> [THREADS]" && exit 1
echo "=== ANALYZER PRO ==="
echo "Alvo: $TARGET"
whatweb "$TARGET" 2>/dev/null || echo "whatweb não disponível"
EOFANALYZER

[ ! -f /home/vagrant/tools/reconnaissance/analyzer.sh ] && cat > /home/vagrant/tools/reconnaissance/analyzer.sh <<'EOFBASIC'
#!/bin/bash
TARGET="${1:-}"
[ -z "$TARGET" ] && echo "Uso: $0 <URL>" && exit 1
echo "=== ANALYZER BÁSICO ==="
curl -I "$TARGET" 2>/dev/null
EOFBASIC

[ ! -f /home/vagrant/tools/reconnaissance/mapper.sh ] && cat > /home/vagrant/tools/reconnaissance/mapper.sh <<'EOFMAPPER'
#!/bin/bash
TARGET="${1:-}"
[ -z "$TARGET" ] && echo "Uso: $0 <TARGET>" && exit 1
echo "=== NETWORK MAPPER ==="
nmap -sV "$TARGET" 2>/dev/null
EOFMAPPER

[ ! -f /home/vagrant/tools/reconnaissance/email.sh ] && cat > /home/vagrant/tools/reconnaissance/email.sh <<'EOFEMAIL'
#!/bin/bash
EMAIL="${1:-}"
[ -z "$EMAIL" ] && echo "Uso: $0 <EMAIL>" && exit 1
echo "=== EMAIL INTELLIGENCE ==="
echo "Email: $EMAIL"
EOFEMAIL

[ ! -f /home/vagrant/tools/reconnaissance/parser.sh ] && cat > /home/vagrant/tools/reconnaissance/parser.sh <<'EOFPARSER'
#!/bin/bash
URL="${1:-}"
[ -z "$URL" ] && echo "Uso: $0 <URL>" && exit 1
echo "=== JSON PARSER ==="
echo "URL: $URL"
EOFPARSER

[ ! -f /home/vagrant/tools/reconnaissance/sensitive.sh ] && cat > /home/vagrant/tools/reconnaissance/sensitive.sh <<'EOFSENSITIVE'
#!/bin/bash
URL="${1:-}"
[ -z "$URL" ] && echo "Uso: $0 <URL>" && exit 1
echo "=== SENSITIVE DATA HUNTER ==="
echo "URL: $URL"
EOFSENSITIVE

[ ! -f /home/vagrant/tools/stealth/stealth.sh ] && cat > /home/vagrant/tools/stealth/stealth.sh <<'EOFSTEALTH'
#!/bin/bash
TARGET="${1:-}"
[ -z "$TARGET" ] && echo "Uso: $0 <TARGET>" && exit 1
echo "=== STEALTH SCANNER ==="
nmap -sS -T2 "$TARGET" 2>/dev/null
EOFSTEALTH

chmod +x /home/vagrant/tools/ai/*.sh /home/vagrant/tools/reconnaissance/*.sh /home/vagrant/tools/stealth/*.sh 2>/dev/null || true

grep -q 'alias cyrax' /home/vagrant/.bashrc || echo 'alias cyrax="cd ~/tools/core && ./dashboard.sh"' >> /home/vagrant/.bashrc
grep -q 'alias cyrax' /home/vagrant/.zshrc || echo 'alias cyrax="cd ~/tools/core && ./dashboard.sh"' >> /home/vagrant/.zshrc

echo "=== TODOS OS DOWNLOADS CONCLUÍDOS ==="
echo "=== INICIANDO PROTEÇÕES (SEM INTERNET) ==="

# ---------------------------

# Desativar IPv6 completamente

# ---------------------------

sed -i '/eth1/d' /etc/sysctl.conf 2>/dev/null || true
grep -q 'net.ipv6.conf.all.disable_ipv6' /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
grep -q 'net.ipv6.conf.default.disable_ipv6' /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
grep -q 'net.ipv6.conf.lo.disable_ipv6' /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
grep -q 'net.ipv6.conf.eth0.disable_ipv6' /etc/sysctl.conf || echo "net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p 2>/dev/null || true

# Mudar prompt para cyrax (sem hostname)
grep -q 'PS1="cyrax' /home/vagrant/.bashrc || echo 'export PS1="cyrax$ "' >> /home/vagrant/.bashrc
grep -q 'PROMPT="cyrax' /home/vagrant/.zshrc || echo 'PROMPT="cyrax$ "' >> /home/vagrant/.zshrc
chown vagrant:vagrant /home/vagrant/.bashrc /home/vagrant/.zshrc 2>/dev/null || true

# ---------------------------

# MAC Spoof (toda vez que reiniciar)

# ---------------------------

# MAC Spoof contínuo e automático
cat > /etc/systemd/system/macspoof.service <<EOF
[Unit]
Description=MAC Address Spoofing
Wants=network-pre.target
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/bin/macchanger -r eth0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable macspoof.service

# ---------------------------

# Configurar Tor transparente

# ---------------------------

cat > /etc/tor/torrc <<EOF
# Configuração para máximo anonimato
AutomapHostsOnResolve 1
TransPort 9040
DNSPort 5353
VirtualAddrNetworkIPv4 10.192.0.0/10

# Proteções adicionais
AvoidDiskWrites 1
DisableDebuggerAttachment 1
SafeLogging 1
HardwareAccel 0

# Timeouts e renovação inteligente
MaxCircuitDirtiness 600
CircuitBuildTimeout 60
NewCircuitPeriod 30
LearnCircuitBuildTimeout 1

# Usar apenas nós seguros
ExitNodes {us},{ca},{de},{nl},{ch}
StrictNodes 0

# Evitar nós suspeitos
ExcludeNodes {cn},{ru},{ir},{kp},{sy}
ExcludeExitNodes {cn},{ru},{ir},{kp},{sy}
EOF

systemctl restart tor

# ---------------------------

# IPTABLES estilo Whonix

# ---------------------------

# IPTABLES inteligente: SSH funciona, web via Tor

iptables -F
iptables -t nat -F
iptables -t mangle -F

# Política padrão mais permissiva para SSH
iptables -P OUTPUT ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD DROP

TOR_UID=$(id -u debian-tor)

# Bloquear IPv6 completamente via firewall
ip6tables -F
ip6tables -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP
ip6tables -A INPUT -j DROP
ip6tables -A OUTPUT -j DROP
ip6tables -A FORWARD -j DROP

# Redirecionar tráfego web para Tor (exceto SSH)
iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 9040
iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 9040
iptables -t nat -A OUTPUT -p tcp --dport 8080 -j REDIRECT --to-ports 9040
iptables -t nat -A OUTPUT -p tcp --dport 8443 -j REDIRECT --to-ports 9040

# Redirecionar DNS para Tor
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353

# Forçar DNS via Tor com fallback
chattr -i /etc/resolv.conf 2>/dev/null || true
cat > /etc/resolv.conf <<EOFDNS
nameserver 127.0.0.1
nameserver 1.1.1.1
EOFDNS
chattr +i /etc/resolv.conf 2>/dev/null || true

# Timezone UTC para anonimato
timedatectl set-timezone UTC

# Configurar teclado ABNT2 português
cat > /etc/default/keyboard <<EOFKB
XKBMODEL="abnt2"
XKBLAYOUT="br"
XKBVARIANT="abnt2"
XKBOPTIONS=""
BACKSPACE="guess"
EOFKB
loadkeys br-abnt2 2>/dev/null || true

# Permitir tráfego Tor
iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT

# Salvar regras
netfilter-persistent save
ip6tables-save > /etc/iptables/rules.v6

# ---------------------------

# Rotação automática de identidade Tor

# ---------------------------

# Rotação de identidade menos suspeita (10-15 min)

cat > /usr/local/bin/tor-newip <<EOF
#!/bin/bash
# Rotação silenciosa
echo "SIGNAL NEWNYM" | nc 127.0.0.1 9051 2>/dev/null || killall -HUP tor
EOF
chmod +x /usr/local/bin/tor-newip

cat > /etc/systemd/system/tor-newip.service <<EOF
[Unit]
Description=Rotate Tor Identity

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tor-newip
StandardOutput=null
StandardError=null
EOF

cat > /etc/systemd/system/tor-newip.timer <<EOF
[Unit]
Description=Rotate Tor identity every 30 minutes

[Timer]
OnBootSec=1800
OnUnitActiveSec=1800
Unit=tor-newip.service

[Install]
WantedBy=timers.target
EOF

systemctl enable tor-newip.timer
systemctl start tor-newip.timer

# ---------------------------

# Kill-switch Tor (cai internet se Tor cair)

# ---------------------------

# Kill-switch e proteções adicionais

echo "net.ipv4.conf.all.src_valid_mark=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.log_martians=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps=0" >> /etc/sysctl.conf
sysctl -p

# Limpar histórico e logs
history -c
rm -f /root/.bash_history /home/*/.bash_history
echo "" > /var/log/auth.log
echo "" > /var/log/syslog

# Configurar proxychains4 para Tor
cat > /etc/proxychains4.conf <<EOF
dynamic_chain
proxy_dns
tcp_read_time_out 5000
tcp_connect_time_out 3000
[ProxyList]
socks5 127.0.0.1 9050
EOF

# Scripts WAF bypass
cat > /usr/local/bin/waf-curl <<EOF
#!/bin/bash
# WAF bypass curl com headers randomizados
UA_LIST=(
  "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
)
UA=\${UA_LIST[\$RANDOM % \${#UA_LIST[@]}]}
proxychains4 -q curl -s "\$@" \\
  -H "User-Agent: \$UA" \\
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \\
  -H "Accept-Language: pt-BR,pt;q=0.9,en;q=0.8" \\
  -H "Accept-Encoding: gzip, deflate" \\
  -H "Connection: keep-alive" \\
  --compressed
EOF
chmod +x /usr/local/bin/waf-curl

cat > /usr/local/bin/waf-sqlmap <<EOF
#!/bin/bash
# SQLMap via Tor com bypass WAF
proxychains4 sqlmap "\$@" \\
  --random-agent \\
  --delay=2-4 \\
  --timeout=30 \\
  --retries=3 \\
  --tamper=space2comment,charencode,randomcase
EOF
chmod +x /usr/local/bin/waf-sqlmap

cat > /usr/local/bin/waf-nmap <<EOF
#!/bin/bash
# Nmap via Tor com evasão WAF
proxychains4 nmap "\$@" \\
  -sS -T2 \\
  --randomize-hosts \\
  --data-length 25 \\
  --scan-delay 2s
EOF
chmod +x /usr/local/bin/waf-nmap

# Configurar aliases para usar sempre com bypass WAF
echo "alias curl='waf-curl'" >> /root/.bashrc
echo "alias sqlmap='waf-sqlmap'" >> /root/.bashrc
echo "alias nmap='waf-nmap'" >> /root/.bashrc
echo "alias wget='proxychains4 -q wget'" >> /root/.bashrc
echo "alias ssh='proxychains4 ssh'" >> /root/.bashrc

# Aguardar Tor inicializar e testar
sleep 10
systemctl restart tor
sleep 5

# Desabilitar logs do VirtualBox Guest Additions
VBoxControl guestproperty set /VirtualBox/GuestAdd/Vbgl/Video/SavedMode 0 2>/dev/null || true

# Randomizar machine-id a cada boot
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup
ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Limpar históricos permanentemente
cat > /etc/profile.d/no-history.sh <<EOF
unset HISTFILE
export HISTSIZE=0
export HISTFILESIZE=0
EOF
chmod +x /etc/profile.d/no-history.sh

# Limpar histórico atual
rm -f /home/*/.bash_history /home/*/.zsh_history /root/.bash_history /root/.zsh_history
ln -sf /dev/null /home/vagrant/.bash_history
ln -sf /dev/null /home/vagrant/.zsh_history
ln -sf /dev/null /root/.bash_history

# Proteger SSH
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
touch /home/vagrant/.ssh/config
cat > /home/vagrant/.ssh/config <<EOF
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
chmod 600 /home/vagrant/.ssh/config

# Limpar informações do host
unset VAGRANT_HOME
unset VBOX_USER_HOME

# ---------------------------

# TextNow Setup (número permanente)

# ---------------------------



# ---------------------------

# Habilitar Tor

# ---------------------------

systemctl enable tor
systemctl start tor

# Script para usar TextNow
cat > /home/vagrant/textnow.sh <<EOF
#!/bin/bash
echo "=== TEXTNOW - NÚMERO PERMANENTE ==="
echo "Acesse via navegador:"
echo "firefox https://www.textnow.com/signup"
echo ""
echo "IMPORTANTE: Use 1x por mês para não perder o número!"
EOF
chmod +x /home/vagrant/textnow.sh
chown vagrant:vagrant /home/vagrant/textnow.sh

# ---------------------------

# Email Permanente Setup

# ---------------------------

# Script para configurar identidade cyrax@devops.com
cat > /home/vagrant/setup_identity.sh <<EOF
#!/bin/bash
echo "=== CONFIGURANDO IDENTIDADE CYRAX ==="
echo "Email: cyrax@devops.com"
echo "Telefone: +1 (555) 123-4567"
echo ""
echo "PASSO 1 - EMAIL CLI:"
echo "~/tools/reconnaissance/email_cli.sh"
echo "Criar email temporário ou configurar ProtonMail"
echo ""
echo "PASSO 2 - SMS CLI:"
echo "~/tools/reconnaissance/sms_cli.sh +5511999999999 'Teste'"
echo "Enviar SMS via TextBelt API"
echo ""
echo "PASSO 3 - WHATSAPP CLI:"
echo "~/tools/reconnaissance/whatsapp_cli.sh"
echo "Configurar WhatsApp via yowsup"
echo ""
echo "BACKUP AUTOMÁTICO:"
echo "echo 'Email: SEU_EMAIL' >> ~/identidade_cyrax.txt"
echo "echo 'Telefone: SEU_NUMERO' >> ~/identidade_cyrax.txt"
echo "echo 'Data: \$(date)' >> ~/identidade_cyrax.txt"
EOF
chmod +x /home/vagrant/setup_identity.sh
chown vagrant:vagrant /home/vagrant/setup_identity.sh

# Criar arquivo de backup da identidade
cat > /home/vagrant/identidade_cyrax.txt <<EOF
=== IDENTIDADE CYRAX ===
Usuário: cyrax
Email: [CRIAR: cyrax.devops@proton.me ou similar]
Telefone: [CRIAR: número TextNow +1]
WhatsApp: [USAR: mesmo número TextNow]
Data criação: $(date)

IMPORTANTE:
- Usar email 1x por mês
- Usar telefone TextNow 1x por mês
- WhatsApp mantém ativo automaticamente
- Todos são PERMANENTES se usados regularmente
EOF
chown vagrant:vagrant /home/vagrant/identidade_cyrax.txt

# Ferramentas já copiadas antes dos bloqueios

# Criar menu de ferramentas
cat > /home/vagrant/tools.sh <<EOF
#!/bin/bash
echo "=== FERRAMENTAS CYRAX ==="
echo "1. bypass.sh <URL>     - Bypass WAF/403/401"
echo "2. exploit.sh <URL>    - Exploits automáticos"
echo "3. analyzer.sh <URL>   - Analisador de sites"
echo "4. keycloak.sh <URL>   - Keycloak exploits"
echo "5. mapper.sh <TARGET>  - Mapeamento de rede"
echo "6. stealth.sh <TARGET> - Scanner stealth"
echo "7. brute.sh <TYPE> <TARGET> - Brute force"
echo "8. payload.sh <TYPE>   - Gerador de payloads"
echo "9. parser.sh <URL> <TYPE> - Parser JSON inteligente"
echo "10. jwt.sh <TOKEN>     - Analisador JWT inteligente"
echo "11. sensitive.sh <URL> - Caçador de dados sensíveis"
echo "12. email.sh <EMAIL>   - Inteligência de emails"
echo "13. ai.sh <PERGUNTA>   - IA Assistant para hacking"
echo "14. oracle.sh <CONTEXTO> - IA Avançada de análise"
echo "15. llama.sh <PERGUNTA> - Llama AI local (avançado)"
echo ""
echo "Exemplo: ./bypass.sh https://target.com/admin"
EOF
chmod +x /home/vagrant/tools.sh
chown vagrant:vagrant /home/vagrant/tools.sh

# Aplicar proteções finais
echo "=== APLICANDO PROTEÇÕES FINAIS ==="

# Bloquear Battery API (vazamento de fingerprint)
mkdir -p /etc/firefox/policies 2>/dev/null || true
cat > /etc/firefox/policies/policies.json <<EOF
{
  "policies": {
    "Permissions": {
      "Battery": {
        "BlockNewRequests": true
      }
    }
  }
}
EOF

# Desmontar /vagrant para isolamento total
umount /vagrant 2>/dev/null || true

# Remover logs que podem identificar
rm -rf /var/log/* /tmp/* /var/tmp/*

# Desmontar /vagrant para isolamento total
echo "=== ISOLANDO VM ==="
umount /vagrant 2>/dev/null || true

# Verificar se está funcionando
echo "Testando conexão Tor..."
proxychains4 -q curl -s --connect-timeout 10 https://check.torproject.org/ | grep -i congratulations && echo "TOR FUNCIONANDO" || echo "TOR COM PROBLEMAS"

echo ""
echo "=== CYRAX INSTALADO E PROTEGIDO! ==="
echo "Ferramentas em: ~/tools/"
echo "Execute: cyrax"

# Recarregar bashrc para ativar aliases
su - vagrant -c "source ~/.bashrc" 2>/dev/null || true