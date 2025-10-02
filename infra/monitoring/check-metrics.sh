#!/bin/bash

# Скрипт проверки метрик для дашборда Node Exporter
# Использование: ./check-metrics.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Проверка контейнеров
check_containers() {
    log "Проверка статуса контейнеров..."
    
    containers=("prometheus" "grafana" "node-exporter")
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            log " $container: запущен"
        else
            error " $container: не запущен"
            return 1
        fi
    done
}

# Проверка портов
check_ports() {
    log "Проверка портов..."
    
    if curl -s http://localhost:9100/metrics > /dev/null; then
        log " Node-exporter (9100): доступен"
    else
        error " Node-exporter (9100): недоступен"
    fi
    
    if curl -s http://localhost:9090/api/v1/query?query=up > /dev/null; then
        log " Prometheus (9090): доступен"
    else
        error " Prometheus (9090): недоступен"
    fi
    
    if curl -s http://localhost:3000/api/health > /dev/null; then
        log " Grafana (3000): доступен"
    else
        error " Grafana (3000): недоступен"
    fi
}

# Проверка метрик
check_metrics() {
    log "Проверка основных метрик..."
    
    metrics=(
        "node_cpu_seconds_total"
        "node_memory_MemTotal_bytes"
        "node_memory_MemAvailable_bytes"
        "node_load1"
        "up"
    )
    
    for metric in "${metrics[@]}"; do
        if curl -s "http://localhost:9090/api/v1/query?query=${metric}" | grep -q '"status":"success"'; then
            log " $metric"
        else
            error " $metric"
        fi
    done
}

# Проверка targets
check_targets() {
    log "Проверка targets в Prometheus..."
    
    # Проверяем конкретно node-exporter target
    response=$(curl -s http://localhost:9090/api/v1/targets)
    
    if echo "$response" | grep -q '"job":"node-exporter".*"health":"up"'; then
        log " node-exporter target: UP"
    else
        error " node-exporter target: DOWN"
        log "Детали targets:"
        echo "$response" | grep -o '"job":"[^"]*".*"health":"[^"]*"' | head -5
    fi
    
    # Проверяем общее количество UP targets
    up_count=$(echo "$response" | grep -o '"health":"up"' | wc -l)
    total_count=$(echo "$response" | grep -o '"health":"[^"]*"' | wc -l)
    log " Активных targets: $up_count из $total_count"
}

# Основная функция
main() {
    echo " Диагностика метрик Node Exporter"
    echo "=================================="
    
    check_containers || exit 1
    echo ""
    
    check_ports
    echo ""
    
    check_targets
    echo ""
    
    check_metrics
    echo ""
    
    log "Диагностика завершена!"
    echo ""
    echo " Если есть ошибки:"
    echo "1. Перезапустите контейнеры: docker-compose restart prometheus grafana node-exporter"
    echo "2. Импортируйте исправленный дашборд: infra/monitoring/grafana/dashboards/node-exporter-fixed.json"
    echo "3. Проверьте datasource в Grafana: http://prometheus:9090"
}

main "$@"
