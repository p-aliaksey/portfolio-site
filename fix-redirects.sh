#!/bin/bash

echo "=========================================="
echo "ТЕСТ UI СЕРВИСОВ"
echo "=========================================="

echo "=== 1. ПРОВЕРКА КОНТЕЙНЕРОВ ==="
echo "Проверяем статус контейнеров..."

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== 2. ПРОВЕРКА КОНФИГУРАЦИИ NGINX ==="
echo "Тестируем конфигурацию nginx..."
if docker exec nginx nginx -t; then
    echo "✓ Конфигурация nginx корректна"
else
    echo "✗ Ошибка в конфигурации nginx"
fi

echo "3.1. Тест главной страницы:"
curl -I https://pishchik-dev.tech/ 2>/dev/null | head -3

echo -e "\n3.2. Тест Grafana:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3

echo -e "\n3.3. Тест Prometheus:"
curl -I https://pishchik-dev.tech/prometheus/ 2>/dev/null | head -3

echo -e "\n3.4. Тест Loki:"
curl -I https://pishchik-dev.tech/loki/ 2>/dev/null | head -3

echo -e "\n=== 4. ПРОВЕРКА ЛОГОВ ==="
echo "4.1. Логи Nginx (последние 10 строк):"
docker logs nginx --tail 10

echo -e "\n4.2. Логи Grafana (последние 5 строк):"
docker logs grafana --tail 5

echo -e "\n=== 5. РЕЗУЛЬТАТ ==="
echo "Если все тесты прошли успешно, сервисы должны быть доступны:"
echo "- Главная страница: https://pishchik-dev.tech/"
echo "- Grafana: https://pishchik-dev.tech/grafana/"
echo "- Prometheus: https://pishchik-dev.tech/prometheus/"
echo "- Loki: https://pishchik-dev.tech/loki/"

echo -e "\nЕсли проблемы остались, выполните:"
echo "1. Очистите кэш браузера (Ctrl+Shift+Delete)"
echo "2. Попробуйте в инкогнито режиме"
echo "3. Запустите диагностику: ./diagnose-redirects.sh"

echo -e "\n=========================================="
echo "ИСПРАВЛЕНИЕ ЗАВЕРШЕНО"
echo "=========================================="
