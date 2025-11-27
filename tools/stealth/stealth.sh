#!/bin/bash
# Stealth Scanner
TARGET="${1:-}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <TARGET>"
    exit 1
fi

echo "=== STEALTH SCANNER ==="
echo "Alvo: $TARGET"
echo "Modo stealth ativado..."
nmap -sS -T2 "$TARGET" 2>/dev/null || echo "nmap não disponível"
