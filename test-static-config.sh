#!/bin/bash

echo " ТЕСТ СТАТИЧЕСКОЙ КОНФИГУРАЦИИ - $(date)"
echo "================================================"

# 1. Перезапуск Promtail
echo "1. ПЕРЕЗАПУСК PROMTAIL:"
echo "----------------------------------------"
docker restart promtail
echo " Promtail перезапущен"
sleep 15
echo ""

# 2. Проверка логов Promtail
echo "2. ЛОГИ PROMTAIL (последние 10):"
echo "----------------------------------------"
docker logs promtail --tail 10
echo ""

# 3. Проверка ошибок
echo "3. СТАТИСТИКА ОШИБОК:"
echo "----------------------------------------"
ERROR_COUNT=$(docker logs promtail --since 2m 2>&1 | grep -c "status=400" 2>/dev/null || echo "0")
echo "Ошибки 400 за последние 2 минуты: $ERROR_COUNT"
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo " Ошибок нет! Promtail работает корректно"
else
    echo " Все еще есть ошибки"
fi
echo ""

# 4. Тест API Loki
echo "4. ТЕСТ API LOKI:"
echo "----------------------------------------"
echo "Loki ready: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Loki labels: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/loki/api/v1/labels 2>/dev/null)"
echo ""

# 5. Проверка меток
echo "5. МЕТКИ В LOKI:"
echo "----------------------------------------"
echo "Доступные метки:"
curl -s http://localhost:3100/loki/api/v1/labels 2>/dev/null | grep -o '"data":\[[^]]*\]' || echo "Ошибка получения меток"
echo ""

# 6. Итоговый статус
echo "6. ИТОГОВЫЙ СТАТУС:"
echo "================================================"
echo "Loki API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Loki через nginx: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/loki/ready 2>/dev/null)"
echo "Promtail ошибки: $ERROR_COUNT"
echo ""

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo " УСПЕХ! Loki и Promtail работают корректно!"
    echo "Теперь можно проверить дашборды в Grafana"
else
    echo "  Проблема все еще существует"
fi

echo " Тест завершен - $(date)"
