# 🚀 DevOps Portfolio - Развертывание

Простое и быстрое развертывание современного DevOps проекта с Docker контейнерами.

## ⚡ Быстрый старт

### 1. 🏗️ Создание инфраструктуры (Terraform)
```bash
# Настройка переменных Yandex Cloud
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars

# Создание VM в Yandex Cloud
terraform init
terraform plan
terraform apply

# Получение IP адреса
terraform output public_ip
```

### 2. ⚙️ Настройка Ansible
```bash
# Установка Ansible (на локальной машине)
pip install ansible

# Клонирование репозитория
git clone <your-repo>
cd devops-portfolio

# Настройка инвентаря
cd infra/ansible
# Замените YOUR_VM_IP на полученный IP
sed -i 's/YOUR_VM_IP/ваш_ip_адрес/' inventory.ini
```

### 3. 🚀 Автоматический деплой
```bash
# Полное развертывание (рекомендуется)
ansible-playbook -i inventory.ini site.yml

# Или поэтапно:
ansible-playbook -i inventory.ini install_docker.yml  # Установка Docker
ansible-playbook -i inventory.ini deploy.yml         # Деплой приложения
```

## 📁 Структура проекта

```
devops-portfolio/
├── docker-compose.yml              # 🐳 Docker Compose (6 контейнеров)
├── infra/
│   ├── terraform/                  # ☁️ Yandex Cloud конфигурация
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   ├── ansible/                    # ⚙️ Ansible playbooks
│   │   ├── inventory.ini
│   │   ├── site.yml
│   │   └── group_vars/all.yml
│   ├── nginx/                      # 🌐 Nginx конфигурации
│   │   ├── nginx.conf              # HTTPS (443)
│   │   └── nginx-http.conf         # HTTP (80)
│   ├── monitoring/                 # 📊 Prometheus + Grafana
│   │   ├── prometheus/
│   │   └── grafana/
│   ├── logging/                    # 📝 Loki + Promtail
│   │   ├── loki/
│   │   └── promtail/
│   └── backup/                     # 💾 Скрипты бэкапов
└── app/                            # 🚀 Flask приложение
    ├── templates/                  # HTML шаблоны
    ├── static/                     # CSS, JS, изображения
    └── translations/               # 🇷🇺🇺🇸 Переводы
```

## 🌐 Доступные сервисы

После развертывания будут доступны:

- **🏠 Главная страница**: `https://your-domain.com/`
- **📊 Мониторинг**: `https://your-domain.com/monitoring`
- **🏗️ Архитектура**: `https://your-domain.com/architecture`
- **📈 Grafana**: `https://your-domain.com/grafana/`
- **📊 Prometheus**: `https://your-domain.com/prometheus/`
- **📝 Loki**: `https://your-domain.com/loki/`

## 🔧 Управление контейнерами

```bash
# На сервере
cd /opt/devops-portfolio

# Запуск всех контейнеров
docker compose up -d

# Остановка всех контейнеров
docker compose down

# Перезапуск всех контейнеров
docker compose restart

# Перезапуск конкретного контейнера
docker compose restart nginx
docker compose restart app
docker compose restart grafana

# Просмотр логов
docker compose logs -f
docker compose logs -f nginx
docker compose logs -f app
```

## 🛠️ Тестирование развертывания

```bash
# Проверка статуса всех контейнеров
docker ps

# Проверка доступности сервисов
curl -I https://your-domain.com/
curl -I https://your-domain.com/grafana/
curl -I https://your-domain.com/prometheus/
curl -I https://your-domain.com/loki/

# Проверка логов на ошибки
docker compose logs | grep -i error
```

## 📝 Просмотр логов

```bash
# Все сервисы
docker compose logs

# Конкретные сервисы
docker compose logs nginx      # Веб-сервер
docker compose logs app        # Flask приложение
docker compose logs grafana    # Дашборды
docker compose logs prometheus # Метрики
docker compose logs loki       # Логи
docker compose logs promtail   # Сбор логов

# Логи в реальном времени
docker compose logs -f nginx
```
