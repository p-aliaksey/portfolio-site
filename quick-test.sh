#!/bin/bash

echo "=========================================="
echo "БЫСТРЫЙ ТЕСТ UI СЕРВИСОВ"
echo "=========================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для быстрого тестирования
quick_test() {
    local name=$1
    local url=$2
    
    echo -n "Тестируем $name... "
    
    # Получаем HTTP код и время ответа
    response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" "$url" 2>/dev/null)
    http_code=$(echo $response | cut -d'|' -f1)
    time_total=$(echo $response | cut -d'|' -f2)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ $http_code (${time_total}s)${NC}"
    elif [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        echo -e "${YELLOW}→ $http_code (${time_total}s) - редирект${NC}"
    else
        echo -e "${RED}✗ $http_code (${time_total}s)${NC}"
    fi
}

echo -e "\n${BLUE}=== ПРОВЕРКА КОНТЕЙНЕРОВ ===${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}" | head -6

echo -e "\n${BLUE}=== ТЕСТИРОВАНИЕ URL ===${NC}"
quick_test "Главная страница" "https://pishchik-dev.tech/"
quick_test "Grafana" "https://pishchik-dev.tech/grafana/"
quick_test "Prometheus" "https://pishchik-dev.tech/prometheus/"
quick_test "Loki" "https://pishchik-dev.tech/loki/"

echo -e "\n${BLUE}=== ПРОВЕРКА ВНУТРЕННИХ ПОРТОВ ===${NC}"
echo -n "App (8000): "
docker exec nginx curl -s -o /dev/null -w "%{http_code}" http://app:8000/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

echo -n "Grafana (3000): "
docker exec nginx curl -s -o /dev/null -w "%{http_code}" http://grafana:3000/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

echo -n "Prometheus (9090): "
docker exec nginx curl -s -o /dev/null -w "%{http_code}" http://prometheus:9090/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

echo -n "Loki (3100): "
docker exec nginx curl -s -o /dev/null -w "%{http_code}" http://loki:3100/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

echo -e "\n${BLUE}=== КРАТКИЕ ЛОГИ ===${NC}"
echo "Nginx (последние ошибки):"
docker logs nginx --tail 5 | grep -i error || echo "Ошибок не найдено"

echo -e "\n${YELLOW}Для полной диагностики запустите: ./test-ui-services.sh${NC}"
echo -e "${YELLOW}Для исправления всех UI сервисов: ./fix-all-ui.sh${NC}"
echo -e "${YELLOW}Для полного перезапуска nginx: ./restart-nginx.sh${NC}"
