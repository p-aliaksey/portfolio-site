# 📱 Полная настройка алертинга через Telegram

Этот документ содержит полные инструкции по настройке системы алертинга через Telegram для проекта DevOps Portfolio.

## 🎯 Что было создано

### ✅ Компоненты системы алертинга
- **Alertmanager** - управление алертами и отправка уведомлений
- **Prometheus Rules** - автоматические правила для генерации алертов
- **Telegram Bot Integration** - интеграция с Telegram для уведомлений
- **Node Exporter** - сбор системных метрик
- **Nginx Configuration** - маршрутизация к Alertmanager

### ✅ Файлы конфигурации
- `infra/monitoring/alertmanager/alertmanager.yml` - конфигурация Alertmanager
- `infra/monitoring/prometheus/rules/alerts.yml` - правила алертов
- `infra/monitoring/prometheus/prometheus.yml` - обновленная конфигурация Prometheus
- `docker-compose.yml` - обновленный с Alertmanager и Node Exporter
- `infra/nginx/nginx.conf` - маршрут к Alertmanager

### ✅ Скрипты автоматизации
- `setup-telegram-alerting.sh` - полная автоматическая настройка
- `infra/monitoring/setup-telegram-bot.sh` - настройка Telegram бота
- `infra/monitoring/test-alerts.sh` - тестирование алертов

### ✅ Ansible Playbooks
- `infra/ansible/setup_telegram_alerting.yml` - автоматическая настройка через Ansible
- `infra/ansible/site.yml` - обновлен для включения алертинга

## 🚀 Быстрая установка

### Вариант 1: Автоматическая установка (рекомендуется)

```bash
# Сделайте скрипт исполняемым и запустите
chmod +x setup-telegram-alerting.sh
./setup-telegram-alerting.sh
```

### Вариант 2: Установка через Ansible

```bash
# Запустите полный деплой с алертингом
cd infra/ansible
ansible-playbook -i inventory.ini site.yml
```

### Вариант 3: Ручная установка

1. **Настройте Telegram бота**:
   ```bash
   chmod +x infra/monitoring/setup-telegram-bot.sh
   ./infra/monitoring/setup-telegram-bot.sh
   ```

2. **Запустите систему**:
   ```bash
   docker-compose up -d
   ```

3. **Протестируйте алерты**:
   ```bash
   chmod +x infra/monitoring/test-alerts.sh
   ./infra/monitoring/test-alerts.sh
   ```

## 📊 Настроенные алерты

### 🚨 Критические алерты (немедленное уведомление)
- **ApplicationDown** - приложение недоступно
- **PrometheusDown** - Prometheus недоступен
- **AlertmanagerDown** - Alertmanager недоступен
- **NginxDown** - Nginx недоступен
- **HighErrorRate** - высокий уровень ошибок (>10% за 5 минут)
- **DiskSpaceLow** - мало места на диске (<10%)
- **BackupFailed** - сбой бэкапа
- **ContainerStopped** - контейнер остановлен

### ⚠️ Предупреждения (группированные уведомления)
- **HighResponseTime** - высокое время отклика (>1 сек)
- **HighMemoryUsage** - высокое использование памяти (>80%)
- **HighCPUUsage** - высокое использование CPU (>80%)
- **GrafanaDown** - Grafana недоступна
- **LokiDown** - Loki недоступен
- **HighDiskIO** - высокая нагрузка на диск (>80%)
- **NetworkConnectivityIssues** - проблемы с сетью
- **BackupNotRun** - бэкап не запускался >24 часов
- **BackupSizeTooSmall** - размер бэкапа слишком мал
- **ContainerRestarting** - контейнер часто перезапускается

### ℹ️ Информационные алерты (редкие уведомления)
- Общие информационные уведомления

## 🌐 Доступные интерфейсы

После установки будут доступны:
- **Главная страница**: https://pishchik-dev.tech/
- **Grafana**: https://pishchik-dev.tech/grafana/
- **Prometheus**: https://pishchik-dev.tech/prometheus/
- **Alertmanager**: https://pishchik-dev.tech/alertmanager/
- **Loki**: https://pishchik-dev.tech/loki/

## 🧪 Тестирование

### Автоматическое тестирование
```bash
./infra/monitoring/test-alerts.sh
```

### Ручное тестирование
```bash
# Создание тестового алерта
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

## 🔧 Управление системой

### Основные команды
```bash
# Просмотр статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f

# Перезапуск сервисов
docker-compose restart

# Остановка системы
docker-compose down

# Обновление и перезапуск
docker-compose pull && docker-compose up -d
```

### Управление алертами
```bash
# Просмотр активных алертов
curl http://localhost:9093/api/v1/alerts

# Просмотр конфигурации Alertmanager
curl http://localhost:9093/api/v1/status

# Перезагрузка конфигурации Prometheus
curl -X POST http://localhost:9090/-/reload
```

## 🛠️ Устранение неполадок

### Проблема: Алерты не отправляются
1. Проверьте .env файл: `cat .env`
2. Проверьте логи Alertmanager: `docker logs alertmanager`
3. Проверьте статус бота: `curl "https://api.telegram.org/bot<TOKEN>/getMe"`
4. Проверьте конфигурацию: `docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml`

### Проблема: Бот не отвечает
1. Убедитесь, что бот запущен (отправьте /start)
2. Проверьте токен бота
3. Проверьте Chat ID

### Проблема: Сервисы не запускаются
1. Проверьте логи: `docker-compose logs`
2. Проверьте порты: `netstat -tulpn | grep :9093`
3. Перезапустите: `docker-compose restart`

## 📚 Дополнительная документация

- [README мониторинга](infra/monitoring/README.md) - подробная документация по алертингу
- [Основной README](README.md) - общая документация проекта
- [Ansible playbooks](infra/ansible/) - автоматизация развертывания

## 🎉 Готово!

Теперь у вас есть полноценная система алертинга через Telegram! 

- ✅ Все критические проблемы будут отправляться немедленно
- ✅ Предупреждения будут группироваться и отправляться реже
- ✅ Информационные сообщения будут отправляться еще реже
- ✅ Все алерты содержат ссылки на дашборды для быстрого доступа
- ✅ Автоматическая настройка через Git и Ansible

**Happy monitoring! 🚀**
