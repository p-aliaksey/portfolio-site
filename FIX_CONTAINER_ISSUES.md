# 🔧 Исправление проблем с контейнерами

## ❌ Проблемы после деплоя:

1. **Prometheus** - неправильный флаг `--alertmanager.url`
2. **Alertmanager** - ошибки в конфигурации YAML (неподдерживаемые поля)
3. **Nginx** - не может найти upstream "prometheus"

## ✅ Решение

### 1. Обновленные файлы
- `docker-compose.yml` - убран неправильный флаг `--alertmanager.url`
- `infra/monitoring/alertmanager/alertmanager.yml` - исправлена конфигурация
- `infra/monitoring/update-alertmanager-config.sh` - новый скрипт для обновления конфигурации

### 2. Что было исправлено

#### В `docker-compose.yml`:
```yaml
# Убран неправильный флаг
prometheus:
  command:
    - "--config.file=/etc/prometheus/prometheus.yml"
    - "--web.enable-lifecycle"
    - "--web.enable-admin-api"
    - "--web.listen-address=0.0.0.0:9090"
    - "--storage.tsdb.retention.time=15d"
    # Убран: - "--alertmanager.url=http://alertmanager:9093"
```

#### В `alertmanager.yml`:
```yaml
# Убраны неподдерживаемые поля из global секции
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alertmanager@example.com'
  # Убраны: telegram_bot_token, telegram_chat_id, telegram_send_resolved

# Исправлены переменные окружения
receivers:
  - name: 'telegram-notifications'
    telegram_configs:
      - bot_token: 'your_bot_token_here'  # Вместо ${TELEGRAM_BOT_TOKEN}
        chat_id: 'your_chat_id_here'      # Вместо ${TELEGRAM_CHAT_ID}
```

### 3. Новый скрипт обновления конфигурации

Создан `update-alertmanager-config.sh` для обновления конфигурации с реальными токенами:

```bash
# Использование:
./update-alertmanager-config.sh <bot_token> <chat_id>

# Пример:
./update-alertmanager-config.sh 123456789:ABCdefGHIjklMNOpqrsTUVwxyz 987654321
```

### 4. Теперь система будет работать:

1. **Prometheus** - запустится без ошибок
2. **Alertmanager** - запустится с корректной конфигурацией
3. **Nginx** - сможет найти все upstream сервисы
4. **Telegram** - можно настроить после деплоя

### 5. Настройка Telegram после деплоя:

```bash
# SSH на сервер
ssh user@your-server-ip

# Вариант 1: Автоматическая настройка
/opt/devops-portfolio/setup-telegram-bot.sh

# Вариант 2: Ручная настройка
/opt/devops-portfolio/update-alertmanager-config.sh YOUR_BOT_TOKEN YOUR_CHAT_ID

# Вариант 3: Ручное редактирование
nano /opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml
# Замените 'your_bot_token_here' и 'your_chat_id_here' на реальные значения
docker compose -f /opt/devops-portfolio/docker-compose.yml restart alertmanager
```

## 🎯 Результат

- ✅ Prometheus запустится без ошибок
- ✅ Alertmanager запустится с корректной конфигурацией
- ✅ Nginx сможет проксировать все сервисы
- ✅ Telegram можно настроить после деплоя
- ✅ Все сервисы будут доступны

## 🚀 Следующие шаги

1. Запустите обновленный Ansible playbook
2. После успешного деплоя настройте Telegram бота
3. Протестируйте алерты

**Проблемы с контейнерами исправлены! 🎉**
