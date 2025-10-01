#!/bin/bash

# Complete setup script for Telegram alerting system
# This script automates the entire process from bot creation to testing

set -e

echo "🚀 Complete Telegram Alerting Setup"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Docker and Docker Compose are available"

# Step 1: Setup Telegram Bot
print_status "Step 1: Setting up Telegram Bot..."
if [ -f "infra/monitoring/setup-telegram-bot.sh" ]; then
    chmod +x infra/monitoring/setup-telegram-bot.sh
    ./infra/monitoring/setup-telegram-bot.sh
else
    print_error "Telegram bot setup script not found"
    exit 1
fi

# Step 2: Check if .env file exists and has proper values
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please run the Telegram bot setup first."
    exit 1
fi

if grep -q "your_bot_token_here" .env || grep -q "your_chat_id_here" .env; then
    print_error ".env file contains placeholder values. Please configure your Telegram bot credentials first."
    exit 1
fi

print_success ".env file is properly configured"

# Step 3: Stop existing containers
print_status "Step 2: Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Step 4: Start the monitoring stack with alerting
print_status "Step 3: Starting monitoring stack with alerting..."
docker-compose up -d

# Step 5: Wait for services to start
print_status "Step 4: Waiting for services to start..."
sleep 30

# Step 6: Check service health
print_status "Step 5: Checking service health..."

services=("app" "nginx" "prometheus" "alertmanager" "grafana" "loki" "promtail" "node-exporter")

for service in "${services[@]}"; do
    if docker-compose ps | grep -q "$service.*Up"; then
        print_success "$service is running"
    else
        print_error "$service is not running"
        print_status "Checking logs for $service..."
        docker-compose logs "$service" | tail -20
    fi
done

# Step 7: Test the alerting system
print_status "Step 6: Testing the alerting system..."

if [ -f "infra/monitoring/test-alerts.sh" ]; then
    chmod +x infra/monitoring/test-alerts.sh
    ./infra/monitoring/test-alerts.sh
else
    print_warning "Test alerts script not found, skipping automated testing"
fi

# Step 8: Display completion information
echo ""
echo "🎉 Telegram Alerting Setup Complete!"
echo "===================================="
echo ""
print_success "All services are running and configured!"
echo ""
print_status "Access URLs:"
echo "   • Main Site: https://pishchik-dev.tech/"
echo "   • Grafana: https://pishchik-dev.tech/grafana/"
echo "   • Prometheus: https://pishchik-dev.tech/prometheus/"
echo "   • Alertmanager: https://pishchik-dev.tech/alertmanager/"
echo "   • Loki: https://pishchik-dev.tech/loki/"
echo ""
print_status "Alert Types Configured:"
echo "   • 🚨 Critical: Application down, Prometheus down, Disk space low, Backup failed"
echo "   • ⚠️ Warning: Memory usage, CPU usage, Grafana down, Loki down, Disk I/O, Network issues"
echo "   • ℹ️ Info: General information alerts"
echo ""
print_status "Management Commands:"
echo "   • View logs: docker-compose logs -f"
echo "   • Restart services: docker-compose restart"
echo "   • Stop services: docker-compose down"
echo "   • Update services: docker-compose pull && docker-compose up -d"
echo ""
print_status "Testing Commands:"
echo "   • Test alerts: ./infra/monitoring/test-alerts.sh"
echo "   • Manual alert: curl -X POST http://localhost:9093/api/v1/alerts -H 'Content-Type: application/json' -d '[{\"labels\":{\"alertname\":\"TestAlert\",\"severity\":\"warning\"},\"annotations\":{\"summary\":\"Test alert\"}}]'"
echo ""
print_warning "Check your Telegram chat for test notifications!"
print_success "Happy monitoring! 🚀"
