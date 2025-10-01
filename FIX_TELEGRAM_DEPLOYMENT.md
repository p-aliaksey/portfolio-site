# 🔧 Исправление проблемы с деплоем Telegram алертинга

## ❌ Проблема
Ansible не может запустить Docker Compose из-за отсутствия файла `.env` с переменными Telegram бота.

## ✅ Решение

### 1. Обновленные файлы
- `infra/ansible/deploy.yml` - создает `.env` файл с placeholder значениями
- `infra/ansible/setup_telegram_alerting.yml` - обновлен для работы с placeholder значениями
- `infra/ansible/configure_telegram_bot.yml` - новый playbook для настройки бота на сервере
- `docker-compose.yml` - добавлены значения по умолчанию для переменных

### 2. Что изменилось

#### В `deploy.yml`:
```yaml
- name: Create .env file with placeholder values
  copy:
    content: |
      # Telegram Bot Configuration
      # Configure these values manually after deployment
      TELEGRAM_BOT_TOKEN=your_bot_token_here
      TELEGRAM_CHAT_ID=your_chat_id_here
    dest: /opt/devops-portfolio/.env
    mode: '0644'
```

#### В `docker-compose.yml`:
```yaml
environment:
  - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN:-your_bot_token_here}
  - TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-your_chat_id_here}
```

### 3. Как теперь работает деплой

1. **Ansible создает `.env` файл** с placeholder значениями
2. **Docker Compose запускается** с placeholder значениями
3. **Система работает** без Telegram уведомлений
4. **После деплоя** можно настроить Telegram бота

### 4. Настройка Telegram бота после деплоя

#### Вариант 1: Автоматическая настройка
```bash
# SSH на сервер
ssh user@your-server-ip

# Запустите автоматический скрипт настройки
/opt/devops-portfolio/setup-telegram-bot.sh
```

#### Вариант 2: Ручная настройка
```bash
# SSH на сервер
ssh user@your-server-ip

# Отредактируйте .env файл
nano /opt/devops-portfolio/.env

# Замените placeholder значения на реальные:
# TELEGRAM_BOT_TOKEN=your_actual_bot_token
# TELEGRAM_CHAT_ID=your_actual_chat_id

# Перезапустите Alertmanager
docker compose -f /opt/devops-portfolio/docker-compose.yml restart alertmanager
```

### 5. Проверка работы

```bash
# Проверьте статус контейнеров
docker compose -f /opt/devops-portfolio/docker-compose.yml ps

# Проверьте логи Alertmanager
docker compose -f /opt/devops-portfolio/docker-compose.yml logs alertmanager

# Проверьте доступность Alertmanager
curl http://localhost:9093/-/healthy
```

## 🎯 Результат

- ✅ Ansible деплой будет работать без ошибок
- ✅ Система запустится с placeholder значениями
- ✅ Все сервисы будут доступны
- ✅ Telegram можно настроить после деплоя
- ✅ Алерты будут работать после настройки бота

## 🚀 Следующие шаги

1. Запустите обновленный Ansible playbook
2. После успешного деплоя настройте Telegram бота
3. Протестируйте алерты

**Проблема решена! 🎉**
