#!/bin/bash
# Sensitive Data Hunter
URL="${1:-}"

if [ -z "$URL" ]; then
    echo "Uso: $0 <URL>"
    exit 1
fi

echo "=== SENSITIVE DATA HUNTER ==="
echo "URL: $URL"
echo "Procurando dados sensíveis..."
