#!/bin/bash

echo "=========================================="
echo "ПЕРЕЗАГРУЗКА NGINX С НОВОЙ КОНФИГУРАЦИЕЙ"
echo "=========================================="

echo "=== 1. ПРОВЕРКА КОНФИГУРАЦИИ ==="
echo "Тестируем конфигурацию nginx..."
if docker exec nginx nginx -t; then
    echo "✓ Конфигурация nginx корректна"
else
    echo "✗ Ошибка в конфигурации nginx"
    exit 1
fi

echo -e "\n=== 2. ПЕРЕЗАГРУЗКА NGINX ==="
echo "Перезагружаем nginx..."
if docker exec nginx nginx -s reload; then
    echo "✓ Nginx перезагружен успешно"
else
    echo "✗ Ошибка при перезагрузке, перезапускаем контейнер..."
    docker restart nginx
    sleep 5
fi

echo -e "\n=== 3. БЫСТРЫЙ ТЕСТ ==="
echo "Тестируем сервисы..."

# Функция для тестирования
test_url() {
    local name=$1
    local url=$2
    
    echo -n "Тестируем $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo -e "\033[0;32m✓ $response\033[0m"
    elif [ "$response" = "301" ] || [ "$response" = "302" ]; then
        echo -e "\033[1;33m→ $response (редирект)\033[0m"
    else
        echo -e "\033[0;31m✗ $response\033[0m"
    fi
}

test_url "Главная страница" "https://pishchik-dev.tech/"
test_url "Grafana" "https://pishchik-dev.tech/grafana/"
test_url "Prometheus" "https://pishchik-dev.tech/prometheus/"
test_url "Loki" "https://pishchik-dev.tech/loki/"

echo -e "\n=========================================="
echo "ПЕРЕЗАГРУЗКА ЗАВЕРШЕНА"
echo "=========================================="
