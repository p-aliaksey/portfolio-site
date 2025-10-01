# 📱 Настройка алертинга через Telegram

Этот документ описывает, как настроить систему алертинга через Telegram для проекта DevOps Portfolio.

## 🎯 Что включено

- **Alertmanager** - система управления алертами
- **Prometheus Rules** - правила для генерации алертов
- **Telegram Bot** - бот для отправки уведомлений
- **Автоматическая настройка** - скрипты для быстрой настройки

## 🚀 Быстрый старт

### 1. Создание Telegram бота

```bash
# Сделайте скрипт исполняемым
chmod +x infra/monitoring/setup-telegram-bot.sh

# Запустите скрипт настройки
./infra/monitoring/setup-telegram-bot.sh
```

### 2. Ручная настройка (если скрипты не работают)

#### Шаг 1: Создание бота
1. Откройте Telegram и найдите @BotFather
2. Отправьте команду `/newbot`
3. Выберите имя для бота (например, "DevOps Portfolio Alerts")
4. Выберите username для бота (например, "devops_portfolio_alerts_bot")
5. Скопируйте токен бота, который даст BotFather

#### Шаг 2: Получение Chat ID
1. Найдите вашего бота по username
2. Отправьте любое сообщение боту (например, "Hello")
3. Откройте в браузере: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
4. Найдите `"chat":{"id":` в ответе - это ваш Chat ID

#### Шаг 3: Создание .env файла
```bash
# Скопируйте пример файла
cp env.example .env

# Отредактируйте .env файл
nano .env
```

Добавьте ваши данные:
```env
TELEGRAM_BOT_TOKEN=your_actual_bot_token_here
TELEGRAM_CHAT_ID=your_actual_chat_id_here
```

### 3. Запуск системы

```bash
# Запустите все сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps
```

## 📊 Настройка алертов

### Доступные алерты

#### 🚨 Критические алерты
- **ApplicationDown** - приложение недоступно
- **PrometheusDown** - Prometheus недоступен
- **AlertmanagerDown** - Alertmanager недоступен
- **HighErrorRate** - высокий уровень ошибок
- **DiskSpaceLow** - мало места на диске
- **BackupFailed** - сбой бэкапа

#### ⚠️ Предупреждения
- **HighResponseTime** - высокое время отклика
- **HighMemoryUsage** - высокое использование памяти
- **HighCPUUsage** - высокое использование CPU
- **GrafanaDown** - Grafana недоступна
- **LokiDown** - Loki недоступен
- **HighDiskIO** - высокая нагрузка на диск
- **NetworkConnectivityIssues** - проблемы с сетью
- **BackupNotRun** - бэкап не запускался
- **BackupSizeTooSmall** - размер бэкапа слишком мал

### Настройка правил алертов

Правила алертов находятся в файле `infra/monitoring/prometheus/rules/alerts.yml`.

Пример добавления нового алерта:
```yaml
- alert: CustomAlert
  expr: your_prometheus_query_here
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Custom alert summary"
    description: "Detailed description of the alert"
```

## 🔧 Конфигурация Alertmanager

### Основные настройки

Файл конфигурации: `infra/monitoring/alertmanager/alertmanager.yml`

#### Группировка алертов
- **group_by**: группировка по alertname, cluster, service
- **group_wait**: время ожидания перед отправкой группы (10s)
- **group_interval**: интервал между группами (10s)
- **repeat_interval**: интервал повторения (1h)

#### Маршрутизация по severity
- **critical** → немедленное уведомление (5s)
- **warning** → группированное уведомление (30s)
- **info** → менее частые уведомления (1m)

### Шаблоны сообщений

#### Критические алерты
```
🔥 CRITICAL ALERT 🔥

Alert: {{ .GroupLabels.alertname }}
Status: {{ .Status | toUpper }}

Summary: {{ .Annotations.summary }}
Description: {{ .Annotations.description }}
Instance: {{ .Labels.instance }}
Started: {{ .StartsAt.Format "2006-01-02 15:04:05" }}

Action Required: Immediate attention needed!
Dashboard: https://pishchik-dev.tech/grafana
```

#### Предупреждения
```
⚠️ WARNING ALERT ⚠️

Alert: {{ .GroupLabels.alertname }}
Status: {{ .Status | toUpper }}

Summary: {{ .Annotations.summary }}
Description: {{ .Annotations.description }}
Instance: {{ .Labels.instance }}

Dashboard: https://pishchik-dev.tech/grafana
```

## 🧪 Тестирование алертов

### 1. Проверка конфигурации

```bash
# Проверка конфигурации Prometheus
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Проверка конфигурации Alertmanager
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
```

### 2. Тестирование бота

```bash
# Отправка тестового сообщения
curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage" \
  -d "chat_id=<YOUR_CHAT_ID>" \
  -d "text=Test message from DevOps Portfolio"
```

### 3. Ручное создание алерта

```bash
# Создание тестового алерта через Alertmanager API
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "warning"
      },
      "annotations": {
        "summary": "Test alert for Telegram",
        "description": "This is a test alert to verify Telegram integration"
      }
    }
  ]'
```

### 4. Автоматическое тестирование

```bash
chmod +x infra/monitoring/test-alerts.sh
./infra/monitoring/test-alerts.sh
```

## 📱 Доступ к интерфейсам

- **Alertmanager**: https://pishchik-dev.tech/alertmanager/
- **Prometheus**: https://pishchik-dev.tech/prometheus/
- **Grafana**: https://pishchik-dev.tech/grafana/

## 🔍 Мониторинг алертов

### Просмотр активных алертов
1. Откройте Alertmanager: https://pishchik-dev.tech/alertmanager/
2. Перейдите на вкладку "Alerts"
3. Просмотрите активные алерты

### Просмотр истории алертов
1. Откройте Grafana: https://pishchik-dev.tech/grafana/
2. Перейдите в раздел "Alerting"
3. Просмотрите историю алертов

## 🛠️ Устранение неполадок

### Проблема: Алерты не отправляются

1. **Проверьте .env файл**:
   ```bash
   cat .env
   ```

2. **Проверьте логи Alertmanager**:
   ```bash
   docker logs alertmanager
   ```

3. **Проверьте статус бота**:
   ```bash
   curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getMe"
   ```

4. **Проверьте конфигурацию**:
   ```bash
   docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
   ```

### Проблема: Бот не отвечает

1. **Проверьте токен бота**
2. **Убедитесь, что бот запущен** (отправьте /start боту)
3. **Проверьте Chat ID**

### Проблема: Алерты дублируются

1. **Проверьте группировку** в alertmanager.yml
2. **Настройте inhibit_rules** для подавления дубликатов

## 📚 Дополнительные ресурсы

- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Telegram Bot API](https://core.telegram.org/bots/api)

## 🎉 Готово!

Теперь у вас есть полноценная система алертинга через Telegram! 

- ✅ Все критические проблемы будут отправляться немедленно
- ✅ Предупреждения будут группироваться и отправляться реже
- ✅ Информационные сообщения будут отправляться еще реже
- ✅ Все алерты содержат ссылки на дашборды для быстрого доступа

**Happy monitoring! 🚀**
