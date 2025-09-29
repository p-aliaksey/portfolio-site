#!/bin/bash

echo " ТЕСТ ИНТЕГРАЦИИ LOKI И PROMTAIL - $(date)"
echo "================================================"

# 1. Проверка контейнеров
echo " 1. СТАТУС КОНТЕЙНЕРОВ:"
echo "----------------------------------------"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(loki|promtail|grafana|nginx|app)"
echo ""

# 2. Проверка логов Promtail
echo " 2. ЛОГИ PROMTAIL (последние 10):"
echo "----------------------------------------"
if docker ps | grep -q promtail; then
    echo " Promtail запущен"
    docker logs promtail --tail 10
else
    echo " Promtail не запущен"
    docker logs promtail --tail 20
fi
echo ""

# 3. Проверка логов Loki
echo " 3. ЛОГИ LOKI (последние 10):"
echo "----------------------------------------"
if docker ps | grep -q loki; then
    echo " Loki запущен"
    docker logs loki --tail 10
else
    echo " Loki не запущен"
    docker logs loki --tail 20
fi
echo ""

# 4. Тест API Loki
echo " 4. ТЕСТ API LOKI:"
echo "----------------------------------------"
echo "Loki ready endpoint:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3100/ready
echo ""

echo "Loki labels endpoint:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3100/loki/api/v1/labels
echo ""

echo "Loki query endpoint:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://localhost:3100/loki/api/v1/query?query={job=\"docker\"}"
echo ""

# 5. Тест через nginx
echo " 5. ТЕСТ ЧЕРЕЗ NGINX:"
echo "----------------------------------------"
echo "Loki ready через nginx:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://pishchik-dev.tech/loki/ready
echo ""

echo "Loki labels через nginx:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://pishchik-dev.tech/loki/api/v1/labels
echo ""

# 6. Проверка конфигурации Promtail
echo " 6. КОНФИГУРАЦИЯ PROMTAIL:"
echo "----------------------------------------"
if docker ps | grep -q promtail; then
    echo "Проверка конфигурации Promtail:"
    docker exec promtail cat /etc/promtail/promtail-config.yml | grep -A 20 "relabel_configs:"
else
    echo " Promtail не запущен - конфигурацию проверить нельзя"
fi
echo ""

# 7. Проверка меток в Loki
echo " 7. МЕТКИ В LOKI:"
echo "----------------------------------------"
echo "Доступные метки:"
curl -s http://localhost:3100/loki/api/v1/labels 2>/dev/null | jq -r '.data[]' 2>/dev/null || echo "Ошибка получения меток"
echo ""

echo "Значения метки 'job':"
curl -s "http://localhost:3100/loki/api/v1/label/job/values" 2>/dev/null | jq -r '.data[]' 2>/dev/null || echo "Ошибка получения значений job"
echo ""

echo "Значения метки 'container':"
curl -s "http://localhost:3100/loki/api/v1/label/container/values" 2>/dev/null | jq -r '.data[]' 2>/dev/null || echo "Ошибка получения значений container"
echo ""

# 8. Тест запроса логов
echo " 8. ТЕСТ ЗАПРОСА ЛОГОВ:"
echo "----------------------------------------"
echo "Запрос логов за последний час:"
curl -s "http://localhost:3100/loki/api/v1/query_range?query={job=\"docker\"}&start=$(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S.000Z)&end=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" 2>/dev/null | jq -r '.data.result | length' 2>/dev/null || echo "Ошибка запроса логов"
echo ""

# 9. Проверка подключения Promtail к Loki
echo " 9. ПОДКЛЮЧЕНИЕ PROMTAIL К LOKI:"
echo "----------------------------------------"
if docker ps | grep -q promtail; then
    echo "Promtail может подключиться к Loki:"
    docker exec promtail curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://loki:3100/ready 2>/dev/null || echo "Ошибка подключения"
    echo ""
    echo "Promtail может отправить данные в Loki:"
    docker exec promtail curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -X POST http://loki:3100/loki/api/v1/push 2>/dev/null || echo "Ошибка отправки данных"
else
    echo " Promtail не запущен - подключение проверить нельзя"
fi
echo ""

# 10. Проверка Grafana подключения к Loki
echo " 10. GRAFANA ПОДКЛЮЧЕНИЕ К LOKI:"
echo "----------------------------------------"
if docker ps | grep -q grafana; then
    echo "Grafana может подключиться к Loki:"
    docker exec grafana curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://loki:3100/ready 2>/dev/null || echo "Ошибка подключения"
    echo ""
    echo "Grafana может получить метки из Loki:"
    docker exec grafana curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://loki:3100/loki/api/v1/labels 2>/dev/null || echo "Ошибка получения меток"
else
    echo " Grafana не запущен - подключение проверить нельзя"
fi
echo ""

# 11. Статистика ошибок Promtail
echo " 11. СТАТИСТИКА ОШИБОК PROMTAIL:"
echo "----------------------------------------"
if docker ps | grep -q promtail; then
    echo "Количество ошибок 400 за последние 5 минут:"
    docker logs promtail --since 5m 2>&1 | grep -c "status=400" || echo "0"
    echo ""
    echo "Последние 3 ошибки:"
    docker logs promtail --since 5m 2>&1 | grep "status=400" | tail -3 || echo "Ошибок не найдено"
else
    echo " Promtail не запущен - статистику проверить нельзя"
fi
echo ""

# 12. Итоговый статус
echo " 12. ИТОГОВЫЙ СТАТУС:"
echo "================================================"
echo "Loki API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Loki через nginx: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/loki/ready 2>/dev/null)"
echo "Loki labels: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/loki/api/v1/labels 2>/dev/null)"
echo "Promtail статус: $(docker ps | grep promtail | awk '{print $7}' || echo "Не запущен")"
echo "Loki статус: $(docker ps | grep loki | awk '{print $7}' || echo "Не запущен")"
echo ""

echo " Тест интеграции Loki завершен - $(date)"
