#!/bin/bash

echo "=========================================="
echo "ТЕСТ ИСПРАВЛЕНИЙ GRAFANA HTTPS"
echo "=========================================="

echo "=== 1. ПРОВЕРКА КОНФИГУРАЦИИ ==="
echo "1.1. Проверка grafana.ini:"
grep -E "root_url|serve_from_sub_path|protocol" infra/monitoring/grafana/grafana.ini

echo -e "\n1.2. Проверка docker-compose.yml:"
grep -A 5 -B 5 "GF_SERVER_ROOT_URL" docker-compose.yml

echo -e "\n1.3. Проверка nginx-https.conf:"
grep -A 10 "location /grafana" infra/nginx/nginx-https.conf

echo -e "\n1.4. Проверка monitoring.html:"
grep "href.*grafana" app/templates/monitoring.html

echo -e "\n=== 2. ТЕСТЫ ДОСТУПНОСТИ ==="
echo "2.1. Тест HTTP редиректа:"
curl -I http://pishchik-dev.tech/grafana 2>/dev/null | head -3

echo -e "\n2.2. Тест HTTPS доступа:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3

echo -e "\n2.3. Тест содержимого:"
curl -s https://pishchik-dev.tech/grafana/ 2>/dev/null | head -5

echo -e "\n2.4. Тест API:"
curl -s https://pishchik-dev.tech/grafana/api/health 2>/dev/null

echo -e "\n=== 3. ПРОВЕРКА СЕРТИФИКАТОВ ==="
echo "3.1. Проверка SSL сертификата:"
openssl s_client -connect pishchik-dev.tech:443 -servername pishchik-dev.tech < /dev/null 2>/dev/null | openssl x509 -noout -dates

echo -e "\n3.2. Проверка цепочки сертификатов:"
openssl s_client -connect pishchik-dev.tech:443 -servername pishchik-dev.tech < /dev/null 2>/dev/null | openssl x509 -noout -issuer

echo -e "\n=== 4. ПРОВЕРКА РЕДИРЕКТОВ ==="
echo "4.1. Тест редиректа /grafana -> /grafana/:"
curl -I https://pishchik-dev.tech/grafana 2>/dev/null | grep -E "HTTP|Location"

echo -e "\n4.2. Тест с максимальным количеством редиректов:"
curl -L --max-redirs 5 -I https://pishchik-dev.tech/grafana 2>/dev/null | head -3

echo -e "\n=== 5. ПРОВЕРКА ЗАГОЛОВКОВ ==="
echo "5.1. Проверка заголовков ответа:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | grep -E "HTTP|Server|Content-Type|Location"

echo -e "\n5.2. Проверка безопасности заголовков:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | grep -E "Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options"

echo -e "\n=== 6. ПРОВЕРКА БРАУЗЕРА (СИМУЛЯЦИЯ) ==="
echo "6.1. Тест с User-Agent браузера:"
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3

echo -e "\n6.2. Тест с Accept заголовками:"
curl -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3

echo -e "\n=== 7. ПРОВЕРКА СТАТУСА КОНТЕЙНЕРОВ ==="
echo "7.1. Статус Grafana:"
docker ps | grep grafana

echo -e "\n7.2. Статус Nginx:"
docker ps | grep nginx

echo -e "\n7.3. Логи Grafana (последние 5 строк):"
docker logs grafana --tail 5

echo -e "\n7.4. Логи Nginx (последние 5 строк):"
docker logs nginx --tail 5

echo -e "\n=========================================="
echo "ТЕСТ ЗАВЕРШЕН"
echo "=========================================="
