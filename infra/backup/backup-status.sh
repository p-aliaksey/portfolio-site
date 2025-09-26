#!/bin/bash

# Скрипт для проверки статуса бэкапов
# Показывает информацию о последних бэкапах, cron задачах и здоровье системы

set -e

BACKUP_DIR="/opt/backups"
CRON_LOG="/var/log/backup-cron.log"
BACKUP_LOG="/var/log/backup.log"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции вывода
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Проверка cron задач
check_cron_jobs() {
    print_header "Cron задачи бэкапов"
    
    local cron_jobs=$(crontab -l 2>/dev/null | grep -E "(backup|restore)" || echo "")
    
    if [ -n "$cron_jobs" ]; then
        echo "$cron_jobs" | while read -r line; do
            if echo "$line" | grep -q "backup.sh"; then
                if echo "$line" | grep -q "weekly"; then
                    print_success "Еженедельный бэкап: $(echo $line | awk '{print $1, $2, $3, $4, $5}')"
                else
                    print_success "Ежедневный бэкап: $(echo $line | awk '{print $1, $2, $3, $4, $5}')"
                fi
            fi
        done
    else
        print_error "Cron задачи бэкапов не найдены"
    fi
    echo ""
}

# Проверка последних бэкапов
check_recent_backups() {
    print_header "Последние бэкапы"
    
    if [ -d "$BACKUP_DIR" ]; then
        local backups=$(find "$BACKUP_DIR" -name "devops-portfolio-backup-*.tar.gz" -type f -printf "%T@ %Tc %p\n" 2>/dev/null | sort -nr)
        
        if [ -n "$backups" ]; then
            echo "Доступные бэкапы (максимум 3):"
            echo "$backups" | while read -r timestamp date time file; do
                local size=$(du -h "$file" | cut -f1)
                local age_hours=$(( ($(date +%s) - ${timestamp%.*}) / 3600 ))
                if [ $age_hours -lt 25 ]; then
                    print_success "$date $time - $size (${age_hours}ч назад)"
                elif [ $age_hours -lt 49 ]; then
                    print_warning "$date $time - $size (${age_hours}ч назад)"
                else
                    print_error "$date $time - $size (${age_hours}ч назад)"
                fi
            done
        else
            print_error "Бэкапы не найдены"
        fi
    else
        print_error "Директория бэкапов не найдена: $BACKUP_DIR"
    fi
    echo ""
}

# Проверка логов
check_logs() {
    print_header "Логи бэкапов"
    
    if [ -f "$CRON_LOG" ]; then
        echo "Последние записи из cron лога:"
        tail -10 "$CRON_LOG" | while read -r line; do
            if echo "$line" | grep -q "ERROR\|error"; then
                print_error "$line"
            elif echo "$line" | grep -q "WARNING\|warning"; then
                print_warning "$line"
            else
                echo "  $line"
            fi
        done
    else
        print_warning "Cron лог не найден: $CRON_LOG"
    fi
    echo ""
}

# Проверка здоровья системы
check_system_health() {
    print_header "Здоровье системы бэкапов"
    
    # Проверяем доступность директории
    if [ -d "$BACKUP_DIR" ]; then
        print_success "Директория бэкапов доступна"
        
        # Проверяем свободное место
        local free_space=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
        local free_gb=$((free_space / 1024 / 1024))
        
        if [ $free_gb -gt 10 ]; then
            print_success "Свободное место: ${free_gb}GB"
        elif [ $free_gb -gt 5 ]; then
            print_warning "Свободное место: ${free_gb}GB (мало)"
        else
            print_error "Свободное место: ${free_gb}GB (критически мало)"
        fi
    else
        print_error "Директория бэкапов недоступна"
    fi
    
    # Проверяем права доступа
    if [ -x "/opt/devops-portfolio/infra/backup/backup.sh" ]; then
        print_success "Скрипт бэкапа исполняемый"
    else
        print_error "Скрипт бэкапа не исполняемый"
    fi
    
    # Проверяем Docker
    if docker ps >/dev/null 2>&1; then
        print_success "Docker доступен"
    else
        print_error "Docker недоступен"
    fi
    echo ""
}

# Статистика бэкапов
show_backup_stats() {
    print_header "Статистика бэкапов"
    
    if [ -d "$BACKUP_DIR" ]; then
        local total_backups=$(find "$BACKUP_DIR" -name "devops-portfolio-backup-*.tar.gz" -type f | wc -l)
        local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
        
        echo "Всего бэкапов: $total_backups (максимум 3)"
        echo "Общий размер: $total_size"
        
        if [ $total_backups -gt 0 ]; then
            echo ""
            echo "Детали бэкапов:"
            find "$BACKUP_DIR" -name "devops-portfolio-backup-*.tar.gz" -type f -exec du -h {} \; | sort -hr | while read -r size file; do
                echo "  $size - $(basename "$file")"
            done
        fi
    else
        print_error "Директория бэкапов не найдена"
    fi
    echo ""
}

# Рекомендации
show_recommendations() {
    print_header "Рекомендации"
    
    # Проверяем последний бэкап
    local last_backup=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -1)
    
    if [ -n "$last_backup" ]; then
        local timestamp=$(echo "$last_backup" | awk '{print $1}')
        local age_hours=$(( ($(date +%s) - ${timestamp%.*}) / 3600 ))
        
        if [ $age_hours -gt 25 ]; then
            print_warning "Последний бэкап был ${age_hours} часов назад. Проверьте cron задачи."
        else
            print_success "Бэкапы выполняются регулярно"
        fi
    else
        print_error "Бэкапы не найдены. Запустите бэкап вручную: /opt/devops-portfolio/infra/backup/backup.sh"
    fi
    
    # Проверяем свободное место
    if [ -d "$BACKUP_DIR" ]; then
        local free_space=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
        local free_gb=$((free_space / 1024 / 1024))
        
        if [ $free_gb -lt 5 ]; then
            print_warning "Мало свободного места. Очистите старые бэкапы или увеличьте диск."
        fi
    fi
    echo ""
}

# Основная функция
main() {
    echo -e "${BLUE}🔍 Проверка статуса системы бэкапов DevOps Portfolio${NC}"
    echo ""
    
    check_cron_jobs
    check_recent_backups
    check_logs
    check_system_health
    show_backup_stats
    show_recommendations
    
    echo -e "${GREEN}=== Проверка завершена ===${NC}"
}

# Запуск скрипта
main "$@"
