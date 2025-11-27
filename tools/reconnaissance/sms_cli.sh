#!/bin/bash
# SMS CLI via TextBelt API

echo "=== SMS CLI ==="
echo ""

PHONE="${1:-}"
MESSAGE="${2:-Test message from CYRAX}"

if [ -z "$PHONE" ]; then
    echo "Uso: $0 <NUMERO> [MENSAGEM]"
    echo "Exemplo: $0 +5511999999999 'Olá do CYRAX'"
    exit 1
fi

echo "Enviando SMS para $PHONE..."
echo ""

# TextBelt API (1 SMS grátis por dia)
curl -X POST https://textbelt.com/text \
  --data-urlencode phone="$PHONE" \
  --data-urlencode message="$MESSAGE" \
  -d key=textbelt

echo ""
echo ""
echo "Alternativas:"
echo "1. Twilio CLI: twilio api:core:messages:create --from +15551234567 --to $PHONE --body '$MESSAGE'"
echo "2. Nexmo CLI: nexmo sms $PHONE '$MESSAGE'"
