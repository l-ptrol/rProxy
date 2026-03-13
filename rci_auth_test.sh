#!/bin/sh
# rci_auth_test.sh
# Скрипт для тестирования авторизации Keenetic RCI через X-NDM-Challenge

USER="${1:-admin}"
PASS="${2:-password}"
IP="${3:-192.168.1.1}"

echo "=== Тест авторизации Keenetic RCI ($IP) ==="

# 1. Получаем challenge и realm
echo "Шаг 1: Получение challenge..."
resp_headers=$(curl -s -i "http://$IP/rci/system/hostname" | tr -d '\r')
realm=$(echo "$resp_headers" | grep -i "X-NDM-Realm" | cut -d' ' -f2)
challenge=$(echo "$resp_headers" | grep -i "X-NDM-Challenge" | cut -d' ' -f2)

if [ -z "$challenge" ]; then
    echo "Ошибка: Не удалось получить challenge. Проверьте IP или доступность RCI."
    exit 1
fi

echo "  Realm: $realm"
echo "  Challenge: $challenge"

# 2. Считаем MD5(login:realm:password)
# -n в echo важно, чтобы не было лишнего перевода строки
h1=$(echo -n "$USER:$realm:$PASS" | md5sum | cut -d' ' -f1)
echo "Шаг 2: MD5(login:realm:password) = $h1"

# 3. Считаем SHA256(challenge + h1)
# challenge — это бинарная строка? Нет, обычно это hex или string.
# В Keenetic challenge (salt) конкатенируется с MD5 хешем (в виде строки).
hash=$(echo -n "$challenge$h1" | sha256sum | cut -d' ' -f1)
echo "Шаг 3: SHA256(challenge + MD5) = $hash"

# 4. Пробуем авторизоваться
echo "Шаг 4: Попытка запроса с хешем..."
# Мы передаем HASH вместо пароля в Basic Auth
result=$(curl -s -u "$USER:$hash" "http://$IP/rci/system/hostname")

if echo "$result" | grep -q "hostname"; then
    echo "БИНГО! Авторизация через Basic Auth (Password=Hash) успешна."
    echo "Ответ: $result"
else
    echo "Метод 1 (Basic Auth) не удался. Пробуем Метод 2 (X-NDM-Auth-Hash)..."
    result=$(curl -s -H "X-NDM-Auth-Hash: $hash" "http://$IP/rci/system/hostname")
    if echo "$result" | grep -q "hostname"; then
        echo "БИНГО! Авторизация через заголовок X-NDM-Auth-Hash успешна."
        echo "Ответ: $result"
    else
        echo "Упс... Оба метода не удались."
        echo "Полный ответ:"
        echo "$result"
    fi
fi
