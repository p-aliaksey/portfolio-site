#!/bin/bash

echo "📊 ТЕСТ ДАШБОРДОВ GRAFANA - $(date)"
echo "================================================"

# 1. Проверка доступности Grafana
echo "1. ПРОВЕРКА GRAFANA:"
echo "----------------------------------------"
echo "Grafana UI: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/grafana 2>/dev/null)"
echo "Grafana API: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/grafana/api/health 2>/dev/null)"
echo ""

# 2. Проверка Loki datasource
echo "2. ПРОВЕРКА LOKI DATASOURCE:"
echo "----------------------------------------"
echo "Loki API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Loki labels: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/loki/api/v1/labels 2>/dev/null)"
echo ""

# 3. Проверка меток в Loki
echo "3. МЕТКИ В LOKI:"
echo "----------------------------------------"
echo "Доступные метки:"
curl -s http://localhost:3100/loki/api/v1/labels 2>/dev/null | grep -o '"data":\[[^]]*\]' || echo "Ошибка получения меток"
echo ""

# 4. Тест запроса логов
echo "4. ТЕСТ ЗАПРОСА ЛОГОВ:"
echo "----------------------------------------"
echo "Запрос логов за последний час:"
curl -s "http://localhost:3100/loki/api/v1/query_range?query={job=\"docker\"}&limit=5&start=$(($(date +%s%N)/1000000 - 3600000))" 2>/dev/null | grep -o '"stream":{[^}]*}' | head -3 || echo "Ошибка запроса логов"
echo ""

# 5. Проверка Promtail
echo "5. ПРОВЕРКА PROMTAIL:"
echo "----------------------------------------"
echo "Promtail статус: $(docker ps | grep promtail | awk '{print $7}' || echo "Не запущен")"
echo "Promtail ошибки за последние 5 минут: $(docker logs promtail --since 5m 2>&1 | grep -c "status=400" 2>/dev/null || echo "0")"
echo ""

# 6. Итоговый статус
echo "6. ИТОГОВЫЙ СТАТУС:"
echo "================================================"
echo "Grafana UI: $(curl -s -o /dev/null -w "%{http_code}" https://pishchik-dev.tech/grafana 2>/dev/null)"
echo "Loki API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready 2>/dev/null)"
echo "Promtail ошибки: $(docker logs promtail --since 5m 2>&1 | grep -c "status=400" 2>/dev/null || echo "0")"
echo ""

echo "✅ Тест дашбордов завершен - $(date)"
echo ""
echo "📋 ИНСТРУКЦИИ:"
echo "1. Откройте https://pishchik-dev.tech/grafana"
echo "2. Перейдите в раздел 'Loki' в левом меню"
echo "3. Найдите дашборды:"
echo "   - Loki Logs Dashboard"
echo "   - Loki Metrics Dashboard" 
echo "   - Promtail Monitoring Dashboard"
echo "4. Проверьте, что логи отображаются корректно"
