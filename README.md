# 🚀 DevOps Portfolio

Современный DevOps проект с автоматизацией, мониторингом и многоязычной поддержкой. Продуманная и логичная архитектура на базе Docker контейнеров.

## 📋 Содержание

- [Архитектура](#-архитектура)
- [Быстрый старт](#-быстрый-старт)
- [Развертывание](#-развертывание)
- [Мониторинг](#-мониторинг)
- [Бэкапы](#-бэкапы)
- [Разработка](#-разработка)
- [Устранение неполадок](#-устранение-неполадок)


## 🏗️ Архитектура

### 🎯 Схема системы

```
👤 Пользователь
    ↓ HTTPS
🌐 Nginx (Port 80/443)
    ↓ Routes
🚀 Flask App (Port 8000)
    ↓
🐳 Docker Containers:
    ├── 📊 Prometheus (Port 9090)
    ├── 📈 Grafana (Port 3001) 
    ├── 📝 Loki (Port 3100)
    └── 📋 Promtail
```

### 🔄 Поток данных

1. **Пользователь** → **Nginx** (HTTPS) → **Flask App**
2. **Prometheus** собирает метрики со всех контейнеров
3. **Grafana** показывает дашборды (метрики + логи)
4. **Promtail** собирает логи → **Loki**
5. **GitHub Actions** → **Ansible** → **Docker Compose**

### 🐙 Ключевые компоненты

- **🐙 GitHub**: Исходный код + CI/CD
- **☁️ Yandex Cloud VM**: Ubuntu 24.04 LTS (2 CPU, 2GB RAM)
- **🐳 Docker**: 6 контейнеров в одной сети
- **🔧 Ansible**: Автоматическая настройка
- **📦 GHCR**: Container Registry

## 🚀 Быстрый старт

### 🏠 Локальная разработка

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/p-aliaksey/portfolio-site.git
   cd portfolio-site
   ```

2. **Запустите все контейнеры:**
   ```bash
   docker compose up -d
   ```

3. **Откройте в браузере:**
   - **Главная страница**: http://localhost
   - **Мониторинг**: http://localhost/monitoring
   - **Архитектура**: http://localhost/architecture
   - **Grafana**: http://localhost:3001 (admin/admin)
   - **Prometheus**: http://localhost:9090
   - **Loki**: http://localhost:3100

### ☁️ Облачное развертывание

1. **Настройте Terraform** (создание VM в Yandex Cloud)
2. **Запустите Ansible** (настройка и деплой)
3. **Готово!** Сайт доступен по HTTPS

## 🌐 Развертывание

### 🏗️ 1. Создание инфраструктуры (Terraform)

1. **Настройте переменные:**
   ```bash
   cd infra/terraform
   cp terraform.tfvars.example terraform.tfvars
   # Отредактируйте terraform.tfvars с вашими данными Yandex Cloud
   ```

2. **Создайте VM в Yandex Cloud:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Получите IP адрес:**
   ```bash
   terraform output public_ip
   ```

### ⚙️ 2. Настройка Ansible

1. **Установите Ansible (на локальной машине):**
   ```bash
   pip install ansible
   ```

2. **Обновите inventory:**
   ```bash
   cd infra/ansible
   # Замените YOUR_VM_IP на полученный IP
   sed -i 's/YOUR_VM_IP/ваш_ip_адрес/' inventory.ini
   ```

3. **Настройте переменные (опционально):**
   ```bash
   vim group_vars/all.yml
   ```

### 🚀 3. Автоматический деплой

1. **Запустите полное развертывание:**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

2. **Или поэтапно:**
   ```bash
   ansible-playbook -i inventory.ini install_docker.yml  # Установка Docker
   ansible-playbook -i inventory.ini deploy.yml         # Деплой приложения
   ```

3. **Проверьте результат:**
   ```bash
   # Откройте в браузере ваш IP адрес
   curl -I http://ваш_ip_адрес
   ```

### 🔐 4. Настройка HTTPS (рекомендуется)

1. **Включите HTTPS:**
   ```yaml
   # group_vars/all.yml
   enable_https: true
   domain_name: your-domain.com
   letsencrypt_email: your-email@example.com
   ```

2. **Перезапустите деплой:**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

## 📊 Мониторинг

### 🌐 Доступные сервисы

- **Главная страница**: https://your-domain.com
- **Мониторинг**: https://your-domain.com/monitoring
- **Архитектура**: https://your-domain.com/architecture
- **Grafana**: https://your-domain.com/grafana/
- **Prometheus**: https://your-domain.com/prometheus/
- **Loki**: https://your-domain.com/loki/

### 📈 Grafana Дашборды

Автоматически создаются дашборды:
- **System Overview**: Общий обзор системы
- **Docker Containers**: Статус всех контейнеров
- **Application Metrics**: Метрики Flask приложения
- **Loki Logs**: Просмотр логов в реальном времени

### 📝 Логирование

- **Loki**: Централизованное хранение логов
- **Promtail**: Автоматический сбор логов со всех контейнеров
- **Grafana**: Просмотр и анализ логов через веб-интерфейс

## 💾 Бэкапы

### 🔄 Автоматические бэкапы

1. **Настройка (выполняется автоматически при деплое):**
   ```bash
   sudo /opt/devops-portfolio/infra/backup/setup-cron.sh
   ```

2. **Ручное создание бэкапа:**
   ```bash
   /opt/devops-portfolio/infra/backup/backup.sh
   ```

3. **Восстановление из бэкапа:**
   ```bash
   /opt/devops-portfolio/infra/backup/restore.sh /opt/backups/backup-file.tar.gz
   ```

### 📦 Что включают бэкапы

- ✅ **Конфигурации**: Docker, Nginx, Prometheus, Grafana, Loki
- ✅ **Исходный код**: Flask приложение
- ✅ **Данные Grafana**: Дашборды и настройки
- ✅ **Данные Loki**: Все логи
- ✅ **Конфигурации Ansible**: Playbooks

### ⏰ Политика хранения

- **Расписание**: Ежедневно в 2:00
- **Хранение**: 7 дней
- **Проверка**: Автоматическая проверка целостности
- **Тестирование**: Автоматический тест восстановления


## 🛠️ Разработка

### 📁 Структура проекта

```
devops-portfolio/
├── app/                          # 🚀 Flask приложение
│   ├── templates/                # HTML шаблоны с переводами
│   ├── static/                   # CSS, JS, изображения
│   ├── translations/             # 🇷🇺🇺🇸 Файлы переводов
│   └── app.py                    # Основное приложение
├── infra/                        # 🏗️ Инфраструктура
│   ├── terraform/                # ☁️ Yandex Cloud конфигурация
│   ├── ansible/                  # ⚙️ Ansible playbooks
│   ├── monitoring/               # 📊 Prometheus + Grafana
│   ├── logging/                  # 📝 Loki + Promtail
│   ├── nginx/                    # 🌐 Nginx конфигурации
│   └── backup/                   # 💾 Скрипты бэкапов
├── docker-compose.yml            # 🐳 Docker Compose
├── Dockerfile                    # 🐳 Docker образ
└── README.md                     # 📖 Документация
```



### 🚀 CI/CD Pipeline

Автоматический деплой через GitHub Actions:

1. **Push в main** → GitHub Actions запускается
2. **Сборка образа** → Docker образ публикуется в GHCR
3. **Создание инфраструктуры** → Terraform настраивает Yandex Cloud
4. **Настройка VM** → Ansible конфигурирует сервер
5. **Запуск контейнеров** → Docker Compose разворачивает все сервисы

### 🔧 Управление контейнерами

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

## 🔧 Устранение неполадок

### 🐳 Проблемы с контейнерами

```bash
# Проверьте статус всех контейнеров
docker ps -a

# Просмотрите логи конкретного контейнера
docker logs nginx
docker logs app
docker logs grafana
docker logs prometheus
docker logs loki
docker logs promtail

# Перезапустите все сервисы
docker compose restart

# Перезапустите конкретный сервис
docker compose restart nginx
```

### 📊 Проблемы с мониторингом

```bash
# Проверьте доступность Prometheus
curl http://localhost:9090/api/v1/query?query=up

# Проверьте доступность Grafana
curl http://localhost:3001/api/health

# Проверьте доступность Loki
curl http://localhost:3100/ready

# Просмотрите логи мониторинга
docker logs prometheus
docker logs grafana
docker logs loki
```

### 💾 Проблемы с бэкапами

```bash
# Проверьте логи бэкапов
tail -f /var/log/backup.log

# Проверьте cron задачи
crontab -l

# Запустите бэкап вручную
/opt/devops-portfolio/infra/backup/backup.sh

# Проверьте статус бэкапов
/opt/devops-portfolio/infra/backup/backup-status.sh
```

### 🛠️ Тестирование развертывания

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

##  Контакты

- **Issues**: GitHub Issues
- **Email**: pishchik.aliaksey@gmail.com

---

**© 2025 DevOps Portfolio - Современный DevOps проект с Docker, мониторингом и автоматизацией** 🚀