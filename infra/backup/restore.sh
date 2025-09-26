#!/bin/bash

# Скрипт восстановления для DevOps Portfolio
# Восстанавливает систему из бэкапа

set -e

# Конфигурация
BACKUP_DIR="/opt/backups"
RESTORE_DIR="/opt/devops-portfolio"
LOG_FILE="/var/log/restore.log"

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

# Показать доступные бэкапы
list_backups() {
    log "Доступные бэкапы:"
    if [ -d "$BACKUP_DIR" ]; then
        ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    else
        warning "Директория бэкапов не найдена: $BACKUP_DIR"
    fi
}

# Остановка сервисов
stop_services() {
    log "Остановка сервисов..."
    
    if [ -f "$RESTORE_DIR/docker-compose.yml" ]; then
        cd "$RESTORE_DIR"
        docker compose down
        log "✓ Сервисы остановлены"
    else
        warning "docker-compose.yml не найден, пропускаем остановку сервисов"
    fi
}

# Восстановление из архива
restore_from_archive() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        error "Файл бэкапа не найден: $backup_file"
        exit 1
    fi
    
    log "Восстановление из архива: $backup_file"
    
    # Создаем временную директорию для восстановления
    local temp_dir="/tmp/restore-$(date +%s)"
    mkdir -p "$temp_dir"
    
    # Распаковываем архив
    if tar -xzf "$backup_file" -C "$temp_dir"; then
        log "✓ Архив распакован"
        
        # Находим директорию с данными
        local backup_data_dir=$(find "$temp_dir" -name "devops-portfolio-backup-*" -type d | head -1)
        
        if [ -n "$backup_data_dir" ]; then
            log "✓ Найдена директория с данными: $backup_data_dir"
            
            # Создаем целевую директорию
            sudo mkdir -p "$RESTORE_DIR"
            sudo chown -R $(whoami):$(whoami) "$RESTORE_DIR"
            
            # Восстанавливаем конфигурации Docker
            if [ -d "$backup_data_dir/docker" ]; then
                cp -r "$backup_data_dir/docker"/* "$RESTORE_DIR/"
                log "✓ Конфигурации Docker восстановлены"
            fi
            
            # Восстанавливаем данные приложения
            if [ -d "$backup_data_dir/app" ]; then
                cp -r "$backup_data_dir/app" "$RESTORE_DIR/"
                log "✓ Данные приложения восстановлены"
            fi
            
            # Восстанавливаем статические файлы
            if [ -d "$backup_data_dir/static" ]; then
                cp -r "$backup_data_dir/static" "$RESTORE_DIR/"
                log "✓ Статические файлы восстановлены"
            fi
            
            # Восстанавливаем данные Grafana
            if [ -d "$backup_data_dir/grafana" ]; then
                sudo mkdir -p "/var/lib/docker/volumes"
                sudo cp -r "$backup_data_dir/grafana/grafana-data" "/var/lib/docker/volumes/"
                log "✓ Данные Grafana восстановлены"
            fi
            
            # Восстанавливаем данные Loki
            if [ -d "$backup_data_dir/loki" ]; then
                sudo mkdir -p "/var/lib/docker/volumes"
                sudo cp -r "$backup_data_dir/loki/loki-data" "/var/lib/docker/volumes/"
                log "✓ Данные Loki восстановлены"
            fi
            
        else
            error "Директория с данными не найдена в архиве"
            exit 1
        fi
        
        # Очищаем временную директорию
        rm -rf "$temp_dir"
        
    else
        error "Ошибка при распаковке архива"
        exit 1
    fi
}

# Запуск сервисов
start_services() {
    log "Запуск сервисов..."
    
    if [ -f "$RESTORE_DIR/docker-compose.yml" ]; then
        cd "$RESTORE_DIR"
        docker compose up -d
        log "✓ Сервисы запущены"
        
        # Ждем запуска сервисов
        sleep 10
        
        # Проверяем статус
        docker ps --format "table {{.Names}}\t{{.Status}}"
        
    else
        error "docker-compose.yml не найден после восстановления"
        exit 1
    fi
}

# Проверка восстановления
verify_restore() {
    log "Проверка восстановления..."
    
    # Проверяем наличие ключевых файлов
    local key_files=(
        "$RESTORE_DIR/docker-compose.yml"
        "$RESTORE_DIR/app/app.py"
        "$RESTORE_DIR/infra/nginx/nginx-http.conf"
        "$RESTORE_DIR/infra/monitoring/prometheus/prometheus.yml"
        "$RESTORE_DIR/infra/monitoring/grafana/datasources.yml"
    )
    
    for file in "${key_files[@]}"; do
        if [ -f "$file" ]; then
            log "✓ Найден: $file"
        else
            warning "Не найден: $file"
        fi
    done
    
    # Проверяем статус контейнеров
    log "Проверка статуса контейнеров..."
    if docker ps | grep -q "Up"; then
        log "✓ Контейнеры запущены"
    else
        warning "Некоторые контейнеры не запущены"
    fi
}

# Основная функция
main() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        error "Не указан файл бэкапа"
        echo "Использование: $0 <путь_к_архиву_бэкапа>"
        echo ""
        list_backups
        exit 1
    fi
    
    log "=== Начало восстановления DevOps Portfolio ==="
    log "Файл бэкапа: $backup_file"
    
    # Останавливаем сервисы
    stop_services
    
    # Восстанавливаем из архива
    restore_from_archive "$backup_file"
    
    # Запускаем сервисы
    start_services
    
    # Проверяем восстановление
    verify_restore
    
    log "=== Восстановление завершено успешно ==="
}

# Запуск скрипта
main "$@"
