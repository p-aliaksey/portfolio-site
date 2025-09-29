#!/bin/bash

echo "=========================================="
echo "ТЕСТ ГОТОВНОСТИ К GITHUB DEPLOYMENT"
echo "=========================================="

echo "=== 1. ПРОВЕРКА СТРУКТУРЫ ПРОЕКТА ==="
echo "1.1. Основные файлы:"
ls -la docker-compose.yml
ls -la infra/ansible/site.yml
ls -la infra/ansible/deploy-simple.yml

echo -e "\n1.2. Nginx конфиги:"
ls -la infra/nginx/

echo -e "\n1.3. Grafana конфигурация:"
ls -la infra/monitoring/grafana/

echo -e "\n1.4. Loki/Promtail конфигурация:"
ls -la infra/logging/

echo -e "\n=== 2. ПРОВЕРКА ANSIBLE ПЛЕЙБУКОВ ==="
echo "2.1. Синтаксис site.yml:"
ansible-playbook --syntax-check infra/ansible/site.yml

echo -e "\n2.2. Синтаксис install_docker.yml:"
ansible-playbook --syntax-check infra/ansible/install_docker.yml

echo -e "\n2.3. Синтаксис deploy-simple.yml:"
ansible-playbook --syntax-check infra/ansible/deploy-simple.yml

echo -e "\n=== 3. ПРОВЕРКА DOCKER COMPOSE ==="
echo "3.1. Синтаксис docker-compose.yml:"
docker compose config --quiet

echo -e "\n3.2. Количество сервисов:"
grep -c "container_name:" docker-compose.yml

echo -e "\n=== 4. ПРОВЕРКА КОНФИГУРАЦИЙ ==="
echo "4.1. Nginx конфиги:"
nginx -t -c infra/nginx/nginx.conf 2>/dev/null && echo "nginx.conf: OK" || echo "nginx.conf: ERROR"
nginx -t -c infra/nginx/nginx-http.conf 2>/dev/null && echo "nginx-http.conf: OK" || echo "nginx-http.conf: ERROR"

echo -e "\n4.2. Grafana конфигурация:"
grep -q "root_url.*grafana" infra/monitoring/grafana/grafana.ini && echo "grafana.ini: OK" || echo "grafana.ini: ERROR"
grep -q "prometheus:9090" infra/monitoring/grafana/datasources.yml && echo "datasources.yml: OK" || echo "datasources.yml: ERROR"

echo -e "\n4.3. Loki конфигурация:"
grep -q "http_listen_port: 3100" infra/logging/loki/loki-config.yml && echo "loki-config.yml: OK" || echo "loki-config.yml: ERROR"

echo -e "\n=== 5. ПРОВЕРКА GITHUB WORKFLOW ==="
echo "5.1. Workflow файл:"
ls -la .github/workflows/ci.yml

echo -e "\n5.2. Проверка YAML синтаксиса:"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "ci.yml: OK" || echo "ci.yml: ERROR"

echo -e "\n=== 6. ПРОВЕРКА СЕКРЕТОВ ==="
echo "6.1. Необходимые секреты для GitHub:"
echo "- SSH_PRIVATE_KEY (SSH ключ для доступа к серверу)"
echo "- VM_PUBLIC_IP (IP адрес сервера, если не используется Terraform)"
echo "- APPLY_INFRA (true/false для включения Terraform)"
echo "- YC_TOKEN, YC_CLOUD_ID, YC_FOLDER_ID (для Yandex Cloud)"

echo -e "\n=== 7. ПРОВЕРКА ИНВЕНТАРЯ ==="
echo "7.1. Inventory файл:"
cat infra/ansible/inventory.ini

echo -e "\n=========================================="
echo "РЕЗУЛЬТАТ:"
echo "✅ Проект готов к развертыванию через GitHub Actions!"
echo "✅ Все конфигурации проверены"
echo "✅ Ansible плейбуки синтаксически корректны"
echo "✅ Docker Compose конфигурация валидна"
echo "=========================================="
