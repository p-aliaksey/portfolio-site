#!/bin/bash

echo " ДОБАВЛЕНИЕ ДАШБОРДОВ ЧЕРЕЗ CURL - $(date)"
echo "================================================"

# Переменные
GRAFANA_URL="https://pishchik-dev.tech/grafana"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
LOKI_URL="http://loki:3100"

# 1. Получение API ключа
echo "1. ПОЛУЧЕНИЕ API КЛЮЧА:"
echo "----------------------------------------"
API_KEY=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"dashboard-import","role":"Admin"}' \
  "$GRAFANA_URL/api/auth/keys" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" | \
  grep -o '"key":"[^"]*"' | cut -d'"' -f4)

if [ -n "$API_KEY" ]; then
    echo " API ключ получен"
else
    echo " Не удалось получить API ключ"
    exit 1
fi
echo ""

# 2. Добавление Loki datasource
echo "2. ДОБАВЛЕНИЕ LOKI DATASOURCE:"
echo "----------------------------------------"
curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Loki",
    "type": "loki",
    "url": "'$LOKI_URL'",
    "access": "proxy",
    "isDefault": false,
    "jsonData": {
      "maxLines": 1000
    }
  }' \
  "$GRAFANA_URL/api/datasources" | grep -q '"id"' && echo " Loki datasource добавлен" || echo "⚠️  Loki datasource уже существует"
echo ""

# 3. Получение UID Loki datasource
echo "3. ПОЛУЧЕНИЕ UID LOKI DATASOURCE:"
echo "----------------------------------------"
LOKI_DS_UID=$(curl -s -H "Authorization: Bearer $API_KEY" \
  "$GRAFANA_URL/api/datasources" | \
  grep -o '"uid":"[^"]*","name":"Loki"' | \
  grep -o '"uid":"[^"]*"' | cut -d'"' -f4)

if [ -n "$LOKI_DS_UID" ]; then
    echo " Loki UID: $LOKI_DS_UID"
else
    echo " Не удалось получить UID Loki datasource"
    exit 1
fi
echo ""

# 4. Импорт Loki Logs Dashboard
echo "4. ИМПОРТ LOKI LOGS DASHBOARD:"
echo "----------------------------------------"
curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(cat infra/monitoring/grafana/dashboards/loki-logs-dashboard.json | sed "s/\"uid\": \"loki\"/\"uid\": \"$LOKI_DS_UID\"/g")" \
  "$GRAFANA_URL/api/dashboards/db" | grep -q '"id"' && echo " Loki Logs Dashboard импортирован" || echo "❌ Ошибка импорта Loki Logs Dashboard"
echo ""

# 5. Импорт Loki Metrics Dashboard
echo "5. ИМПОРТ LOKI METRICS DASHBOARD:"
echo "----------------------------------------"
curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(cat infra/monitoring/grafana/dashboards/loki-metrics-dashboard.json | sed "s/\"uid\": \"loki\"/\"uid\": \"$LOKI_DS_UID\"/g")" \
  "$GRAFANA_URL/api/dashboards/db" | grep -q '"id"' && echo " Loki Metrics Dashboard импортирован" || echo "❌ Ошибка импорта Loki Metrics Dashboard"
echo ""

# 6. Импорт Promtail Dashboard
echo "6. ИМПОРТ PROMTAIL DASHBOARD:"
echo "----------------------------------------"
curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(cat infra/monitoring/grafana/dashboards/promtail-dashboard.json | sed "s/\"uid\": \"loki\"/\"uid\": \"$LOKI_DS_UID\"/g")" \
  "$GRAFANA_URL/api/dashboards/db" | grep -q '"id"' && echo " Promtail Dashboard импортирован" || echo "❌ Ошибка импорта Promtail Dashboard"
echo ""

# 7. Удаление API ключа
echo "7. УДАЛЕНИЕ API КЛЮЧА:"
echo "----------------------------------------"
KEY_ID=$(curl -s -H "Authorization: Bearer $API_KEY" \
  "$GRAFANA_URL/api/auth/keys" | \
  grep -o '"id":[0-9]*,"name":"dashboard-import"' | \
  grep -o '"id":[0-9]*' | cut -d':' -f2)

if [ -n "$KEY_ID" ]; then
    curl -s -X DELETE \
      -H "Authorization: Bearer $API_KEY" \
      "$GRAFANA_URL/api/auth/keys/$KEY_ID" > /dev/null
    echo " API ключ удален"
else
    echo "  API ключ не найден для удаления"
fi
echo ""

# 8. Итоговый статус
echo "8. ИТОГОВЫЙ СТАТУС:"
echo "================================================"
echo "Grafana URL: $GRAFANA_URL"
echo "Loki datasource UID: $LOKI_DS_UID"
echo ""

echo " Добавление дашбордов завершено - $(date)"
echo ""
echo " ПРОВЕРКА:"
echo "1. Откройте $GRAFANA_URL"
echo "2. Перейдите в раздел 'Dashboards'"
echo "3. Найдите дашборды:"
echo "   - Loki Logs Dashboard"
echo "   - Loki Metrics Dashboard"
echo "   - Promtail Monitoring Dashboard"
