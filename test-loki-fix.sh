#!/bin/bash

echo "=== ТЕСТИРОВАНИЕ ИСПРАВЛЕНИЙ LOKI/PROMTAIL ==="

echo "1. Останавливаем все контейнеры:"
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo ""
echo "2. Запускаем стек заново:"
cd /opt/devops-portfolio
docker compose up -d

echo ""
echo "3. Ждем запуска (30 секунд):"
sleep 30

echo ""
echo "4. Проверяем статус контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "5. Проверяем логи Promtail:"
docker logs promtail --tail 20

echo ""
echo "6. Проверяем, что Promtail видит контейнеры:"
curl -s http://localhost:9080/api/v1/targets | jq '.data[] | {job: .labels.job, container: .labels.container, service: .labels.service}' 2>/dev/null || echo "Ошибка получения targets"

echo ""
echo "7. Проверяем Loki API:"
curl -s "http://localhost:3100/loki/api/v1/query?query={job=\"docker\"}" | jq '.data.result | length' 2>/dev/null || echo "Ошибка запроса к Loki"

echo ""
echo "8. Проверяем логи конкретного контейнера (app):"
curl -s "http://localhost:3100/loki/api/v1/query?query={container=\"app\"}" | jq '.data.result | length' 2>/dev/null || echo "Ошибка запроса к Loki"

echo ""
echo "9. Проверяем Grafana дашборды:"
curl -s -u admin:admin http://localhost:3001/api/search?type=dash-db | jq '.[].title' 2>/dev/null || echo "Ошибка получения дашбордов"

echo ""
echo "10. Проверяем метрики Promtail:"
curl -s http://localhost:9080/metrics | grep promtail | head -5

echo ""
echo "=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ==="
