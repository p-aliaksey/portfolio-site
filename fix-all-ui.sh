#!/bin/bash

echo "=========================================="
echo "ИСПРАВЛЕНИЕ ВСЕХ UI СЕРВИСОВ"
echo "=========================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}=== 1. ОСТАНОВКА ВСЕХ КОНТЕЙНЕРОВ ===${NC}"
docker compose down

echo -e "\n${BLUE}=== 2. ОЧИСТКА DOCKER ===${NC}"
docker system prune -f

echo -e "\n${BLUE}=== 3. ЗАПУСК ВСЕХ СЕРВИСОВ ===${NC}"
docker compose up -d

echo -e "\n${BLUE}=== 4. ОЖИДАНИЕ ЗАПУСКА ===${NC}"
echo "Ждем 60 секунд для полного запуска всех сервисов..."
sleep 60

echo -e "\n${BLUE}=== 5. ПРОВЕРКА СТАТУСА КОНТЕЙНЕРОВ ===${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${BLUE}=== 6. ПРОВЕРКА ВНУТРЕННЕЙ СВЯЗНОСТИ ===${NC}"
echo "Проверяем доступность сервисов внутри Docker сети..."

# Функция для проверки внутренних портов
check_internal() {
    local service=$1
    local port=$2
    local name=$3
    
    echo -n "$name ($port): "
    response=$(docker exec nginx curl -s -o /dev/null -w "%{http_code}" "http://$service:$port/" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ $response${NC}"
    elif [ "$response" = "301" ] || [ "$response" = "302" ]; then
        echo -e "${YELLOW}→ $response (редирект)${NC}"
    else
        echo -e "${RED}✗ $response${NC}"
    fi
}

check_internal "app" "8000" "App"
check_internal "grafana" "3000" "Grafana"
check_internal "prometheus" "9090" "Prometheus"
check_internal "loki" "3100" "Loki"

echo -e "\n${BLUE}=== 7. ТЕСТИРОВАНИЕ ВНЕШНИХ URL ===${NC}"

# Функция для тестирования URL
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

echo -e "\n${BLUE}=== 8. ПРОВЕРКА ЛОГОВ ===${NC}"
echo "Логи nginx (последние 10 строк):"
docker logs nginx --tail 10

echo -e "\n${GREEN}=========================================="
echo "ИСПРАВЛЕНИЕ ЗАВЕРШЕНО"
echo "==========================================${NC}"

echo -e "\n${YELLOW}Проверьте доступность сервисов:${NC}"
echo "- Главная страница: https://pishchik-dev.tech/"
echo "- Grafana: https://pishchik-dev.tech/grafana/"
echo "- Prometheus: https://pishchik-dev.tech/prometheus/"
echo "- Loki: https://pishchik-dev.tech/loki/"
