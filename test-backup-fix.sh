#!/bin/bash

# Скрипт для тестирования исправлений бэкапов
# Запуск: ./test-backup-fix.sh

echo "🔧 Тестирование исправлений бэкапов..."

# 1. Проверяем, что бэкапы есть в /opt/backups
echo "=== 1. Проверка бэкапов в /opt/backups ==="
if [ -d "/opt/backups" ]; then
    echo "✓ Папка /opt/backups существует"
    ls -la /opt/backups/
    echo ""
else
    echo "❌ Папка /opt/backups не найдена"
fi

# 2. Тестируем API статистики
echo "=== 2. Тестирование API статистики ==="
echo "Запрос: GET /api/system/backups"
curl -s http://localhost:8000/api/system/backups | jq '.' 2>/dev/null || curl -s http://localhost:8000/api/system/backups
echo ""

# 3. Тестируем создание бэкапа через API
echo "=== 3. Тестирование создания бэкапа ==="
echo "Запрос: POST /api/system/backups/create"
curl -s -X POST http://localhost:8000/api/system/backups/create | jq '.' 2>/dev/null || curl -s -X POST http://localhost:8000/api/system/backups/create
echo ""

# 4. Проверяем, что бэкап создался
echo "=== 4. Проверка созданного бэкапа ==="
if [ -d "/opt/backups" ]; then
    echo "Бэкапы после создания:"
    ls -la /opt/backups/
    echo ""
fi

# 5. Тестируем API статистики снова
echo "=== 5. Повторная проверка API статистики ==="
echo "Запрос: GET /api/system/backups"
curl -s http://localhost:8000/api/system/backups | jq '.' 2>/dev/null || curl -s http://localhost:8000/api/system/backups
echo ""

echo "✅ Тестирование завершено"
