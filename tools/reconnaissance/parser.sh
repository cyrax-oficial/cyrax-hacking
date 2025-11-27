#!/bin/bash
# Parser JSON
URL="${1:-}"
TYPE="${2:-endpoints}"

if [ -z "$URL" ]; then
    echo "Uso: $0 <URL> [TYPE]"
    exit 1
fi

echo "=== JSON PARSER ==="
echo "URL: $URL"
echo "Tipo: $TYPE"
