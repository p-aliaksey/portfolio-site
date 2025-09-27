# 🚀 DevOps Portfolio

Полнофункциональный DevOps проект с автоматизацией, мониторингом, логированием и многоязычной поддержкой.

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

### 🔧 **DevOps Stack**
- **Infrastructure as Code**: Terraform для Yandex Cloud
- **Configuration Management**: Ansible для автоматизации
- **Containerization**: Docker + Docker Compose
- **CI/CD**: GitHub Actions с автоматическим деплоем
- **Reverse Proxy**: Nginx с SSL/TLS поддержкой

### 📊 **Мониторинг и Наблюдаемость**
- **Prometheus**: Сбор метрик
- **Grafana**: Дашборды и визуализация
- **Loki**: Централизованное логирование
- **Promtail**: Сбор логов с контейнеров

### 🌍 **Многоязычность**
- **Русский** и **Английский** языки
- Автоматическое определение языка
- Переключатель языков в интерфейсе

### 🔄 **Автоматизация**
- **Автоматические бэкапы** с проверкой восстановления
- **Cron задачи** для регулярного обслуживания
- **Мониторинг состояния** системы

## 🏗️ Архитектура

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Пользователь  │────│      Nginx      │────│   Flask App     │
└─────────────────┘    │   (Port 80)     │    │   (Port 8000)   │
                       └─────────────────┘    └─────────────────┘
                                │
                    ┌───────────┼───────────┐
                    │           │           │
            ┌───────▼───┐ ┌─────▼─────┐ ┌───▼─────┐
            │Prometheus │ │  Grafana  │ │  Loki   │
            │(Port 9090)│ │(Port 3001)│ │(Port 3100)│
            └───────────┘ └───────────┘ └─────────┘
                    │           │           │
                    └───────────┼───────────┘
                                │
                        ┌───────▼───────┐
                        │   Promtail    │
                        │ (Log Collector)│
                        └───────────────┘
```

## 🚀 Быстрый старт

### Локальная разработка

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/your-username/devops-portfolio.git
   cd devops-portfolio
   ```

2. **Запустите локально:**
   ```bash
   docker compose up -d
   ```

3. **Откройте в браузере:**
   - Главная страница: http://localhost
   - Мониторинг: http://localhost/monitoring
   - Архитектура: http://localhost/architecture
   - Grafana: http://localhost:3001 (admin/admin)
   - Prometheus: http://localhost:9090

## 🌐 Развертывание

### 1. Подготовка инфраструктуры (Terraform)

1. **Настройте переменные:**
   ```bash
   cd infra/terraform
   cp terraform.tfvars.example terraform.tfvars
   # Отредактируйте terraform.tfvars с вашими данными
   ```

2. **Создайте инфраструктуру:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Получите IP адрес:**
   ```bash
   terraform output public_ip
   ```

### 2. Настройка Ansible

1. **Обновите inventory:**
   ```bash
   cd infra/ansible
   # Замените YOUR_VM_IP на полученный IP
   sed -i 's/YOUR_VM_IP/ваш_ip_адрес/' inventory.ini
   ```

2. **Настройте переменные:**
   ```bash
   # Отредактируйте group_vars/all.yml при необходимости
   vim group_vars/all.yml
   ```

### 3. Развертывание приложения

1. **Запустите Ansible playbook:**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

2. **Проверьте развертывание:**
   ```bash
   ./test-deployment.sh ваш_ip_адрес
   ```

### 4. Настройка HTTPS (опционально)

1. **Включите HTTPS в переменных:**
   ```yaml
   # group_vars/all.yml
   enable_https: true
   domain_name: your-domain.com
   letsencrypt_email: your-email@example.com
   ```

2. **Перезапустите развертывание:**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

## 📊 Мониторинг

### Доступные сервисы

- **Главная страница**: http://your-domain.com
- **Мониторинг**: http://your-domain.com/monitoring
- **Архитектура**: http://your-domain.com/architecture
- **Grafana**: http://your-domain.com:3001
- **Prometheus**: http://your-domain.com:9090

### Grafana Дашборды

Проект включает готовые дашборды:
- **System Overview**: Общий обзор системы
- **Docker Containers**: Мониторинг контейнеров
- **Application Metrics**: Метрики приложения

### Логирование

- **Loki**: Централизованное хранение логов
- **Promtail**: Автоматический сбор логов
- **Grafana**: Просмотр и анализ логов

## 💾 Бэкапы

### Автоматические бэкапы

1. **Настройте автоматические бэкапы:**
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

### Что включают бэкапы

- ✅ Конфигурации Docker (docker-compose.yml)
- ✅ Конфигурации Nginx
- ✅ Конфигурации Prometheus и Grafana
- ✅ Конфигурации Loki и Promtail
- ✅ Исходный код приложения
- ✅ Данные Grafana (дашборды, настройки)
- ✅ Данные Loki (логи)

### Политика хранения

- **Хранение**: 7 дней
- **Расписание**: Ежедневно в 2:00
- **Проверка**: Автоматическая проверка целостности
- **Тестирование**: Автоматический тест восстановления

## 🌍 Многоязычность

### Поддерживаемые языки

- **Русский** (по умолчанию)
- **Английский**

### Переключение языков

1. **В интерфейсе**: Используйте переключатель RU/EN в навигации
2. **По URL**: Добавьте `?lang=en` или `?lang=ru`
3. **Автоматически**: По заголовку `Accept-Language`

### Добавление нового языка

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

### Структура проекта

```
devops-portfolio/
├── app/                          # Flask приложение
│   ├── templates/                # HTML шаблоны
│   ├── static/                   # Статические файлы
│   ├── translations/             # Файлы переводов
│   └── app.py                    # Основное приложение
├── infra/                        # Инфраструктура
│   ├── terraform/                # Terraform конфигурации
│   ├── ansible/                  # Ansible playbooks
│   ├── monitoring/               # Конфигурации мониторинга
│   ├── logging/                  # Конфигурации логирования
│   ├── nginx/                    # Конфигурации Nginx
│   └── backup/                   # Скрипты бэкапов
├── docker-compose.yml            # Docker Compose конфигурация
├── Dockerfile                    # Docker образ приложения
└── README.md                     # Документация
```

### Локальная разработка

1. **Установите зависимости:**
   ```bash
   pip install -r app/requirements.txt
   ```

2. **Запустите в режиме разработки:**
   ```bash
   cd app
   python app.py
   ```

3. **Запустите тесты:**
   ```bash
   python -m pytest tests/
   ```

### CI/CD Pipeline

Проект использует GitHub Actions для автоматического развертывания:

1. **Push в main** → Автоматический деплой
2. **Сборка Docker образа** → Публикация в GHCR
3. **Запуск Ansible** → Развертывание на сервере
4. **Проверка здоровья** → Уведомления о статусе

## 🔧 Устранение неполадок

### Проблемы с контейнерами

```bash
# Проверьте статус контейнеров
docker ps -a

# Просмотрите логи
docker logs container_name

# Перезапустите сервисы
docker compose restart
```

### Проблемы с мониторингом

```bash
# Проверьте доступность Prometheus
curl http://localhost:9090/api/v1/query?query=up

# Проверьте доступность Grafana
curl http://localhost:3001/api/health

# Проверьте логи Grafana
docker logs grafana
```

### Проблемы с бэкапами

```bash
# Проверьте логи бэкапов
tail -f /var/log/backup.log

# Проверьте cron задачи
crontab -l

# Запустите бэкап вручную
/opt/devops-portfolio/infra/backup/backup.sh
```

## 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/your-username/devops-portfolio/issues)
- **Email**: pishchik.aliaksey@gmail.com
- **LinkedIn**: [Алексей Пищик](https://www.linkedin.com/in/алексей-пищик-9a3b432a9/)

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для подробностей.

---

**© 2025 DevOps Portfolio - Полнофункциональный DevOps проект с автоматизацией и мониторингом**

60.6 latest http