#!/bin/bash

echo "=========================================="
echo "ПОЛНЫЙ ПЕРЕЗАПУСК NGINX"
echo "=========================================="

echo "=== 1. ОСТАНОВКА NGINX ==="
echo "Останавливаем nginx контейнер..."
docker stop nginx

echo -e "\n=== 2. УДАЛЕНИЕ NGINX КОНТЕЙНЕРА ==="
echo "Удаляем nginx контейнер..."
docker rm nginx

echo -e "\n=== 3. ЗАПУСК NGINX С НОВОЙ КОНФИГУРАЦИЕЙ ==="
echo "Запускаем nginx с обновленной конфигурацией..."
docker compose up -d nginx

echo -e "\n=== 4. ОЖИДАНИЕ ЗАПУСКА ==="
echo "Ждем 10 секунд для полного запуска..."
sleep 10

echo -e "\n=== 5. ПРОВЕРКА СТАТУСА ==="
echo "Проверяем статус nginx..."
docker ps | grep nginx

echo -e "\n=== 6. ТЕСТИРОВАНИЕ ==="
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
echo "ПЕРЕЗАПУСК ЗАВЕРШЕН"
echo "=========================================="
