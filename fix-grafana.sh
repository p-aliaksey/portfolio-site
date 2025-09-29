#!/bin/bash

echo "=========================================="
echo "ИСПРАВЛЕНИЕ GRAFANA"
echo "=========================================="

echo "=== 1. ОСТАНОВКА GRAFANA ==="
echo "Останавливаем grafana контейнер..."
docker stop grafana

echo -e "\n=== 2. УДАЛЕНИЕ GRAFANA КОНТЕЙНЕРА ==="
echo "Удаляем grafana контейнер..."
docker rm grafana

echo -e "\n=== 3. ЗАПУСК GRAFANA С НОВОЙ КОНФИГУРАЦИЕЙ ==="
echo "Запускаем grafana с исправленной конфигурацией..."
docker compose up -d grafana

echo -e "\n=== 4. ОЖИДАНИЕ ЗАПУСКА ==="
echo "Ждем 15 секунд для полного запуска..."
sleep 15

echo -e "\n=== 5. ПРОВЕРКА СТАТУСА ==="
echo "Проверяем статус grafana..."
docker ps | grep grafana

echo -e "\n=== 6. ТЕСТИРОВАНИЕ ==="
echo "Тестируем grafana..."

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

test_url "Grafana" "https://pishchik-dev.tech/grafana/"

echo -e "\n=== 7. ПРОВЕРКА ВНУТРЕННЕГО ПОРТА ==="
echo -n "Grafana (3000): "
docker exec nginx curl -s -o /dev/null -w "%{http_code}" http://grafana:3000/ 2>/dev/null && echo -e "\033[0;32m✓\033[0m" || echo -e "\033[0;31m✗\033[0m"

echo -e "\n=========================================="
echo "ИСПРАВЛЕНИЕ GRAFANA ЗАВЕРШЕНО"
echo "=========================================="
