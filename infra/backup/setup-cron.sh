#!/bin/bash

# Скрипт настройки автоматических бэкапов
# Устанавливает cron задачу для ежедневных бэкапов

set -e

BACKUP_SCRIPT="/opt/devops-portfolio/infra/backup/backup.sh"
CRON_LOG="/var/log/backup-cron.log"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Проверяем права доступа
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        warning "Скрипт запущен без прав root, попробуем с sudo"
        # Не выходим, а продолжаем с sudo
    fi
}

# Устанавливаем права на скрипты
setup_permissions() {
    log "Установка прав доступа на скрипты бэкапа..."
    
    chmod +x "$BACKUP_SCRIPT"
    chmod +x "/opt/devops-portfolio/infra/backup/restore.sh"
    
    log "✓ Права доступа установлены"
}

# Создаем cron задачу
setup_cron() {
    log "Настройка cron задачи для автоматических бэкапов..."
    
    # Удаляем старые задачи бэкапа если есть
    crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT" | crontab - 2>/dev/null || true
    
    # Создаем cron задачу для ежедневного бэкапа в 2:00
    local cron_entry="0 2 * * * sudo $BACKUP_SCRIPT >> $CRON_LOG 2>&1"
    
    # Добавляем задачу в crontab
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    
    log "✓ Cron задача добавлена: ежедневно в 2:00"
    log "✓ Логи бэкапов будут сохраняться в: $CRON_LOG"
}

# Создаем директорию для логов
setup_logging() {
    log "Настройка логирования..."
    
    touch "$CRON_LOG"
    chmod 644 "$CRON_LOG"
    
    log "✓ Логирование настроено"
}

# Проверяем установку
verify_setup() {
    log "Проверка установки..."
    
    # Проверяем cron задачу
    if crontab -l | grep -q "$BACKUP_SCRIPT"; then
        log "✓ Cron задача найдена"
    else
        error "Cron задача не найдена"
        exit 1
    fi
    
    # Проверяем права на скрипт
    if [ -x "$BACKUP_SCRIPT" ]; then
        log "✓ Скрипт бэкапа исполняемый"
    else
        error "Скрипт бэкапа не исполняемый"
        exit 1
    fi
    
    # Проверяем логи
    if [ -f "$CRON_LOG" ]; then
        log "✓ Файл логов создан"
    else
        error "Файл логов не создан"
        exit 1
    fi
}

# Показываем статус
show_status() {
    log "=== Статус автоматических бэкапов ==="
    echo ""
    echo "Cron задачи:"
    crontab -l | grep -E "(backup|restore)" || echo "  Нет задач бэкапа"
    echo ""
    echo "Последние логи:"
    if [ -f "$CRON_LOG" ]; then
        tail -10 "$CRON_LOG" || echo "  Логи пусты"
    else
        echo "  Файл логов не найден"
    fi
    echo ""
    echo "Доступные бэкапы:"
    ls -la /opt/backups/*.tar.gz 2>/dev/null | tail -5 || echo "  Бэкапы не найдены"
    echo ""
}

# Основная функция
main() {
    log "=== Настройка автоматических бэкапов ==="
    
    check_permissions
    setup_permissions
    setup_cron
    setup_logging
    verify_setup
    
    log "=== Настройка завершена успешно ==="
    echo ""
    show_status
}

# Запуск скрипта
main "$@"
