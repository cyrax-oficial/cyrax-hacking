#!/bin/bash
# Mapper - Mapeamento de rede
TARGET="${1:-}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <TARGET>"
    exit 1
fi

echo "=== NETWORK MAPPER ==="
echo "Alvo: $TARGET"
nmap -sV "$TARGET" 2>/dev/null || echo "nmap não disponível"
