# 📱 Настройка алертинга через Telegram для Ubuntu

Краткая инструкция по настройке системы алертинга через Telegram на Ubuntu сервере.

## 🚀 Быстрая установка

### 1. Автоматическая установка (рекомендуется)

```bash
# Сделайте скрипт исполняемым и запустите
chmod +x setup-telegram-alerting.sh
./setup-telegram-alerting.sh
```

### 2. Установка через Ansible (для продакшена)

```bash
# Запустите полный деплой с алертингом
cd infra/ansible
ansible-playbook -i inventory.ini site.yml
```

### 3. Ручная установка

```bash
# 1. Настройте Telegram бота
chmod +x infra/monitoring/setup-telegram-bot.sh
./infra/monitoring/setup-telegram-bot.sh

# 2. Запустите систему
docker-compose up -d

# 3. Протестируйте алерты
chmod +x infra/monitoring/test-alerts.sh
./infra/monitoring/test-alerts.sh
```

## 📊 Настроенные алерты

### 🚨 Критические (немедленное уведомление)
- Application down, Prometheus down, Disk space low, Backup failed

### ⚠️ Предупреждения (группированные)
- Memory usage, CPU usage, Grafana down, Loki down, Network issues

### ℹ️ Информационные (редкие)
- Общие уведомления

## 🌐 Доступные интерфейсы

- **Alertmanager**: https://pishchik-dev.tech/alertmanager/
- **Prometheus**: https://pishchik-dev.tech/prometheus/
- **Grafana**: https://pishchik-dev.tech/grafana/

## 🧪 Тестирование

```bash
# Автоматическое тестирование
./infra/monitoring/test-alerts.sh

# Ручное создание алерта
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"TestAlert","severity":"warning"},"annotations":{"summary":"Test alert"}}]'
```

## 🔧 Управление

```bash
# Статус сервисов
docker-compose ps

# Логи
docker-compose logs -f

# Перезапуск
docker-compose restart

# Остановка
docker-compose down
```

## 🎉 Готово!

Система алертинга через Telegram готова к использованию на Ubuntu сервере!

**Happy monitoring! 🚀**
