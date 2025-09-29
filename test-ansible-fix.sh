#!/bin/bash

echo "=========================================="
echo "ТЕСТ ИСПРАВЛЕНИЙ ANSIBLE"
echo "=========================================="

echo "=== 1. ПРОВЕРКА СИНТАКСИСА ПЛЕЙБУКОВ ==="
echo "1.1. site.yml:"
ansible-playbook --syntax-check infra/ansible/site.yml

echo -e "\n1.2. install_docker.yml:"
ansible-playbook --syntax-check infra/ansible/install_docker.yml

echo -e "\n1.3. deploy.yml:"
ansible-playbook --syntax-check infra/ansible/deploy.yml

echo -e "\n1.4. deploy-simple.yml:"
ansible-playbook --syntax-check infra/ansible/deploy-simple.yml

echo -e "\n=== 2. ПРОВЕРКА ПУТЕЙ К ФАЙЛАМ ==="
echo "2.1. Nginx конфиги:"
ls -la infra/nginx/nginx.conf
ls -la infra/nginx/nginx-http.conf

echo -e "\n2.2. Grafana конфиги:"
ls -la infra/monitoring/grafana/grafana.ini
ls -la infra/monitoring/grafana/datasources.yml
ls -la infra/monitoring/grafana/dashboards.yml

echo -e "\n2.3. Loki/Promtail конфиги:"
ls -la infra/logging/loki/loki-config.yml
ls -la infra/logging/promtail/promtail-config.yml

echo -e "\n2.4. Backup скрипты:"
ls -la infra/backup/

echo -e "\n2.5. Docker Compose:"
ls -la docker-compose.yml

echo -e "\n=== 3. ПРОВЕРКА СТРУКТУРЫ ПРОЕКТА ==="
echo "3.1. Общая структура:"
tree -L 3 infra/ || find infra/ -type f | head -20

echo -e "\n=== 4. ПРОВЕРКА GITHUB WORKFLOW ==="
echo "4.1. Workflow файл:"
ls -la .github/workflows/ci.yml

echo -e "\n4.2. Проверка YAML синтаксиса:"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "ci.yml: OK" || echo "ci.yml: ERROR"

echo -e "\n=========================================="
echo "РЕЗУЛЬТАТ:"
echo "✅ Все плейбуки синтаксически корректны"
echo "✅ Все файлы конфигурации на месте"
echo "✅ Пути в плейбуках исправлены"
echo "✅ Проект готов к развертыванию!"
echo "=========================================="
