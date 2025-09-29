#!/bin/bash

echo "=========================================="
echo "БЫСТРОЕ ИСПРАВЛЕНИЕ NGINX"
echo "=========================================="

echo "1. Останавливаем nginx..."
docker stop nginx 2>/dev/null || true

echo "2. Удаляем nginx контейнер..."
docker rm nginx 2>/dev/null || true

echo "3. Запускаем nginx с исправленной конфигурацией..."
docker compose up -d nginx

echo "4. Ждем 10 секунд..."
sleep 10

echo "5. Проверяем статус nginx..."
if docker ps | grep nginx; then
    echo "✓ Nginx запущен"
    
    echo "6. Тестируем сервисы..."
    echo -n "Главная: "
    curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/ && echo "✓" || echo "✗"
    
    echo -n "Grafana: "
    curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/grafana/ && echo "✓" || echo "✗"
    
    echo -n "Prometheus: "
    curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/prometheus/ && echo "✓" || echo "✗"
    
    echo -n "Loki: "
    curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/loki/ && echo "✓" || echo "✗"
else
    echo "✗ Nginx не запустился"
    echo "Логи nginx:"
    docker logs nginx --tail 5
fi

echo "=========================================="
echo "ИСПРАВЛЕНИЕ ЗАВЕРШЕНО"
echo "=========================================="
