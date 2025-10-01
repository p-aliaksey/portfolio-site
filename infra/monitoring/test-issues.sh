#!/bin/bash

# Script to test and diagnose issues with the monitoring stack
# Usage: ./test-issues.sh

set -e

echo "🔍 Testing Monitoring Stack Issues"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_status "WARNING" "This script should be run with sudo for full functionality"
fi

echo ""
print_status "INFO" "Checking Docker containers status..."

# Check container status
containers=("app" "nginx" "prometheus" "alertmanager" "grafana" "loki" "promtail" "node-exporter" "certbot")

for container in "${containers[@]}"; do
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
        status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{print $2}')
        if [[ $status == *"Up"* ]]; then
            print_status "OK" "$container is running"
        else
            print_status "ERROR" "$container is not running properly: $status"
        fi
    else
        print_status "ERROR" "$container is not running"
    fi
done

echo ""
print_status "INFO" "Checking container logs for errors..."

# Check Prometheus logs
echo ""
print_status "INFO" "Prometheus logs:"
if docker logs prometheus 2>&1 | grep -i error; then
    print_status "ERROR" "Prometheus has errors in logs"
else
    print_status "OK" "Prometheus logs look clean"
fi

# Check Alertmanager logs
echo ""
print_status "INFO" "Alertmanager logs:"
if docker logs alertmanager 2>&1 | grep -i error; then
    print_status "ERROR" "Alertmanager has errors in logs"
else
    print_status "OK" "Alertmanager logs look clean"
fi

# Check Nginx logs
echo ""
print_status "INFO" "Nginx logs:"
if docker logs nginx 2>&1 | grep -i error; then
    print_status "ERROR" "Nginx has errors in logs"
else
    print_status "OK" "Nginx logs look clean"
fi

echo ""
print_status "INFO" "Testing service connectivity..."

# Test Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
    print_status "OK" "Prometheus is responding on port 9090"
else
    print_status "ERROR" "Prometheus is not responding on port 9090"
fi

# Test Alertmanager
if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
    print_status "OK" "Alertmanager is responding on port 9093"
else
    print_status "ERROR" "Alertmanager is not responding on port 9093"
fi

# Test Grafana
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    print_status "OK" "Grafana is responding on port 3000"
else
    print_status "ERROR" "Grafana is not responding on port 3000"
fi

# Test Loki
if curl -s http://localhost:3100/ready > /dev/null 2>&1; then
    print_status "OK" "Loki is responding on port 3100"
else
    print_status "ERROR" "Loki is not responding on port 3100"
fi

# Test Application
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    print_status "OK" "Application is responding on port 8000"
else
    print_status "ERROR" "Application is not responding on port 8000"
fi

echo ""
print_status "INFO" "Checking configuration files..."

# Check if configuration files exist and are valid
config_files=(
    "/opt/devops-portfolio/infra/monitoring/prometheus/prometheus.yml"
    "/opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml"
    "/opt/devops-portfolio/infra/monitoring/prometheus/rules/alerts.yml"
    "/opt/devops-portfolio/infra/nginx/nginx.conf"
)

for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ]; then
        print_status "OK" "Configuration file exists: $config_file"
        
        # Check if it's a valid YAML file
        if [[ $config_file == *.yml ]] || [[ $config_file == *.yaml ]]; then
            if python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
                print_status "OK" "YAML syntax is valid: $config_file"
            else
                print_status "ERROR" "YAML syntax error in: $config_file"
            fi
        fi
    else
        print_status "ERROR" "Configuration file missing: $config_file"
    fi
done

echo ""
print_status "INFO" "Checking Docker Compose configuration..."

# Check if docker-compose.yml is valid
if [ -f "/opt/devops-portfolio/docker-compose.yml" ]; then
    if docker compose -f /opt/devops-portfolio/docker-compose.yml config > /dev/null 2>&1; then
        print_status "OK" "Docker Compose configuration is valid"
    else
        print_status "ERROR" "Docker Compose configuration has errors"
    fi
else
    print_status "ERROR" "Docker Compose file not found"
fi

echo ""
print_status "INFO" "Checking system resources..."

# Check disk space
disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -lt 80 ]; then
    print_status "OK" "Disk usage is ${disk_usage}% (OK)"
elif [ "$disk_usage" -lt 90 ]; then
    print_status "WARNING" "Disk usage is ${disk_usage}% (Warning)"
else
    print_status "ERROR" "Disk usage is ${disk_usage}% (Critical)"
fi

# Check memory usage
memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$memory_usage" -lt 80 ]; then
    print_status "OK" "Memory usage is ${memory_usage}% (OK)"
elif [ "$memory_usage" -lt 90 ]; then
    print_status "WARNING" "Memory usage is ${memory_usage}% (Warning)"
else
    print_status "ERROR" "Memory usage is ${memory_usage}% (Critical)"
fi

echo ""
print_status "INFO" "Checking network connectivity..."

# Check if ports are accessible
ports=(8000 3000 9090 9093 3100 9100)
for port in "${ports[@]}"; do
    if netstat -tuln | grep -q ":$port "; then
        print_status "OK" "Port $port is listening"
    else
        print_status "ERROR" "Port $port is not listening"
    fi
done

echo ""
print_status "INFO" "Testing external access..."

# Test external URLs (if domain is configured)
domain="pishchik-dev.tech"
if curl -s --max-time 10 "https://$domain" > /dev/null 2>&1; then
    print_status "OK" "External access to $domain is working"
else
    print_status "WARNING" "External access to $domain is not working (may be normal if not configured)"
fi

echo ""
print_status "INFO" "Summary of issues found:"

# Count issues
error_count=$(grep -c "❌" <<< "$(docker ps -a --format 'table {{.Status}}' | grep -v Up)")
warning_count=$(grep -c "⚠️" <<< "$(df / | awk 'NR==2 {print $5}' | sed 's/%//' | awk '{if($1>80) print "warning"}')")

if [ "$error_count" -eq 0 ] && [ "$warning_count" -eq 0 ]; then
    print_status "OK" "No critical issues found! System appears to be running normally."
else
    print_status "WARNING" "Found $error_count errors and $warning_count warnings. Please review the output above."
fi

echo ""
print_status "INFO" "To fix common issues:"
echo "1. Restart failed containers: docker compose -f /opt/devops-portfolio/docker-compose.yml restart"
echo "2. Check logs: docker logs <container_name>"
echo "3. Update Alertmanager config: /opt/devops-portfolio/update-alertmanager-config.sh <bot_token> <chat_id>"
echo "4. Rebuild and restart all: docker compose -f /opt/devops-portfolio/docker-compose.yml down && docker compose -f /opt/devops-portfolio/docker-compose.yml up -d"

echo ""
print_status "INFO" "Test completed!"
