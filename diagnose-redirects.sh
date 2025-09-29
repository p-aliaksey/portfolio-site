#!/bin/bash

echo "=========================================="
echo "ДИАГНОСТИКА РЕДИРЕКТОВ И СЕРВИСОВ"
echo "=========================================="

echo "=== 1. ПРОВЕРКА КОНТЕЙНЕРОВ ==="
echo "1.1. Статус всех контейнеров:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n1.2. Проверка портов:"
netstat -tlnp | grep -E ":(80|443|3000|9090|3100|8000)" || ss -tlnp | grep -E ":(80|443|3000|9090|3100|8000)"

echo -e "\n=== 2. ПРОВЕРКА NGINX ==="
echo "2.1. Логи Nginx (последние 20 строк):"
docker logs nginx --tail 20

echo -e "\n2.2. Конфигурация Nginx:"
docker exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 10 -B 5 "location /"

echo -e "\n2.3. Тест синтаксиса Nginx:"
docker exec nginx nginx -t

echo -e "\n=== 3. ПРОВЕРКА GRAFANA ==="
echo "3.1. Логи Grafana (последние 10 строк):"
docker logs grafana --tail 10

echo "3.2. Конфигурация Grafana:"
docker exec grafana cat /etc/grafana/grafana.ini | grep -E "root_url|serve_from_sub_path|domain"

echo "3.3. Тест прямого доступа к Grafana:"
curl -I http://localhost:3000/ 2>/dev/null | head -5

echo -e "\n=== 4. ПРОВЕРКА PROMETHEUS ==="
echo "4.1. Логи Prometheus (последние 5 строк):"
docker logs prometheus --tail 5

echo "4.2. Тест прямого доступа к Prometheus:"
curl -I http://localhost:9090/ 2>/dev/null | head -5

echo -e "\n=== 5. ПРОВЕРКА LOKI ==="
echo "5.1. Логи Loki (последние 5 строк):"
docker logs loki --tail 5

echo "5.2. Тест прямого доступа к Loki:"
curl -I http://localhost:3100/ 2>/dev/null | head -5

echo -e "\n=== 6. ТЕСТЫ HTTP/HTTPS ==="
echo "6.1. Тест HTTP (должен редиректить на HTTPS):"
curl -I http://pishchik-dev.tech/ 2>/dev/null | head -5

echo -e "\n6.2. Тест HTTPS главной страницы:"
curl -I https://pishchik-dev.tech/ 2>/dev/null | head -5

echo -e "\n6.3. Тест HTTPS Grafana (с максимальными редиректами):"
curl -L --max-redirs 10 -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -10

echo -e "\n6.4. Тест HTTPS Prometheus:"
curl -I https://pishchik-dev.tech/prometheus/ 2>/dev/null | head -5

echo -e "\n6.5. Тест HTTPS Loki:"
curl -I https://pishchik-dev.tech/loki/ 2>/dev/null | head -5

echo -e "\n=== 7. ПРОВЕРКА SSL СЕРТИФИКАТОВ ==="
echo "7.1. Проверка SSL сертификата:"
openssl s_client -connect pishchik-dev.tech:443 -servername pishchik-dev.tech < /dev/null 2>/dev/null | openssl x509 -noout -dates

echo -e "\n7.2. Проверка цепочки сертификатов:"
openssl s_client -connect pishchik-dev.tech:443 -servername pishchik-dev.tech < /dev/null 2>/dev/null | openssl x509 -noout -issuer

echo -e "\n=== 8. ПРОВЕРКА СЕТИ ==="
echo "8.1. DNS резолюция:"
nslookup pishchik-dev.tech

echo -e "\n8.2. Ping тест:"
ping -c 3 pishchik-dev.tech

echo -e "\n=== 9. ПРОВЕРКА КОНФИГУРАЦИЙ ==="
echo "9.1. Docker Compose конфигурация:"
grep -A 5 -B 5 "grafana:" docker-compose.yml

echo -e "\n9.2. Nginx конфигурация (локальная):"
grep -A 10 "location /grafana" infra/nginx/nginx.conf

echo -e "\n9.3. Grafana конфигурация (локальная):"
grep -E "root_url|serve_from_sub_path" infra/monitoring/grafana/grafana.ini

echo -e "\n=== 10. ИСПРАВЛЕНИЕ ПРОБЛЕМ ==="
echo "10.1. Перезапуск всех контейнеров:"
echo "docker compose down && docker compose up -d"

echo -e "\n10.2. Очистка кэша браузера:"
echo "Ctrl+Shift+Delete или инкогнито режим"

echo -e "\n10.3. Проверка после исправлений:"
echo "curl -I https://pishchik-dev.tech/grafana/"

echo -e "\n=========================================="
echo "ДИАГНОСТИКА ЗАВЕРШЕНА"
echo "=========================================="
