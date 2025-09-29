#!/bin/bash

echo "=========================================="
echo "ПЕРЕЗАПУСК NGINX С ИСПРАВЛЕННОЙ КОНФИГУРАЦИЕЙ"
echo "=========================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}=== 1. ПРОВЕРКА КОНФИГУРАЦИИ ===${NC}"
echo "Тестируем конфигурацию nginx..."
if docker exec nginx nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓ Конфигурация nginx корректна${NC}"
else
    echo -e "${RED}✗ Ошибка в конфигурации nginx${NC}"
    echo "Логи nginx:"
    docker logs nginx --tail 5
    echo -e "\n${YELLOW}Перезапускаем nginx контейнер с новой конфигурацией...${NC}"
fi

echo -e "\n${BLUE}=== 2. ПЕРЕЗАПУСК NGINX ===${NC}"
echo "Останавливаем nginx..."
docker stop nginx

echo "Удаляем nginx контейнер..."
docker rm nginx

echo "Запускаем nginx с исправленной конфигурацией..."
docker compose up -d nginx

echo -e "\n${BLUE}=== 3. ОЖИДАНИЕ ЗАПУСКА ===${NC}"
echo "Ждем 10 секунд для полного запуска..."
sleep 10

echo -e "\n${BLUE}=== 4. ПРОВЕРКА СТАТУСА ===${NC}"
echo "Проверяем статус nginx..."
docker ps | grep nginx

echo -e "\n${BLUE}=== 5. ТЕСТИРОВАНИЕ ===${NC}"
echo "Тестируем сервисы..."

# Функция для тестирования
test_url() {
    local name=$1
    local url=$2
    
    echo -n "Тестируем $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ $response${NC}"
    elif [ "$response" = "301" ] || [ "$response" = "302" ]; then
        echo -e "${YELLOW}→ $response (редирект)${NC}"
    else
        echo -e "${RED}✗ $response${NC}"
    fi
}

test_url "Главная страница" "https://pishchik-dev.tech/"
test_url "Grafana" "https://pishchik-dev.tech/grafana/"
test_url "Prometheus" "https://pishchik-dev.tech/prometheus/"
test_url "Loki" "https://pishchik-dev.tech/loki/"

echo -e "\n${GREEN}=========================================="
echo "ПЕРЕЗАПУСК ЗАВЕРШЕН"
echo "==========================================${NC}"
