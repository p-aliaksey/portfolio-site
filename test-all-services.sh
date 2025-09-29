#!/bin/bash

echo " ТЕСТ ВСЕХ СЕРВИСОВ - $(date)"
echo "================================================"

# 1. Проверка контейнеров
echo " 1. СТАТУС КОНТЕЙНЕРОВ:"
echo "----------------------------------------"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 2. Проверка логов nginx
echo " 2. ЛОГИ NGINX:"
echo "----------------------------------------"
if docker ps | grep -q nginx; then
    echo " Nginx запущен"
    docker logs nginx --tail 5
else
    echo " Nginx не запущен"
    docker logs nginx --tail 10
fi
echo ""

# 3. Проверка логов grafana
echo " 3. ЛОГИ GRAFANA:"
echo "----------------------------------------"
if docker ps | grep -q grafana; then
    echo " Grafana запущен"
    docker logs grafana --tail 3
else
    echo " Grafana не запущен"
    docker logs grafana --tail 5
fi
echo ""

# 4. Проверка логов loki
echo " 4. ЛОГИ LOKI:"
echo "----------------------------------------"
if docker ps | grep -q loki; then
    echo " Loki запущен"
    docker logs loki --tail 3
else
    echo " Loki не запущен"
    docker logs loki --tail 5
fi
echo ""

# 5. Проверка конфигурации nginx
echo " 5. КОНФИГУРАЦИЯ NGINX:"
echo "----------------------------------------"
if docker ps | grep -q nginx; then
    echo "Проверка синтаксиса nginx:"
    docker exec nginx nginx -t 2>&1
    echo ""
    echo "Grafana location:"
    docker exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 10 "location /grafana"
    echo ""
    echo "Loki location:"
    docker exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 10 "location /loki"
else
    echo " Nginx не запущен - конфигурацию проверить нельзя"
fi
echo ""

# 6. Тест URL
echo " 6. ТЕСТ URL:"
echo "----------------------------------------"
echo "Главная страница:"
curl -I https://pishchik-dev.tech/ 2>/dev/null | head -3
echo ""

echo "Grafana:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3
echo ""

echo "Loki:"
curl -I https://pishchik-dev.tech/loki/ 2>/dev/null | head -3
echo ""

echo "Prometheus:"
curl -I https://pishchik-dev.tech/prometheus/ 2>/dev/null | head -3
echo ""

# 7. Тест внутренних соединений
echo " 7. ВНУТРЕННИЕ СОЕДИНЕНИЯ:"
echo "----------------------------------------"
if docker ps | grep -q nginx; then
    echo "Nginx -> Grafana:"
    docker exec nginx curl -I http://grafana:3000/ 2>/dev/null | head -2
    echo ""
    echo "Nginx -> Loki:"
    docker exec nginx curl -I http://loki:3100/ 2>/dev/null | head -2
    echo ""
    echo "Nginx -> Prometheus:"
    docker exec nginx curl -I http://prometheus:9090/ 2>/dev/null | head -2
else
    echo " Nginx не запущен - внутренние соединения проверить нельзя"
fi
echo ""

# 8. Итоговый статус
echo " 8. ИТОГОВЫЙ СТАТУС:"
echo "================================================"
echo "Главная страница: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/ 2>/dev/null)"
echo "Grafana: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/grafana/ 2>/dev/null)"
echo "Loki: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/loki/ 2>/dev/null)"
echo "Prometheus: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/prometheus/ 2>/dev/null)"
echo ""

echo " Тест завершен - $(date)"
