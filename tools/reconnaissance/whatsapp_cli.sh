#!/bin/bash
# WhatsApp CLI via yowsup

echo "=== WHATSAPP CLI ==="
echo ""

if ! command -v yowsup-cli &> /dev/null; then
    echo "Instalando yowsup..."
    pip3 install yowsup2 --break-system-packages 2>/dev/null || pip3 install yowsup2
fi

echo "Configuração:"
echo "1. Registrar número: yowsup-cli registration --requestcode sms --phone 5511999999999 --cc 55 --mcc 724 --mnc 05"
echo "2. Verificar código: yowsup-cli registration --register 123456 --phone 5511999999999 --cc 55"
echo "3. Enviar mensagem: yowsup-cli demos --config ~/.yowsup/config --send 5511888888888 'Mensagem'"
echo ""
echo "Modo interativo:"
yowsup-cli demos --yowsup
