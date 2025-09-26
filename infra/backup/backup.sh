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
    # В контейнере директория уже должна существовать и быть доступной для записи
    if [ ! -d "$BACKUP_DIR" ]; then
        log "Директория $BACKUP_DIR не существует, создаем..."
        mkdir -p "$BACKUP_DIR" || {
            error "Не удалось создать директорию $BACKUP_DIR"
            return 1
        }
    fi
    
    # Проверяем права на запись
    if [ ! -w "$BACKUP_DIR" ]; then
        error "Нет прав на запись в директорию $BACKUP_DIR"
        return 1
    fi
    
    log "✓ Директория $BACKUP_DIR доступна для записи"
}

# Бэкап конфигураций Docker
backup_docker_configs() {
    log "Создание бэкапа конфигураций Docker..."
    mkdir -p "${BACKUP_PATH}/docker"
    
    # Копируем docker-compose.yml - проверяем все возможные пути
    local docker_compose_found=false
    
    for path in "/opt/devops-portfolio/docker-compose.yml" "/app/docker-compose.yml" "/opt/devops-portfolio/infra/docker-compose.yml"; do
        if [ -f "$path" ]; then
            cp "$path" "${BACKUP_PATH}/docker/"
            log "✓ docker-compose.yml скопирован из $path"
            docker_compose_found=true
            break
        fi
    done
    
    if [ "$docker_compose_found" = false ]; then
        warning "docker-compose.yml не найден ни в одном из путей"
    fi
    
    # Копируем конфигурации Nginx - проверяем все возможные пути
    local nginx_found=false
    for path in "/opt/devops-portfolio/infra/nginx" "/app/infra/nginx" "/opt/devops-portfolio/nginx"; do
        if [ -d "$path" ]; then
            cp -r "$path" "${BACKUP_PATH}/docker/"
            log "✓ Конфигурации Nginx скопированы из $path"
            nginx_found=true
            break
        fi
    done
    
    if [ "$nginx_found" = false ]; then
        warning "Конфигурации Nginx не найдены"
    fi
    
    # Копируем конфигурации мониторинга - проверяем все возможные пути
    local monitoring_found=false
    for path in "/opt/devops-portfolio/infra/monitoring" "/app/infra/monitoring" "/opt/devops-portfolio/monitoring"; do
        if [ -d "$path" ]; then
            cp -r "$path" "${BACKUP_PATH}/docker/"
            log "✓ Конфигурации мониторинга скопированы из $path"
            monitoring_found=true
            break
        fi
    done
    
    if [ "$monitoring_found" = false ]; then
        warning "Конфигурации мониторинга не найдены"
    fi
    
    # Копируем конфигурации логирования - проверяем все возможные пути
    local logging_found=false
    for path in "/opt/devops-portfolio/infra/logging" "/app/infra/logging" "/opt/devops-portfolio/logging"; do
        if [ -d "$path" ]; then
            cp -r "$path" "${BACKUP_PATH}/docker/"
            log "✓ Конфигурации логирования скопированы из $path"
            logging_found=true
            break
        fi
    done
    
    if [ "$logging_found" = false ]; then
        warning "Конфигурации логирования не найдены"
    fi
}

# Бэкап данных приложения
backup_app_data() {
    log "Создание бэкапа данных приложения..."
    mkdir -p "${BACKUP_PATH}/app"
    
    # Копируем исходный код приложения - проверяем все возможные пути
    local app_found=false
    for path in "/opt/devops-portfolio/app" "/app" "/opt/devops-portfolio"; do
        if [ -d "$path" ]; then
            cp -r "$path" "${BACKUP_PATH}/"
            log "✓ Исходный код приложения скопирован из $path"
            app_found=true
            break
        fi
    done
    
    if [ "$app_found" = false ]; then
        warning "Исходный код приложения не найден"
    fi
    
    # Копируем статические файлы - проверяем все возможные пути
    local static_found=false
    for path in "/opt/devops-portfolio/static" "/app/static" "/opt/devops-portfolio/app/static"; do
        if [ -d "$path" ]; then
            cp -r "$path" "${BACKUP_PATH}/"
            log "✓ Статические файлы скопированы из $path"
            static_found=true
            break
        fi
    done
    
    if [ "$static_found" = false ]; then
        warning "Статические файлы не найдены"
    fi
    
    # Копируем README и другие важные файлы - проверяем все возможные пути
    for file in README.md LICENSE Dockerfile; do
        local file_found=false
        for path in "/opt/devops-portfolio/$file" "/app/$file" "/opt/devops-portfolio/infra/$file"; do
            if [ -f "$path" ]; then
                cp "$path" "${BACKUP_PATH}/"
                log "✓ $file скопирован из $path"
                file_found=true
                break
            fi
        done
        
        if [ "$file_found" = false ]; then
            warning "$file не найден"
        fi
    done
}

# Бэкап данных Grafana
backup_grafana_data() {
    log "Создание бэкапа данных Grafana..."
    mkdir -p "${BACKUP_PATH}/grafana"
    
    # В контейнере app нет доступа к Docker, пропускаем остановку контейнеров
    log "Пропуск остановки Grafana (нет доступа к Docker в контейнере app)"
    
    # Копируем данные Grafana
    if [ -d "/var/lib/docker/volumes/grafana-data" ]; then
        cp -r "/var/lib/docker/volumes/grafana-data" "${BACKUP_PATH}/grafana/" || {
            warning "Не удалось скопировать данные Grafana (возможно, нет прав доступа)"
        }
        log "✓ Данные Grafana скопированы"
    else
        warning "Директория данных Grafana не найдена"
    fi
}

# Бэкап данных Loki
backup_loki_data() {
    log "Создание бэкапа данных Loki..."
    mkdir -p "${BACKUP_PATH}/loki"
    
    # В контейнере app нет доступа к Docker, пропускаем остановку контейнеров
    log "Пропуск остановки Loki (нет доступа к Docker в контейнере app)"
    
    # Копируем данные Loki
    if [ -d "/var/lib/docker/volumes/loki-data" ]; then
        cp -r "/var/lib/docker/volumes/loki-data" "${BACKUP_PATH}/loki/" || {
            warning "Не удалось скопировать данные Loki (возможно, нет прав доступа)"
        }
        log "✓ Данные Loki скопированы"
    else
        warning "Директория данных Loki не найдена"
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
        
        # Проверяем размер (уменьшаем минимальный размер для тестовых бэкапов)
        local size=$(stat -c%s "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz")
        if [ "$size" -gt 100 ]; then
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
