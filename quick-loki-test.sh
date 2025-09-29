#!/bin/bash

echo "🔍 БЫСТРЫЙ ТЕСТ LOKI - $(date)"
echo "================================================"

# 1. Перезапуск Promtail
echo "1. ПЕРЕЗАПУСК PROMTAIL:"
echo "----------------------------------------"
docker restart promtail
sleep 5
echo "✅ Promtail перезапущен"
echo ""

# 2. Проверка логов Promtail
echo "2. ЛОГИ PROMTAIL (последние 5):"
echo "----------------------------------------"
docker logs promtail --tail 5
echo ""

# 3. Тест API Loki
echo "3. ТЕСТ API LOKI:"
echo "----------------------------------------"
echo "Loki ready: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Loki labels: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/loki/api/v1/labels 2>/dev/null)"
echo ""

# 4. Проверка меток (без jq)
echo "4. МЕТКИ В LOKI:"
echo "----------------------------------------"
echo "Доступные метки:"
curl -s http://localhost:3100/loki/api/v1/labels 2>/dev/null | grep -o '"data":\[[^]]*\]' || echo "Ошибка получения меток"
echo ""

# 5. Статистика ошибок
echo "5. СТАТИСТИКА ОШИБОК:"
echo "----------------------------------------"
echo "Ошибки 400 за последние 2 минуты: $(docker logs promtail --since 2m 2>&1 | grep -c "status=400" || echo "0")"
echo ""

# 6. Итоговый статус
echo "6. ИТОГОВЫЙ СТАТУС:"
echo "================================================"
echo "Loki API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Loki через nginx: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/loki/ready 2>/dev/null)"
echo "Promtail статус: $(docker ps | grep promtail | awk '{print $7}' || echo "Не запущен")"
echo ""

echo "✅ Быстрый тест завершен - $(date)"
