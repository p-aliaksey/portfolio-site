#!/bin/bash

# Скрипт автоматизации бэкапов для DevOps Portfolio
# Создает бэкапы конфигураций, данных и проверяет восстановление

set -e

# Конфигурация
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="devops-portfolio-backup-${DATE}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
MAX_BACKUPS=3
LOG_FILE="/var/log/backup.log"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# Создание директории для бэкапов
create_backup_dir() {
    log "Создание директории для бэкапов: $BACKUP_DIR"
    sudo mkdir -p "$BACKUP_DIR"
    sudo chown -R $(whoami):$(whoami) "$BACKUP_DIR"
}

# Бэкап конфигураций Docker
backup_docker_configs() {
    log "Создание бэкапа конфигураций Docker..."
    mkdir -p "${BACKUP_PATH}/docker"
    
    # Копируем docker-compose.yml
    if [ -f "/opt/devops-portfolio/docker-compose.yml" ]; then
        cp "/opt/devops-portfolio/docker-compose.yml" "${BACKUP_PATH}/docker/"
        log "✓ docker-compose.yml скопирован"
    else
        warning "docker-compose.yml не найден"
    fi
    
    # Копируем конфигурации Nginx
    if [ -d "/opt/devops-portfolio/infra/nginx" ]; then
        cp -r "/opt/devops-portfolio/infra/nginx" "${BACKUP_PATH}/docker/"
        log "✓ Конфигурации Nginx скопированы"
    fi
    
    # Копируем конфигурации мониторинга
    if [ -d "/opt/devops-portfolio/infra/monitoring" ]; then
        cp -r "/opt/devops-portfolio/infra/monitoring" "${BACKUP_PATH}/docker/"
        log "✓ Конфигурации мониторинга скопированы"
    fi
    
    # Копируем конфигурации логирования
    if [ -d "/opt/devops-portfolio/infra/logging" ]; then
        cp -r "/opt/devops-portfolio/infra/logging" "${BACKUP_PATH}/docker/"
        log "✓ Конфигурации логирования скопированы"
    fi
}

# Бэкап данных приложения
backup_app_data() {
    log "Создание бэкапа данных приложения..."
    mkdir -p "${BACKUP_PATH}/app"
    
    # Копируем исходный код приложения
    if [ -d "/opt/devops-portfolio/app" ]; then
        cp -r "/opt/devops-portfolio/app" "${BACKUP_PATH}/"
        log "✓ Исходный код приложения скопирован"
    fi
    
    # Копируем статические файлы
    if [ -d "/opt/devops-portfolio/static" ]; then
        cp -r "/opt/devops-portfolio/static" "${BACKUP_PATH}/"
        log "✓ Статические файлы скопированы"
    fi
}

# Бэкап данных Grafana
backup_grafana_data() {
    log "Создание бэкапа данных Grafana..."
    mkdir -p "${BACKUP_PATH}/grafana"
    
    # Останавливаем Grafana для консистентного бэкапа
    if docker ps | grep -q grafana; then
        log "Остановка Grafana для создания бэкапа..."
        docker stop grafana
    fi
    
    # Копируем данные Grafana
    if [ -d "/var/lib/docker/volumes/grafana-data" ]; then
        sudo cp -r "/var/lib/docker/volumes/grafana-data" "${BACKUP_PATH}/grafana/"
        log "✓ Данные Grafana скопированы"
    fi
    
    # Запускаем Grafana обратно
    if docker ps -a | grep -q grafana; then
        log "Запуск Grafana после бэкапа..."
        docker start grafana
    fi
}

# Бэкап данных Loki
backup_loki_data() {
    log "Создание бэкапа данных Loki..."
    mkdir -p "${BACKUP_PATH}/loki"
    
    # Останавливаем Loki для консистентного бэкапа
    if docker ps | grep -q loki; then
        log "Остановка Loki для создания бэкапа..."
        docker stop loki
    fi
    
    # Копируем данные Loki
    if [ -d "/var/lib/docker/volumes/loki-data" ]; then
        sudo cp -r "/var/lib/docker/volumes/loki-data" "${BACKUP_PATH}/loki/"
        log "✓ Данные Loki скопированы"
    fi
    
    # Запускаем Loki обратно
    if docker ps -a | grep -q loki; then
        log "Запуск Loki после бэкапа..."
        docker start loki
    fi
}

# Создание архива бэкапа
create_backup_archive() {
    log "Создание архива бэкапа..."
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    # Удаляем временную директорию
    rm -rf "$BACKUP_NAME"
    
    # Устанавливаем права доступа
    chmod 600 "${BACKUP_NAME}.tar.gz"
    
    log "✓ Архив создан: ${BACKUP_NAME}.tar.gz"
    log "✓ Размер архива: $(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)"
}

# Очистка старых бэкапов
cleanup_old_backups() {
    log "Очистка бэкапов (оставляем только $MAX_BACKUPS последних)..."
    
    # Получаем список всех бэкапов, отсортированных по времени создания (новые первыми)
    local backup_files=($(find "$BACKUP_DIR" -name "devops-portfolio-backup-*.tar.gz" -type f -printf "%T@ %p\n" | sort -nr | awk '{print $2}'))
    
    # Удаляем все бэкапы кроме последних MAX_BACKUPS
    if [ ${#backup_files[@]} -gt $MAX_BACKUPS ]; then
        local files_to_delete=("${backup_files[@]:$MAX_BACKUPS}")
        for file in "${files_to_delete[@]}"; do
            log "Удаление старого бэкапа: $(basename "$file")"
            rm -f "$file"
        done
        log "✓ Удалено $((${#backup_files[@]} - MAX_BACKUPS)) старых бэкапов"
    else
        log "✓ Количество бэкапов в пределах лимита ($MAX_BACKUPS)"
    fi
}

# Проверка целостности бэкапа
verify_backup() {
    log "Проверка целостности бэкапа..."
    
    if [ -f "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" ]; then
        # Проверяем архив
        if tar -tzf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" > /dev/null 2>&1; then
            log "✓ Архив корректен"
        else
            error "Архив поврежден!"
            return 1
        fi
        
        # Проверяем размер
        local size=$(stat -c%s "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz")
        if [ "$size" -gt 1024 ]; then
            log "✓ Размер архива приемлемый: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
        else
            error "Архив слишком мал, возможно поврежден!"
            return 1
        fi
    else
        error "Архив не найден!"
        return 1
    fi
}

# Тест восстановления
test_restore() {
    log "Тестирование восстановления..."
    
    local test_dir="/tmp/backup-test-${DATE}"
    mkdir -p "$test_dir"
    
    # Распаковываем архив в тестовую директорию
    if tar -xzf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "$test_dir"; then
        log "✓ Архив успешно распакован"
        
        # Проверяем наличие ключевых файлов
        local key_files=(
            "$test_dir/$BACKUP_NAME/docker/docker-compose.yml"
            "$test_dir/$BACKUP_NAME/docker/nginx"
            "$test_dir/$BACKUP_NAME/docker/monitoring"
            "$test_dir/$BACKUP_NAME/app"
        )
        
        for file in "${key_files[@]}"; do
            if [ -e "$file" ]; then
                log "✓ Найден: $file"
            else
                warning "Не найден: $file"
            fi
        done
        
        # Очищаем тестовую директорию
        rm -rf "$test_dir"
        log "✓ Тест восстановления завершен успешно"
    else
        error "Ошибка при распаковке архива!"
        return 1
    fi
}

# Отправка уведомления
send_notification() {
    local status=$1
    local message=$2
    
    # Здесь можно добавить отправку уведомлений (email, Slack, Telegram)
    log "Уведомление: $status - $message"
    
    # Пример отправки в лог
    echo "BACKUP_STATUS: $status" >> "$LOG_FILE"
    echo "BACKUP_MESSAGE: $message" >> "$LOG_FILE"
}

# Основная функция
main() {
    log "=== Начало создания бэкапа DevOps Portfolio ==="
    
    # Создаем директорию для бэкапов
    create_backup_dir
    
    # Создаем бэкапы
    backup_docker_configs
    backup_app_data
    backup_grafana_data
    backup_loki_data
    
    # Создаем архив
    create_backup_archive
    
    # Проверяем целостность
    if verify_backup; then
        log "✓ Бэкап создан успешно"
        
        # Тестируем восстановление
        if test_restore; then
            log "✓ Тест восстановления прошел успешно"
            send_notification "SUCCESS" "Бэкап создан и проверен успешно"
        else
            error "Тест восстановления не прошел"
            send_notification "WARNING" "Бэкап создан, но тест восстановления не прошел"
        fi
    else
        error "Ошибка при создании бэкапа"
        send_notification "ERROR" "Ошибка при создании бэкапа"
        exit 1
    fi
    
    # Очищаем старые бэкапы
    cleanup_old_backups
    
    log "=== Бэкап завершен успешно ==="
}

# Запуск скрипта
main "$@"
