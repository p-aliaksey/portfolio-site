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

# Главная страница
echo "Тестирование главной страницы..."
if curl -s -f "http://$DOMAIN/" > /dev/null; then
    echo "✅ Главная страница работает"
else
    echo "❌ Главная страница не работает"
fi

# Prometheus
echo "Тестирование Prometheus..."
if curl -s -f "http://$DOMAIN/prometheus/" > /dev/null; then
    echo "✅ Prometheus работает"
else
    echo "❌ Prometheus не работает"
    echo "Ответ: $(curl -s -I "http://$DOMAIN/prometheus/" | head -1)"
fi

# Grafana
echo "Тестирование Grafana..."
if curl -s -f "http://$DOMAIN/grafana/" > /dev/null; then
    echo "✅ Grafana работает"
else
    echo "❌ Grafana не работает"
    echo "Ответ: $(curl -s -I "http://$DOMAIN/grafana/" | head -1)"
fi

# Loki
echo "Тестирование Loki..."
if curl -s -f "http://$DOMAIN/loki/" > /dev/null; then
    echo "✅ Loki работает"
else
    echo "❌ Loki не работает"
    echo "Ответ: $(curl -s -I "http://$DOMAIN/loki/" | head -1)"
fi

echo "🎉 Тестирование завершено!"
echo "🌐 Откройте в браузере: http://$DOMAIN"
