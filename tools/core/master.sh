#!/bin/bash
# MASTER TOOL - Coordenador inteligente de todas as ferramentas
echo "=== MASTER RECONNAISSANCE TOOL ==="

TOOLS_DIR="$(dirname "$0")"
TARGET="$1"
MODE="$2"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <TARGET> [MODE]"
    echo "Modos: quick, full, stealth, aggressive"
    echo "Exemplo: $0 example.com full"
    exit 1
fi

MODE=${MODE:-"quick"}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="/tmp/recon_${TARGET//[^a-zA-Z0-9]/_}_$TIMESTAMP"
mkdir -p "$REPORT_DIR"

echo "🎯 Target: $TARGET"
echo "🔧 Mode: $MODE"
echo "📁 Report: $REPORT_DIR"

# Função para executar com timeout e log
run_tool() {
    local tool="$1"
    local args="$2"
    local timeout_val="$3"
    local output_file="$REPORT_DIR/${tool}_output.txt"
    
    echo "🔄 Executando: $tool $args"
    timeout "$timeout_val" bash "$TOOLS_DIR/$tool.sh" $args > "$output_file" 2>&1 &
    local pid=$!
    
    # Mostrar progresso
    while kill -0 $pid 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo " ✅"
    
    # Verificar se encontrou algo importante
    if grep -qi "sucesso\|encontrado\|vulnerável\|crítico" "$output_file"; then
        echo "⚠️  ACHADOS IMPORTANTES em $tool!"
    fi
}

# Workflow baseado no modo
case "$MODE" in
    "quick")
        echo -e "\n🚀 MODO RÁPIDO - Reconhecimento básico"
        run_tool "mapper" "$TARGET" "60s"
        run_tool "analyzer" "http://$TARGET" "45s"
        run_tool "sensitive" "http://$TARGET" "30s"
        ;;
        
    "full")
        echo -e "\n🔍 MODO COMPLETO - Análise profunda"
        run_tool "mapper" "$TARGET" "120s" &
        run_tool "analyzer" "http://$TARGET" "90s" &
        run_tool "analyzer" "https://$TARGET" "90s" &
        wait
        
        run_tool "sensitive" "http://$TARGET" "60s" &
        run_tool "email" "http://$TARGET" "45s" &
        run_tool "parser" "http://$TARGET/api" "endpoints" &
        wait
        
        # Se encontrou admin/login, testar bypass
        if grep -q "admin\|login" "$REPORT_DIR"/*.txt; then
            run_tool "bypass" "http://$TARGET/admin" "60s"
            run_tool "brute" "http" "http://$TARGET/login" "120s"
        fi
        ;;
        
    "stealth")
        echo -e "\n👤 MODO STEALTH - Máxima evasão"
        run_tool "stealth" "$TARGET" "300s"
        sleep 30
        run_tool "analyzer" "http://$TARGET" "120s"
        sleep 20
        run_tool "sensitive" "http://$TARGET" "90s"
        ;;
        
    "aggressive")
        echo -e "\n⚡ MODO AGRESSIVO - Todos os exploits"
        # Executar tudo em paralelo
        run_tool "mapper" "$TARGET" "180s" &
        run_tool "analyzer" "http://$TARGET" "120s" &
        run_tool "analyzer" "https://$TARGET" "120s" &
        run_tool "exploit" "http://$TARGET" "150s" &
        run_tool "brute" "ssh" "$TARGET" "300s" &
        wait
        
        run_tool "sensitive" "http://$TARGET" "90s" &
        run_tool "email" "http://$TARGET" "60s" &
        run_tool "jwt" "http://$TARGET/api/token" "45s" &
        run_tool "keycloak" "http://$TARGET" "120s" &
        wait
        ;;
esac

# Gerar relatório inteligente
echo -e "\n📊 Gerando relatório inteligente..."

FINAL_REPORT="$REPORT_DIR/FINAL_REPORT.md"

cat > "$FINAL_REPORT" <<EOF
# RECONNAISSANCE REPORT
**Target:** $TARGET  
**Mode:** $MODE  
**Date:** $(date)  
**Duration:** $SECONDS seconds

## 🎯 EXECUTIVE SUMMARY
EOF

# Analisar resultados e gerar resumo
CRITICAL_FINDINGS=0
HIGH_FINDINGS=0
MEDIUM_FINDINGS=0

for file in "$REPORT_DIR"/*.txt; do
    if [ -f "$file" ]; then
        tool_name=$(basename "$file" _output.txt)
        
        # Contar achados por severidade
        critical=$(grep -ci "crítico\|critical\|sucesso\|success" "$file" 2>/dev/null || echo 0)
        high=$(grep -ci "vulnerável\|vulnerable\|encontrado\|found" "$file" 2>/dev/null || echo 0)
        medium=$(grep -ci "possível\|possible\|atenção\|warning" "$file" 2>/dev/null || echo 0)
        
        CRITICAL_FINDINGS=$((CRITICAL_FINDINGS + critical))
        HIGH_FINDINGS=$((HIGH_FINDINGS + high))
        MEDIUM_FINDINGS=$((MEDIUM_FINDINGS + medium))
        
        if [ $critical -gt 0 ] || [ $high -gt 0 ]; then
            echo "## 🔥 $tool_name (C:$critical H:$high M:$medium)" >> "$FINAL_REPORT"
            echo '```' >> "$FINAL_REPORT"
            head -20 "$file" >> "$FINAL_REPORT"
            echo '```' >> "$FINAL_REPORT"
            echo "" >> "$FINAL_REPORT"
        fi
    fi
done

# Resumo final
cat >> "$FINAL_REPORT" <<EOF

## 📈 STATISTICS
- 🔴 Critical: $CRITICAL_FINDINGS
- 🟠 High: $HIGH_FINDINGS  
- 🟡 Medium: $MEDIUM_FINDINGS
- ⏱️ Total Time: $SECONDS seconds

## 🎯 NEXT STEPS
EOF

if [ $CRITICAL_FINDINGS -gt 0 ]; then
    echo "1. **IMMEDIATE ACTION REQUIRED** - Critical vulnerabilities found" >> "$FINAL_REPORT"
fi

if [ $HIGH_FINDINGS -gt 0 ]; then
    echo "2. Investigate high-priority findings" >> "$FINAL_REPORT"
fi

echo "3. Review all tool outputs in: $REPORT_DIR" >> "$FINAL_REPORT"

# Mostrar resumo
echo -e "\n🎉 RECONHECIMENTO CONCLUÍDO!"
echo "📊 Achados: 🔴$CRITICAL_FINDINGS 🟠$HIGH_FINDINGS 🟡$MEDIUM_FINDINGS"
echo "📁 Relatório completo: $FINAL_REPORT"

if [ $CRITICAL_FINDINGS -gt 0 ]; then
    echo "⚠️  ATENÇÃO: Vulnerabilidades críticas encontradas!"
fi