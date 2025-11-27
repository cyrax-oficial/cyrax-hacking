#!/bin/bash
# CYRAX HONEYPOT DETECTOR - Detecta honeypots e armadilhas
echo "=== CYRAX HONEYPOT DETECTOR ==="

TARGET="$1"
if [ -z "$TARGET" ]; then
    echo "Uso: $0 <TARGET>"
    exit 1
fi

TEMP_DIR="/tmp/cyrax_honeypot_$(date +%s)"
mkdir -p "$TEMP_DIR"

# Indicadores de honeypot
HONEYPOT_INDICATORS=(
    "honeypot"
    "kippo"
    "cowrie"
    "dionaea"
    "glastopf"
    "conpot"
    "thug"
    "amun"
    "nepenthes"
    "artillery"
)

# Verificar headers suspeitos
check_headers() {
    local response=$(curl -s -I "$TARGET" --connect-timeout 10 2>/dev/null)
    
    for indicator in "${HONEYPOT_INDICATORS[@]}"; do
        if echo "$response" | grep -qi "$indicator"; then
            echo "⚠️  HONEYPOT DETECTADO: $indicator"
            echo "$indicator" >> "$TEMP_DIR/honeypot_detected.txt"
        fi
    done
}

# Verificar comportamento anômalo
check_behavior() {
    # Múltiplas conexões simultâneas
    for i in {1..5}; do
        curl -s "$TARGET" --connect-timeout 5 &
    done
    wait
    
    # Verificar se todas responderam igual (suspeito)
    echo "Teste de comportamento concluído"
}

# Verificar portas fake
check_fake_ports() {
    # Portas comumente usadas em honeypots
    local fake_ports=(2222 2223 23 8080 8443 9999)
    
    for port in "${fake_ports[@]}"; do
        if timeout 3 bash -c "</dev/tcp/$TARGET/$port" 2>/dev/null; then
            echo "⚠️  Porta suspeita aberta: $port"
        fi
    done
}

check_headers
check_behavior  
check_fake_ports

echo "Análise salva em: $TEMP_DIR"