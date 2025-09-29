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
    echo ""
    echo "Nginx -> App:"
    docker exec nginx curl -I http://app:8000/ 2>/dev/null | head -2
else
    echo " Nginx не запущен - внутренние соединения проверить нельзя"
fi
echo ""

# 8. Тест Docker сети
echo " 8. DOCKER СЕТЬ:"
echo "----------------------------------------"
echo "Docker сети:"
docker network ls
echo ""
echo "Сеть проекта:"
docker network inspect $(docker network ls -q | head -1) 2>/dev/null | grep -A 5 "Containers" || echo "Не удалось получить информацию о сети"
echo ""

# 9. Тест пробросов портов
echo " 9. ПРОБРОСЫ ПОРТОВ:"
echo "----------------------------------------"
echo "Проверка доступности портов на localhost:"
echo "App (8000): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null)"
echo "Grafana (3000): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null)"
echo "Loki (3100): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Prometheus (9090): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/ 2>/dev/null)"
echo ""

# 10. Тест DNS резолвинга в контейнерах
echo " 10. DNS РЕЗОЛВИНГ:"
echo "----------------------------------------"
if docker ps | grep -q nginx; then
    echo "Nginx может резолвить:"
    docker exec nginx nslookup grafana 2>/dev/null | grep "Address:" | head -1 || echo "Ошибка резолвинга grafana"
    docker exec nginx nslookup loki 2>/dev/null | grep "Address:" | head -1 || echo "Ошибка резолвинга loki"
    docker exec nginx nslookup app 2>/dev/null | grep "Address:" | head -1 || echo "Ошибка резолвинга app"
    docker exec nginx nslookup prometheus 2>/dev/null | grep "Address:" | head -1 || echo "Ошибка резолвинга prometheus"
else
    echo " Nginx не запущен - DNS резолвинг проверить нельзя"
fi
echo ""

# 10.1. Тест подключений между контейнерами
echo " 10.1. ПОДКЛЮЧЕНИЯ МЕЖДУ КОНТЕЙНЕРАМИ:"
echo "----------------------------------------"
echo "App -> Grafana: $(docker exec app curl -s -o /dev/null -w "%{http_code}" http://grafana:3000/ 2>/dev/null || echo "Ошибка")"
echo "App -> Loki: $(docker exec app curl -s -o /dev/null -w "%{http_code}" http://loki:3100/ready 2>/dev/null || echo "Ошибка")"
echo "App -> Prometheus: $(docker exec app curl -s -o /dev/null -w "%{http_code}" http://prometheus:9090/ 2>/dev/null || echo "Ошибка")"
echo "Grafana -> Loki: $(docker exec grafana curl -s -o /dev/null -w "%{http_code}" http://loki:3100/ready 2>/dev/null || echo "Ошибка")"
echo "Grafana -> Prometheus: $(docker exec grafana curl -s -o /dev/null -w "%{http_code}" http://prometheus:9090/ 2>/dev/null || echo "Ошибка")"
echo ""

# 11. Итоговый статус
echo " 11. ИТОГОВЫЙ СТАТУС:"
echo "================================================"
echo "Главная страница: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/ 2>/dev/null)"
echo "Grafana: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/grafana/ 2>/dev/null)"
echo "Loki: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/loki/ 2>/dev/null)"
echo "Prometheus: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/prometheus/ 2>/dev/null)"
echo ""

echo " Тест завершен - $(date)"
