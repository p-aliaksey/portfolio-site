#!/bin/bash

echo "=========================================="
echo "ТЕСТ ОПТИМИЗИРОВАННОГО РАЗВЕРТЫВАНИЯ"
echo "=========================================="

echo "=== 1. ПРОВЕРКА КОНФИГУРАЦИИ ==="
echo "1.1. Docker Compose:"
grep -c "services:" docker-compose.yml
echo "Сервисов в docker-compose.yml: $(grep -c "container_name:" docker-compose.yml)"

echo -e "\n1.2. Nginx конфиги:"
ls -la infra/nginx/

echo -e "\n1.3. Grafana конфигурация:"
grep -E "root_url|serve_from_sub_path" infra/monitoring/grafana/grafana.ini

echo -e "\n=== 2. ТЕСТЫ ДОСТУПНОСТИ ==="
echo "2.1. Главная страница:"
curl -I https://pishchik-dev.tech/ 2>/dev/null | head -3

echo -e "\n2.2. Grafana:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3

echo -e "\n2.3. Prometheus:"
curl -I https://pishchik-dev.tech/prometheus/ 2>/dev/null | head -3

echo -e "\n2.4. Loki:"
curl -I https://pishchik-dev.tech/loki/ 2>/dev/null | head -3

echo -e "\n=== 3. ПРОВЕРКА КОНТЕЙНЕРОВ ==="
echo "3.1. Статус всех контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n3.2. Логи Grafana (последние 3 строки):"
docker logs grafana --tail 3

echo -e "\n3.3. Логи Nginx (последние 3 строки):"
docker logs nginx --tail 3

echo -e "\n=========================================="
echo "ТЕСТ ЗАВЕРШЕН"
echo "=========================================="
