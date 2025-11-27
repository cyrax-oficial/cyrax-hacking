#!/bin/bash
# Llama AI Local - IA Avançada para Hacking
echo "=== LLAMA AI HACKING ==="

# Verificar se Ollama está instalado
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama não encontrado. Instalando..."
    
    # Instalar Ollama
    curl -fsSL https://ollama.ai/install.sh | sh
    
    # Iniciar serviço
    systemctl start ollama
    systemctl enable ollama
    
    echo "✅ Ollama instalado!"
fi

# Verificar se modelo está baixado
if ! ollama list | grep -q "llama3.2"; then
    echo "📥 Baixando Llama 3.2 (3B) - Otimizado para hacking..."
    ollama pull llama3.2:3b
fi

if [ -z "$1" ]; then
    echo "Uso: $0 <PERGUNTA_HACKING>"
    echo "Exemplo: $0 'Como explorar Keycloak 8.1.3?'"
    echo "Exemplo: $0 'JWT none algorithm attack'"
    echo "Exemplo: $0 'Bypass WAF com headers'"
    exit 1
fi

QUERY="$1"

# Prompt especializado em hacking
HACKING_PROMPT="Você é um especialista em ethical hacking e penetration testing. 
Responda de forma técnica e prática sobre: $QUERY

Foque em:
- Técnicas específicas de exploit
- Comandos práticos
- Ferramentas recomendadas
- Payloads funcionais
- Bypasses conhecidos

Seja direto e técnico. Forneça exemplos de código quando possível."

echo "🦙 Llama analisando: $QUERY"
echo "⏳ Processando..."

# Executar Llama com prompt especializado
ollama run llama3.2:3b "$HACKING_PROMPT"

echo -e "\n🔧 FERRAMENTAS RELACIONADAS:"

# Sugerir ferramentas baseadas na query
if [[ "$QUERY" =~ (jwt|token) ]]; then
    echo "• ./jwt.sh <token> - Análise JWT"
elif [[ "$QUERY" =~ (waf|bypass|403) ]]; then
    echo "• ./bypass.sh <url> - WAF bypass"
elif [[ "$QUERY" =~ (sql|injection) ]]; then
    echo "• ./exploit.sh <url> - SQL injection"
elif [[ "$QUERY" =~ (keycloak|oauth) ]]; then
    echo "• ./keycloak.sh <url> - Keycloak exploits"
elif [[ "$QUERY" =~ (scan|recon) ]]; then
    echo "• ./mapper.sh <target> - Network scan"
    echo "• ./stealth.sh <target> - Stealth scan"
else
    echo "• ./tools.sh - Ver todas as ferramentas"
fi

echo -e "\n💡 Use './llama.sh \"pergunta mais específica\"' para detalhes"