# DevOps Portfolio - Развертывание

## 🚀 Быстрый старт

### 1. Подготовка сервера
```bash
# Установка Ansible (на локальной машине)
pip install ansible

# Клонирование репозитория
git clone <your-repo>
cd portfolio-site2
```

### 2. Настройка инвентаря
Отредактируйте `infra/ansible/inventory.ini`:
```ini
[prod]
your-server-ip ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

### 3. Развертывание
```bash
# Полное развертывание
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/site.yml

# Или только установка Docker
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/install_docker.yml

# Или только деплой приложения
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/deploy-simple.yml
```

## 📁 Структура проекта

```
├── docker-compose.yml              # Основной compose файл
├── infra/
│   ├── nginx/
│   │   ├── nginx.conf              # HTTPS конфигурация (443)
│   │   └── nginx-http.conf         # HTTP конфигурация (80)
│   ├── monitoring/
│   │   ├── prometheus/
│   │   │   └── prometheus.yml
│   │   └── grafana/
│   │       ├── grafana.ini
│   │       ├── datasources.yml
│   │       └── dashboards.yml
│   ├── logging/
│   │   ├── loki/
│   │   │   └── loki-config.yml
│   │   └── promtail/
│   │       └── promtail-config.yml
│   └── ansible/
│       ├── inventory.ini
│       ├── site.yml
│       ├── install_docker.yml
│       └── deploy-simple.yml
└── app/                            # Flask приложение
```

## 🌐 Доступные сервисы

После развертывания будут доступны:

- **Главная страница**: `https://your-domain.com/`
- **Grafana**: `https://your-domain.com/grafana/`
- **Prometheus**: `https://your-domain.com/prometheus/`
- **Loki**: `https://your-domain.com/loki/`

## 🔧 Управление

```bash
# На сервере
cd /opt/devops-portfolio

# Запуск
docker compose up -d

# Остановка
docker compose down

# Перезапуск
docker compose restart

# Логи
docker compose logs -f
```

## 🛠️ Тестирование

```bash
# Локальное тестирование
./test-deployment.sh

# Проверка статуса
docker ps
curl -I https://your-domain.com/
curl -I https://your-domain.com/grafana/
```

## 📝 Логи

```bash
# Все сервисы
docker compose logs

# Конкретный сервис
docker compose logs grafana
docker compose logs nginx
docker compose logs app
```
