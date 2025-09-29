#!/bin/bash

echo "=========================================="
echo "ДИАГНОСТИКА UI СЕРВИСОВ"
echo "=========================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для проверки статуса
check_status() {
    local service=$1
    local url=$2
    local expected_code=$3
    
    echo -e "\n${BLUE}=== ПРОВЕРКА $service ===${NC}"
    echo "URL: $url"
    
    # Проверяем HTTP статус
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✓ Статус: $response (OK)${NC}"
        return 0
    else
        echo -e "${RED}✗ Статус: $response (ожидался $expected_code)${NC}"
        return 1
    fi
}

# Функция для детальной проверки
detailed_check() {
    local service=$1
    local url=$2
    
    echo -e "\n${YELLOW}--- Детальная проверка $service ---${NC}"
    
    # Получаем заголовки
    echo "Заголовки ответа:"
    curl -I "$url" 2>/dev/null | head -10
    
    # Проверяем время ответа
    echo -e "\nВремя ответа:"
    curl -w "Total time: %{time_total}s\n" -o /dev/null -s "$url" 2>/dev/null
    
    # Проверяем редирект
    echo -e "\nПроверка редиректов:"
    curl -L -I "$url" 2>/dev/null | grep -E "(HTTP|Location)" | head -5
}

echo -e "\n${BLUE}=== 1. ПРОВЕРКА КОНТЕЙНЕРОВ ===${NC}"
echo "Статус всех контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${BLUE}=== 2. ПРОВЕРКА ПОРТОВ ===${NC}"
echo "Проверяем доступность портов внутри Docker сети:"

# Проверяем внутренние порты контейнеров
echo -e "\n${YELLOW}--- Внутренние порты ---${NC}"
docker exec nginx curl -s -o /dev/null -w "App (8000): %{http_code}\n" http://app:8000/ 2>/dev/null || echo "App: недоступен"
docker exec nginx curl -s -o /dev/null -w "Grafana (3000): %{http_code}\n" http://grafana:3000/ 2>/dev/null || echo "Grafana: недоступен"
docker exec nginx curl -s -o /dev/null -w "Prometheus (9090): %{http_code}\n" http://prometheus:9090/ 2>/dev/null || echo "Prometheus: недоступен"
docker exec nginx curl -s -o /dev/null -w "Loki (3100): %{http_code}\n" http://loki:3100/ 2>/dev/null || echo "Loki: недоступен"

echo -e "\n${BLUE}=== 3. ПРОВЕРКА ВНЕШНИХ URL ===${NC}"

# Основные проверки
check_status "ГЛАВНАЯ СТРАНИЦА" "https://pishchik-dev.tech/" "200"
check_status "GRAFANA" "https://pishchik-dev.tech/grafana/" "200"
check_status "PROMETHEUS" "https://pishchik-dev.tech/prometheus/" "200"
check_status "LOKI" "https://pishchik-dev.tech/loki/" "200"

echo -e "\n${BLUE}=== 4. ДЕТАЛЬНАЯ ДИАГНОСТИКА ===${NC}"

# Детальные проверки для каждого сервиса
detailed_check "Главная страница" "https://pishchik-dev.tech/"
detailed_check "Grafana" "https://pishchik-dev.tech/grafana/"
detailed_check "Prometheus" "https://pishchik-dev.tech/prometheus/"
detailed_check "Loki" "https://pishchik-dev.tech/loki/"

echo -e "\n${BLUE}=== 5. ПРОВЕРКА ЛОГОВ ===${NC}"

echo -e "\n${YELLOW}--- Логи Nginx (последние 20 строк) ---${NC}"
docker logs nginx --tail 20

echo -e "\n${YELLOW}--- Логи Grafana (последние 10 строк) ---${NC}"
docker logs grafana --tail 10

echo -e "\n${YELLOW}--- Логи Prometheus (последние 10 строк) ---${NC}"
docker logs prometheus --tail 10

echo -e "\n${YELLOW}--- Логи Loki (последние 10 строк) ---${NC}"
docker logs loki --tail 10

echo -e "\n${BLUE}=== 6. ПРОВЕРКА КОНФИГУРАЦИИ NGINX ===${NC}"

echo "Проверяем конфигурацию nginx:"
docker exec nginx nginx -t

echo -e "\nАктивная конфигурация nginx:"
docker exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 5 -B 5 "location"

echo -e "\n${BLUE}=== 7. ПРОВЕРКА СЕТИ ===${NC}"

echo "Проверяем Docker сеть:"
docker network ls
echo -e "\nИнформация о сети:"
docker network inspect mysite_default 2>/dev/null | grep -A 10 "Containers" || echo "Сеть не найдена"

echo -e "\n${BLUE}=== 8. ПРОВЕРКА SSL СЕРТИФИКАТОВ ===${NC}"

echo "Проверяем SSL сертификаты:"
if [ -d "/etc/letsencrypt/live/pishchik-dev.tech" ]; then
    echo "✓ Сертификаты найдены"
    ls -la /etc/letsencrypt/live/pishchik-dev.tech/
    echo -e "\nСрок действия сертификата:"
    openssl x509 -in /etc/letsencrypt/live/pishchik-dev.tech/fullchain.pem -text -noout | grep -A 2 "Validity"
else
    echo -e "${RED}✗ Сертификаты не найдены${NC}"
fi

echo -e "\n${BLUE}=== 9. ТЕСТИРОВАНИЕ БЕЗ SSL ===${NC}"

echo "Тестируем HTTP версии (должны редиректить на HTTPS):"
curl -I http://pishchik-dev.tech/ 2>/dev/null | head -3
curl -I http://pishchik-dev.tech/grafana/ 2>/dev/null | head -3
curl -I http://pishchik-dev.tech/prometheus/ 2>/dev/null | head -3
curl -I http://pishchik-dev.tech/loki/ 2>/dev/null | head -3

echo -e "\n${BLUE}=== 10. РЕКОМЕНДАЦИИ ПО ИСПРАВЛЕНИЮ ===${NC}"

echo -e "\n${YELLOW}Если сервисы недоступны, попробуйте:${NC}"
echo "1. Перезапустить все контейнеры:"
echo "   docker compose down && docker compose up -d"
echo ""
echo "2. Очистить кэш Docker:"
echo "   docker system prune -f"
echo ""
echo "3. Проверить логи конкретного сервиса:"
echo "   docker logs grafana"
echo "   docker logs prometheus"
echo "   docker logs loki"
echo "   docker logs nginx"
echo ""
echo "4. Проверить конфигурацию nginx:"
echo "   docker exec nginx nginx -t"
echo ""
echo "5. Перезагрузить конфигурацию nginx:"
echo "   docker exec nginx nginx -s reload"
echo ""
echo "6. Проверить DNS разрешение:"
echo "   nslookup pishchik-dev.tech"
echo ""
echo "7. Очистить кэш браузера и попробовать в инкогнито режиме"

echo -e "\n${GREEN}=========================================="
echo "ДИАГНОСТИКА ЗАВЕРШЕНА"
echo "==========================================${NC}"
