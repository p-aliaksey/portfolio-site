#!/bin/bash

# Нагрузочный тест для проверки алертинга
# Создает различные виды нагрузки для тестирования мониторинга и алертов

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO:${NC} $1"
}

# Проверка зависимостей
check_dependencies() {
    log "Проверка зависимостей..."
    
    commands=("stress" "curl" "docker")
    missing=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" > /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Отсутствуют команды: ${missing[*]}"
        info "Установите недостающие пакеты:"
        info "Ubuntu/Debian: sudo apt-get install stress curl docker.io"
        info "CentOS/RHEL: sudo yum install stress curl docker"
        exit 1
    fi
    
    log "Все зависимости установлены"
}

# CPU нагрузка
cpu_stress_test() {
    local duration=${1:-60}
    local cores=${2:-2}
    
    log "Запуск CPU нагрузочного теста..."
    info "Длительность: ${duration}с, Ядер: ${cores}"
    
    # Запускаем stress в фоне
    stress --cpu "$cores" --timeout "${duration}s" &
    local stress_pid=$!
    
    log "CPU стресс тест запущен (PID: $stress_pid)"
    
    # Мониторим нагрузку
    for ((i=1; i<=duration; i++)); do
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
        
        if (( i % 10 == 0 )); then
            info "CPU: ${cpu_usage}%, Load: ${load_avg}"
        fi
        
        sleep 1
    done
    
    wait $stress_pid
    log "CPU стресс тест завершен"
}

# Memory нагрузка
memory_stress_test() {
    local duration=${1:-60}
    local memory_mb=${2:-512}
    
    log "Запуск Memory нагрузочного теста..."
    info "Длительность: ${duration}с, Память: ${memory_mb}MB"
    
    # Запускаем stress в фоне
    stress --vm 1 --vm-bytes "${memory_mb}M" --timeout "${duration}s" &
    local stress_pid=$!
    
    log "Memory стресс тест запущен (PID: $stress_pid)"
    
    # Мониторим использование памяти
    for ((i=1; i<=duration; i++)); do
        mem_usage=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
        
        if (( i % 10 == 0 )); then
            info "Memory usage: ${mem_usage}%"
        fi
        
        sleep 1
    done
    
    wait $stress_pid
    log "Memory стресс тест завершен"
}

# Disk I/O нагрузка
disk_stress_test() {
    local duration=${1:-60}
    local workers=${2:-2}
    
    log "Запуск Disk I/O нагрузочного теста..."
    info "Длительность: ${duration}с, Workers: ${workers}"
    
    # Создаем временную директорию
    local temp_dir="/tmp/disk_stress_$$"
    mkdir -p "$temp_dir"
    
    # Запускаем stress в фоне
    stress --io "$workers" --hdd 1 --hdd-bytes 100M --timeout "${duration}s" --temp-dir "$temp_dir" &
    local stress_pid=$!
    
    log "Disk I/O стресс тест запущен (PID: $stress_pid)"
    
    # Мониторим I/O
    for ((i=1; i<=duration; i++)); do
        if (( i % 15 == 0 )); then
            disk_usage=$(df /tmp | tail -1 | awk '{print $5}')
            info "Disk usage /tmp: ${disk_usage}"
        fi
        
        sleep 1
    done
    
    wait $stress_pid
    
    # Очищаем временные файлы
    rm -rf "$temp_dir"
    log "Disk I/O стресс тест завершен"
}

# Сетевая нагрузка на приложение
network_stress_test() {
    local duration=${1:-60}
    local requests_per_second=${2:-10}
    
    log "Запуск Network нагрузочного теста..."
    info "Длительность: ${duration}с, RPS: ${requests_per_second}"
    
    local app_url="http://localhost:8000"
    local total_requests=$((duration * requests_per_second))
    local interval=$(echo "scale=2; 1 / $requests_per_second" | bc -l)
    
    log "Отправка $total_requests запросов к $app_url"
    
    # Счетчики
    local success_count=0
    local error_count=0
    
    for ((i=1; i<=total_requests; i++)); do
        # Отправляем запрос
        if curl -s -o /dev/null -w "%{http_code}" "$app_url" | grep -q "200"; then
            ((success_count++))
        else
            ((error_count++))
        fi
        
        # Показываем прогресс каждые 50 запросов
        if (( i % 50 == 0 )); then
            info "Отправлено: $i/$total_requests, Успешно: $success_count, Ошибок: $error_count"
        fi
        
        # Ждем перед следующим запросом
        sleep "$interval"
    done
    
    log "Network стресс тест завершен"
    log "Итого - Успешно: $success_count, Ошибок: $error_count"
}

# Комбинированный стресс тест
combined_stress_test() {
    local duration=${1:-120}
    
    log "Запуск комбинированного стресс теста..."
    info "Длительность: ${duration}с"
    
    # Запускаем все виды нагрузки параллельно
    cpu_stress_test "$duration" 1 &
    local cpu_pid=$!
    
    sleep 5
    memory_stress_test "$duration" 256 &
    local mem_pid=$!
    
    sleep 5  
    disk_stress_test "$duration" 1 &
    local disk_pid=$!
    
    sleep 5
    network_stress_test "$duration" 5 &
    local net_pid=$!
    
    log "Все стресс тесты запущены параллельно"
    info "CPU PID: $cpu_pid, Memory PID: $mem_pid, Disk PID: $disk_pid, Network PID: $net_pid"
    
    # Ждем завершения всех тестов
    wait $cpu_pid $mem_pid $disk_pid $net_pid
    
    log "Комбинированный стресс тест завершен"
}

# Проверка алертов
check_alerts() {
    log "Проверка статуса алертов..."
    
    # Проверяем Prometheus алерты
    if curl -s http://localhost:9090/api/v1/alerts > /dev/null; then
        alerts=$(curl -s http://localhost:9090/api/v1/alerts | grep -o '"state":"[^"]*"' | sort | uniq -c)
        log "Статус алертов в Prometheus:"
        echo "$alerts" | while read -r count state; do
            info "  $state: $count"
        done
    else
        error "Не удается получить алерты из Prometheus"
    fi
    
    # Проверяем Alertmanager
    if curl -s http://localhost:9093/api/v1/alerts > /dev/null; then
        am_alerts=$(curl -s http://localhost:9093/api/v1/alerts | grep -o '"status":"[^"]*"' | sort | uniq -c)
        log "Статус алертов в Alertmanager:"
        echo "$am_alerts" | while read -r count status; do
            info "  $status: $count"
        done
    else
        error "Не удается получить алерты из Alertmanager"
    fi
}

# Показать меню
show_menu() {
    echo ""
    echo "🔥 НАГРУЗОЧНЫЕ ТЕСТЫ ДЛЯ АЛЕРТИНГА"
    echo "=================================="
    echo "1. CPU стресс тест (60с)"
    echo "2. Memory стресс тест (60с)" 
    echo "3. Disk I/O стресс тест (60с)"
    echo "4. Network стресс тест (60с)"
    echo "5. Комбинированный тест (120с)"
    echo "6. Проверить алерты"
    echo "7. Кастомный тест"
    echo "0. Выход"
    echo ""
}

# Кастомный тест
custom_test() {
    echo ""
    echo "Кастомный тест:"
    read -p "Длительность (сек): " duration
    read -p "Тип (cpu/memory/disk/network/combined): " test_type
    
    case $test_type in
        cpu)
            read -p "Количество ядер: " cores
            cpu_stress_test "$duration" "$cores"
            ;;
        memory)
            read -p "Память (MB): " memory
            memory_stress_test "$duration" "$memory"
            ;;
        disk)
            read -p "Workers: " workers
            disk_stress_test "$duration" "$workers"
            ;;
        network)
            read -p "RPS: " rps
            network_stress_test "$duration" "$rps"
            ;;
        combined)
            combined_stress_test "$duration"
            ;;
        *)
            error "Неизвестный тип теста: $test_type"
            ;;
    esac
}

# Основная функция
main() {
    log "Инициализация нагрузочного тестирования"
    
    check_dependencies
    
    if [ $# -eq 0 ]; then
        # Интерактивный режим
        while true; do
            show_menu
            read -p "Выберите опцию: " choice
            
            case $choice in
                1) cpu_stress_test 60 2 ;;
                2) memory_stress_test 60 512 ;;
                3) disk_stress_test 60 2 ;;
                4) network_stress_test 60 10 ;;
                5) combined_stress_test 120 ;;
                6) check_alerts ;;
                7) custom_test ;;
                0) log "Завершение работы"; exit 0 ;;
                *) error "Неверный выбор: $choice" ;;
            esac
            
            echo ""
            read -p "Нажмите Enter для продолжения..."
        done
    else
        # Режим командной строки
        case $1 in
            cpu) cpu_stress_test "${2:-60}" "${3:-2}" ;;
            memory) memory_stress_test "${2:-60}" "${3:-512}" ;;
            disk) disk_stress_test "${2:-60}" "${3:-2}" ;;
            network) network_stress_test "${2:-60}" "${3:-10}" ;;
            combined) combined_stress_test "${2:-120}" ;;
            alerts) check_alerts ;;
            *) 
                echo "Использование: $0 [cpu|memory|disk|network|combined|alerts] [duration] [params]"
                echo "Или запустите без параметров для интерактивного режима"
                exit 1
                ;;
        esac
    fi
}

main "$@"
