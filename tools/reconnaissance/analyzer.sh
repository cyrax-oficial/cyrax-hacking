#!/bin/bash
# Analyzer - Análise básica
TARGET="${1:-}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL>"
    exit 1
fi

echo "=== ANALYZER BÁSICO ==="
echo "Alvo: $TARGET"
echo ""
curl -I "$TARGET" 2>/dev/null || echo "Erro ao conectar"
