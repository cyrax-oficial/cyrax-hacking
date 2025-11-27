#!/bin/bash
# Analyzer PRO - Análise avançada com IA
TARGET="${1:-}"
THREADS="${2:-10}"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL> [THREADS]"
    exit 1
fi

echo "=== ANALYZER PRO ==="
echo "Alvo: $TARGET"
echo "Threads: $THREADS"
echo ""
echo "Analisando tecnologias..."
whatweb "$TARGET" 2>/dev/null || echo "whatweb não disponível"
echo ""
echo "Análise concluída!"
