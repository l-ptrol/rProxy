#!/bin/bash
# test_keenetic_auth.sh
# Использование: ./test_keenetic_auth.sh [USER] [PASS] [IP]

USER="${1:-admin}"
PASS="${2:-12985654}"
IP="${3:-192.168.60.1}"
AUTH_BASE64=$(echo -n "$USER:$PASS" | base64)

echo "=== Диагностика авторизации Keenetic RCI ($IP) ==="
echo "Пользователь: $USER"

test_request() {
    local name="$1"
    local port="$2"
    local headers="$3"
    echo -n "Тест: $name (Порт $port)... "
    
    # Используем curl с таймаутом, чтобы не висело вечно
    local start_time=$(date +%s%3N)
    local out
    # В Windows curl может вести себя иначе, но мы предполагаем запуск на роутере или в bash
    out=$(curl -s -i -m 10 \
        $headers \
        "http://$IP:$port/rci/system/hostname" 2>&1)
    local status=$?
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    if [ $status -eq 0 ]; then
        local code=$(echo "$out" | grep "HTTP/" | tail -1 | awk '{print $2}')
        echo "OK [$code] ($duration ms)"
        if [ "$code" = "401" ]; then
            echo "   Заголовки WWW-Authenticate:"
            echo "$out" | grep -i "WWW-Authenticate" | sed 's/^/   / '
        fi
    elif [ $status -eq 28 ]; then
        echo "TIMEOUT (Зависло!)"
    else
        echo "ERROR (Код curl: $status)"
        echo "$out" | head -n 3 | sed 's/^/   / '
    fi
}

echo "--- Начинаем тесты ---"

# 1. Базовый порт 80, чистый Basic Auth
test_request "Port 80 + Basic Auth" 80 "-H \"Authorization: Basic $AUTH_BASE64\""

# 2. Порт 80 + Метод v1.3.8 (XMLHttpRequest)
test_request "Port 80 + XMLHttpRequest" 80 "-H \"Authorization: Basic $AUTH_BASE64\" -H \"X-Requested-With: XMLHttpRequest\""

# 3. Порт 80 + Метод v1.3.8 (Full X-Headers)
test_request "Port 80 + Full X-Headers" 80 "-H \"Authorization: Basic $AUTH_BASE64\" -H \"X-Requested-With: XMLHttpRequest\" -H \"X-NDM-Auth-Type: Basic\" -H \"Accept: application/json\""

# 4. Порт 79 (Служебный) - Чистый Basic
test_request "Port 79 + Basic Auth" 79 "-H \"Authorization: Basic $AUTH_BASE64\""

# 5. Порт 79 + XMLHttpRequest
test_request "Port 79 + XMLHttpRequest" 79 "-H \"Authorization: Basic $AUTH_BASE64\" -H \"X-Requested-With: XMLHttpRequest\""

echo "--- Диагностика завершена ---"
