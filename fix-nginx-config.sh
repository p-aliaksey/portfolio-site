#!/bin/bash

echo "=========================================="
echo "ИСПРАВЛЕНИЕ КОНФИГУРАЦИИ NGINX"
echo "=========================================="

echo "=== 1. ОСТАНОВКА NGINX ==="
echo "Останавливаем Nginx контейнер..."
docker stop nginx

echo -e "\n=== 2. КОПИРОВАНИЕ НОВОЙ КОНФИГУРАЦИИ ==="
echo "Копируем обновленную конфигурацию Nginx..."

# Создаем временный файл с новой конфигурацией
cat > /tmp/nginx.conf << 'EOF'
server {
    listen 443 ssl;
    server_name pishchik-dev.tech;

    ssl_certificate /etc/letsencrypt/live/pishchik-dev.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pishchik-dev.tech/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://app:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    # Redirect /grafana to /grafana/ for consistency
    location = /grafana {
        return 301 /grafana/;
    }

    location /grafana/ {
        proxy_pass http://grafana:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 300s;
        proxy_redirect off;
        proxy_buffering off;
    }

    # Redirect /prometheus to /prometheus/ for consistency
    location = /prometheus {
        return 301 /prometheus/;
    }

    location /prometheus/ {
        proxy_pass http://prometheus:9090/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 300s;
        proxy_redirect off;
        proxy_buffering off;
    }

    # Redirect /loki to /loki/ for consistency
    location = /loki {
        return 301 /loki/;
    }

    location /loki/ {
        proxy_pass http://loki:3100/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 300s;
        proxy_redirect off;
        proxy_buffering off;
    }
}
EOF

# Копируем конфигурацию в контейнер
docker cp /tmp/nginx.conf nginx:/etc/nginx/conf.d/default.conf

echo -e "\n=== 3. ПРОВЕРКА СИНТАКСИСА ==="
echo "Проверяем синтаксис Nginx..."
docker exec nginx nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Синтаксис Nginx корректен"
else
    echo "❌ Ошибка в синтаксисе Nginx"
    exit 1
fi

echo -e "\n=== 4. ЗАПУСК NGINX ==="
echo "Запускаем Nginx с новой конфигурацией..."
docker start nginx

echo -e "\n=== 5. ОЖИДАНИЕ ЗАПУСКА ==="
echo "Ждем 10 секунд для полного запуска..."
sleep 10

echo -e "\n=== 6. ТЕСТИРОВАНИЕ ==="
echo "6.1. Тест Grafana:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3

echo -e "\n6.2. Тест Prometheus:"
curl -I https://pishchik-dev.tech/prometheus/ 2>/dev/null | head -3

echo -e "\n6.3. Тест Loki:"
curl -I https://pishchik-dev.tech/loki/ 2>/dev/null | head -3

echo -e "\n=== 7. ПРОВЕРКА СТАТУСА ==="
echo "Статус контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== 8. ОЧИСТКА ==="
rm -f /tmp/nginx.conf

echo -e "\n=========================================="
echo "ИСПРАВЛЕНИЕ ЗАВЕРШЕНО"
echo "=========================================="
echo "Теперь попробуйте открыть:"
echo "- https://pishchik-dev.tech/grafana/"
echo "- https://pishchik-dev.tech/prometheus/"
echo "- https://pishchik-dev.tech/loki/"
