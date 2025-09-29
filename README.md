# 🚀 DevOps Portfolio

Современный DevOps проект с автоматизацией, мониторингом и многоязычной поддержкой. Простая и понятная архитектура на базе Docker контейнеров.

## 📋 Содержание

- [Особенности](#-особенности)
- [Архитектура](#-архитектура)
- [Быстрый старт](#-быстрый-старт)
- [Развертывание](#-развертывание)
- [Мониторинг](#-мониторинг)
- [Бэкапы](#-бэкапы)
- [Многоязычность](#-многоязычность)
- [Разработка](#-разработка)

## ✨ Особенности

### 🐳 **Docker Stack**
- **6 контейнеров**: Nginx, Flask App, Prometheus, Grafana, Loki, Promtail
- **Docker Compose**: Простая оркестрация
- **Автоматический деплой**: GitHub Actions + Ansible

### ☁️ **Облачная инфраструктура**
- **Yandex Cloud VM**: Ubuntu 24.04 LTS (2 CPU, 2GB RAM)
- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration Management
- **GitHub Actions**: CI/CD Pipeline

### 📊 **Мониторинг и Логирование**
- **Prometheus**: Сбор метрик со всех контейнеров
- **Grafana**: Красивые дашборды и визуализация
- **Loki**: Централизованное хранение логов
- **Promtail**: Автоматический сбор логов

### 🌍 **Многоязычность**
- **Русский** и **Английский** языки
- Переключатель языков в интерфейсе
- Автоматическое определение языка

### 🔄 **Автоматизация**
- **Автоматические бэкапы** ежедневно в 2:00
- **Cron задачи** для обслуживания
- **Мониторинг состояния** всех сервисов

## 🏗️ Архитектура

### 🎯 Простая схема

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
   git clone https://github.com/your-username/devops-portfolio.git
   cd devops-portfolio
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

1. **Обновите inventory:**
   ```bash
   cd infra/ansible
   # Замените YOUR_VM_IP на полученный IP
   sed -i 's/YOUR_VM_IP/ваш_ip_адрес/' inventory.ini
   ```

2. **Настройте переменные (опционально):**
   ```bash
   vim group_vars/all.yml
   ```

### 🚀 3. Автоматический деплой

1. **Запустите полное развертывание:**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

2. **Проверьте результат:**
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

## 🌍 Многоязычность

### 🌐 Поддерживаемые языки

- **🇷🇺 Русский** (по умолчанию)
- **🇺🇸 Английский**

### 🔄 Переключение языков

1. **В интерфейсе**: Используйте переключатель RU/EN в навигации
2. **По URL**: Добавьте `?lang=en` или `?lang=ru`
3. **Автоматически**: По заголовку `Accept-Language`

### ➕ Добавление нового языка

1. **Создайте файл перевода:**
   ```bash
   cp app/translations/ru.json app/translations/новый_язык.json
   ```

2. **Отредактируйте переводы:**
   ```bash
   vim app/translations/новый_язык.json
   ```

3. **Добавьте переключатель в шаблоны:**
   ```html
   <a href="/set_language/новый_язык">НОВЫЙ_ЯЗЫК</a>
   ```

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

### 🏠 Локальная разработка

1. **Установите зависимости:**
   ```bash
   pip install -r app/requirements.txt
   ```

2. **Запустите в режиме разработки:**
   ```bash
   cd app
   python app.py
   ```

3. **Или используйте Docker:**
   ```bash
   docker compose up -d
   ```

### 🚀 CI/CD Pipeline

Автоматический деплой через GitHub Actions:

1. **Push в main** → GitHub Actions запускается
2. **Сборка образа** → Docker образ публикуется в GHCR
3. **Создание инфраструктуры** → Terraform настраивает Yandex Cloud
4. **Настройка VM** → Ansible конфигурирует сервер
5. **Запуск контейнеров** → Docker Compose разворачивает все сервисы

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

## 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/your-username/devops-portfolio/issues)
- **Email**: pishchik.aliaksey@gmail.com
- **LinkedIn**: [Алексей Пищик](https://www.linkedin.com/in/алексей-пищик-9a3b432a9/)

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для подробностей.

---

**© 2025 DevOps Portfolio - Современный DevOps проект с Docker, мониторингом и автоматизацией** 🚀