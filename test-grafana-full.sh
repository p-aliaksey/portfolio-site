#!/bin/bash

echo "=========================================="
echo "ПОЛНАЯ ДИАГНОСТИКА GRAFANA HTTPS"
echo "=========================================="

echo "=== 1. СТАТУС КОНТЕЙНЕРОВ ==="
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== 2. GRAFANA ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ ==="
docker exec grafana env | grep GF_

echo -e "\n=== 3. GRAFANA КОНФИГУРАЦИЯ ==="
echo "3.1. Проверка grafana.ini:"
docker exec grafana cat /etc/grafana/grafana.ini 2>/dev/null || echo "Файл grafana.ini не найден"

echo -e "\n3.2. Проверка переменных в конфиге:"
docker exec grafana grep -E "root_url|serve_from_sub_path|domain" /etc/grafana/grafana.ini 2>/dev/null || echo "Настройки не найдены"

echo -e "\n=== 4. GRAFANA ЛОГИ ==="
echo "4.1. Последние 20 строк логов:"
docker logs grafana --tail 20

echo -e "\n4.2. Поиск ошибок в логах:"
docker logs grafana 2>&1 | grep -i "error\|warn\|fail" | tail -10 || echo "Ошибок не найдено"

echo -e "\n=== 5. NGINX КОНФИГУРАЦИЯ ==="
echo "5.1. Текущая конфигурация Nginx:"
docker exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 15 -B 5 "location /grafana"

echo -e "\n5.2. Проверка синтаксиса Nginx:"
docker exec nginx nginx -t

echo -e "\n5.3. Логи Nginx (последние 10 строк):"
docker logs nginx --tail 10

echo -e "\n=== 6. ТЕСТЫ ДОСТУПНОСТИ ==="
echo "6.1. HTTP тест (прямой доступ к контейнеру):"
curl -I http://localhost:3001 2>/dev/null | head -5 || echo "HTTP недоступен"

echo -e "\n6.2. HTTPS тест (через Nginx):"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -5 || echo "HTTPS недоступен"

echo -e "\n6.3. Тест с подробными заголовками:"
curl -v https://pishchik-dev.tech/grafana/ 2>&1 | head -20

echo -e "\n6.4. Тест API health:"
curl -s https://pishchik-dev.tech/grafana/api/health 2>/dev/null || echo "API недоступен"

echo -e "\n6.5. Тест главной страницы:"
curl -s https://pishchik-dev.tech/grafana/ 2>/dev/null | head -10 || echo "Главная страница недоступна"

echo -e "\n=== 7. ПРОВЕРКА РЕДИРЕКТОВ ==="
echo "7.1. Тест редиректа с /grafana на /grafana/:"
curl -I https://pishchik-dev.tech/grafana 2>/dev/null | head -5

echo -e "\n7.2. Тест с максимальным количеством редиректов:"
curl -L --max-redirs 5 https://pishchik-dev.tech/grafana/ 2>/dev/null | head -10

echo -e "\n7.3. Тест с отключенными редиректами:"
curl -L --max-redirs 0 https://pishchik-dev.tech/grafana/ 2>/dev/null | head -5

echo -e "\n=== 8. ПРОВЕРКА СЕТИ И DNS ==="
echo "8.1. DNS резолюция:"
nslookup pishchik-dev.tech

echo -e "\n8.2. Проверка портов:"
ss -tlnp | grep -E ":(80|443|3001)" || echo "Порты не найдены"

echo -e "\n8.3. Проверка SSL сертификата:"
echo | openssl s_client -servername pishchik-dev.tech -connect pishchik-dev.tech:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "SSL недоступен"

echo -e "\n=== 9. ПРОВЕРКА ФАЙЛОВ КОНФИГУРАЦИИ ==="
echo "9.1. Проверка docker-compose.yml на сервере:"
docker exec grafana cat /opt/devops-portfolio/docker-compose.yml | grep -A 20 -B 5 grafana 2>/dev/null || echo "Файл не найден"

echo -e "\n9.2. Проверка монтирования volumes:"
docker inspect grafana | grep -A 10 -B 5 Mounts

echo -e "\n=== 10. ТЕСТЫ БРАУЗЕРА (СИМУЛЯЦИЯ) ==="
echo "10.1. Тест с User-Agent браузера:"
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" https://pishchik-dev.tech/grafana/ 2>/dev/null | head -10

echo -e "\n10.2. Тест с Accept заголовками:"
curl -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" https://pishchik-dev.tech/grafana/ 2>/dev/null | head -10

echo -e "\n10.3. Тест с Cookie:"
curl -H "Cookie: grafana_sess=test" https://pishchik-dev.tech/grafana/ 2>/dev/null | head -10

echo -e "\n=== 11. ПРОВЕРКА GRAFANA ВНУТРИ КОНТЕЙНЕРА ==="
echo "11.1. Проверка процессов:"
docker exec grafana ps aux | grep grafana

echo -e "\n11.2. Проверка сетевых соединений:"
docker exec grafana netstat -tlnp 2>/dev/null || echo "netstat недоступен"

echo -e "\n11.3. Проверка файлов конфигурации:"
docker exec grafana ls -la /etc/grafana/

echo -e "\n11.4. Проверка логов внутри контейнера:"
docker exec grafana tail -10 /var/log/grafana/grafana.log 2>/dev/null || echo "Лог файл не найден"

echo -e "\n=== 12. ДЕТАЛЬНЫЙ АНАЛИЗ ОТВЕТОВ ==="
echo "12.1. Полный HTTP ответ:"
curl -v https://pishchik-dev.tech/grafana/ 2>&1 | grep -E "HTTP|Location|Set-Cookie|Server"

echo -e "\n12.2. Проверка заголовков ответа:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null

echo -e "\n12.3. Проверка содержимого ответа:"
curl -s https://pishchik-dev.tech/grafana/ 2>/dev/null

echo -e "\n=========================================="
echo "ДИАГНОСТИКА ЗАВЕРШЕНА"
echo "=========================================="

echo -e "\n=== РЕКОМЕНДАЦИИ ==="
echo "1. Если видите 301 редирект - проблема в конфигурации Grafana"
echo "2. Если видите 404 - проблема в Nginx прокси"
echo "3. Если видите ERR_TOO_MANY_REDIRECTS - проблема в настройках подпути"
echo "4. Если API работает, но UI нет - проблема в статических ресурсах"
