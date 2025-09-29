#!/bin/bash

echo "=========================================="
echo "ИСПРАВЛЕНИЕ РЕДИРЕКТОВ"
echo "=========================================="

echo "=== 1. ОСТАНОВКА КОНТЕЙНЕРОВ ==="
echo "Останавливаем все контейнеры..."
docker compose down

echo -e "\n=== 2. ОЧИСТКА КЭША DOCKER ==="
echo "Очищаем неиспользуемые образы..."
docker system prune -f

echo -e "\n=== 3. ПЕРЕЗАПУСК СЕРВИСОВ ==="
echo "Запускаем контейнеры заново..."
docker compose up -d

echo -e "\n=== 4. ОЖИДАНИЕ ЗАПУСКА ==="
echo "Ждем 30 секунд для полного запуска..."
sleep 30

echo -e "\n=== 5. ПРОВЕРКА СТАТУСА ==="
echo "Проверяем статус контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== 6. ТЕСТИРОВАНИЕ СЕРВИСОВ ==="
echo "6.1. Тест главной страницы:"
curl -I https://pishchik-dev.tech/ 2>/dev/null | head -3

echo -e "\n6.2. Тест Grafana:"
curl -I https://pishchik-dev.tech/grafana/ 2>/dev/null | head -3

echo -e "\n6.3. Тест Prometheus:"
curl -I https://pishchik-dev.tech/prometheus/ 2>/dev/null | head -3

echo -e "\n6.4. Тест Loki:"
curl -I https://pishchik-dev.tech/loki/ 2>/dev/null | head -3

echo -e "\n=== 7. ПРОВЕРКА ЛОГОВ ==="
echo "7.1. Логи Nginx (последние 10 строк):"
docker logs nginx --tail 10

echo -e "\n7.2. Логи Grafana (последние 5 строк):"
docker logs grafana --tail 5

echo -e "\n=== 8. РЕЗУЛЬТАТ ==="
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
