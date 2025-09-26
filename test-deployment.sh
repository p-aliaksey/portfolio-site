#!/bin/bash

# Скрипт для тестирования развертывания DevOps Portfolio
# Использование: ./test-deployment.sh <VM_IP>

set -e

VM_IP=${1:-"51.250.90.201"}
DOMAIN="pishchik-dev.tech"

echo "🚀 Тестирование развертывания DevOps Portfolio на $VM_IP"

# Проверка доступности VM
echo "📡 Проверка доступности VM..."
if ! ping -c 3 $VM_IP > /dev/null 2>&1; then
    echo "❌ VM $VM_IP недоступна"
    exit 1
fi
echo "✅ VM доступна"

# Проверка SSH подключения
echo "🔐 Проверка SSH подключения..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$VM_IP "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "❌ SSH подключение не удалось"
    exit 1
fi
echo "✅ SSH подключение работает"

# Запуск Ansible playbook
echo "🔧 Запуск Ansible playbook..."
cd infra/ansible
ansible-playbook -i inventory.ini site.yml -v

# Проверка статуса контейнеров
echo "🐳 Проверка статуса контейнеров..."
ssh ubuntu@$VM_IP "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Тестирование HTTP endpoints
echo "🌐 Тестирование HTTP endpoints..."

# Функция для тестирования endpoint
test_endpoint() {
    local name=$1
    local url=$2
    echo "Тестирование $name..."
    if curl -s -f "$url" > /dev/null; then
        echo "✅ $name работает"
    else
        echo "❌ $name не работает"
        echo "Ответ: $(curl -s -I "$url" | head -1)"
    fi
}

# Тестируем все endpoints
test_endpoint "Главная страница" "http://$DOMAIN/"
test_endpoint "Prometheus" "http://$DOMAIN/prometheus/"
test_endpoint "Grafana" "http://$DOMAIN/grafana/"
test_endpoint "Loki" "http://$DOMAIN/loki/"

echo "🎉 Тестирование завершено!"
echo "🌐 Откройте в браузере: http://$DOMAIN"