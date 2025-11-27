#!/bin/bash
# Email CLI via mutt/neomutt

echo "=== EMAIL CLI ==="
echo ""

# Instalar mutt se não existir
if ! command -v mutt &> /dev/null; then
    echo "Instalando mutt..."
    apt-get install -y mutt msmtp 2>/dev/null
fi

# Configurar email temporário via guerrillamail
echo "Opção 1 - Email Temporário (Guerrilla Mail):"
echo "curl -s 'https://api.guerrillamail.com/ajax.php?f=get_email_address' | jq -r '.email_addr'"
echo ""

# Configurar ProtonMail via bridge
echo "Opção 2 - ProtonMail CLI:"
echo "1. Instalar: wget https://proton.me/download/bridge/protonmail-bridge.deb && dpkg -i protonmail-bridge.deb"
echo "2. Configurar: protonmail-bridge --cli"
echo ""

# Mutt config básico
cat > ~/.muttrc <<EOF
set from = "cyrax@protonmail.com"
set realname = "Cyrax"
set smtp_url = "smtp://127.0.0.1:1025"
set smtp_pass = ""
set folder = "~/Mail"
set spoolfile = "+INBOX"
EOF

echo "Enviar email:"
echo "echo 'Corpo da mensagem' | mutt -s 'Assunto' destinatario@email.com"
echo ""
echo "Ler emails:"
echo "mutt"
