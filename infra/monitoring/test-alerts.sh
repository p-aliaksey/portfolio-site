#!/bin/bash

# Script to test the alerting system
# This script creates various test alerts to verify Telegram integration

set -e

echo "🧪 Testing Alerting System"
echo "=========================="
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

# Check if Alertmanager is running
if ! curl -s http://localhost:9093/api/v1/status > /dev/null; then
    print_error "Alertmanager is not running. Please start the monitoring stack first."
    print_status "Run: docker-compose up -d"
    exit 1
fi

print_success "Alertmanager is running"

# Function to create test alert
create_test_alert() {
    local alert_name="$1"
    local severity="$2"
    local summary="$3"
    local description="$4"
    local instance="${5:-test-instance}"
    
    print_status "Creating test alert: $alert_name"
    
    local alert_json=$(cat << EOF
[
  {
    "labels": {
      "alertname": "$alert_name",
      "severity": "$severity",
      "instance": "$instance",
      "service": "test-service"
    },
    "annotations": {
      "summary": "$summary",
      "description": "$description"
    }
  }
]
EOF
)
    
    if curl -s -X POST http://localhost:9093/api/v1/alerts \
        -H "Content-Type: application/json" \
        -d "$alert_json" > /dev/null; then
        print_success "Test alert '$alert_name' created successfully"
    else
        print_error "Failed to create test alert '$alert_name'"
    fi
}

# Test critical alerts
echo "🚨 Testing Critical Alerts"
echo "-------------------------"
create_test_alert "TestCriticalAlert" "critical" "Critical test alert" "This is a test critical alert to verify immediate notification"
sleep 2

# Test warning alerts
echo ""
echo "⚠️ Testing Warning Alerts"
echo "------------------------"
create_test_alert "TestWarningAlert" "warning" "Warning test alert" "This is a test warning alert to verify grouped notification"
sleep 2

# Test info alerts
echo ""
echo "ℹ️ Testing Info Alerts"
echo "---------------------"
create_test_alert "TestInfoAlert" "info" "Info test alert" "This is a test info alert to verify less frequent notification"
sleep 2

# Test application-specific alerts
echo ""
echo "📱 Testing Application Alerts"
echo "----------------------------"
create_test_alert "TestApplicationDown" "critical" "Application is down" "Test application down alert"
sleep 2

create_test_alert "TestHighMemoryUsage" "warning" "High memory usage detected" "Memory usage is 85% of the limit"
sleep 2

create_test_alert "TestHighCPUUsage" "warning" "High CPU usage detected" "CPU usage is 90%"
sleep 2

# Test infrastructure alerts
echo ""
echo "🏗️ Testing Infrastructure Alerts"
echo "-------------------------------"
create_test_alert "TestPrometheusDown" "critical" "Prometheus is down" "Prometheus monitoring system is not responding"
sleep 2

create_test_alert "TestGrafanaDown" "warning" "Grafana is down" "Grafana dashboard is not accessible"
sleep 2

create_test_alert "TestLokiDown" "warning" "Loki is down" "Loki logging system is not responding"
sleep 2

# Test system alerts
echo ""
echo "💻 Testing System Alerts"
echo "-----------------------"
create_test_alert "TestDiskSpaceLow" "critical" "Disk space is low" "Disk space is 95% full"
sleep 2

create_test_alert "TestHighDiskIO" "warning" "High disk I/O detected" "Disk I/O is 80%"
sleep 2

create_test_alert "TestNetworkIssues" "warning" "Network connectivity issues" "Network receive errors rate is 0.5 per second"
sleep 2

# Test backup alerts
echo ""
echo "💾 Testing Backup Alerts"
echo "-----------------------"
create_test_alert "TestBackupFailed" "critical" "Backup failed" "Backup has failed in the last 24 hours"
sleep 2

create_test_alert "TestBackupNotRun" "warning" "Backup not run" "Backup has not been run for more than 24 hours"
sleep 2

create_test_alert "TestBackupSizeTooSmall" "warning" "Backup size too small" "Backup size is only 500KB, possible issue"
sleep 2

# Test multiple alerts in group
echo ""
echo "📦 Testing Alert Grouping"
echo "-------------------------"
create_test_alert "TestGroupAlert1" "warning" "Group test alert 1" "First alert in group"
sleep 1
create_test_alert "TestGroupAlert2" "warning" "Group test alert 2" "Second alert in group"
sleep 1
create_test_alert "TestGroupAlert3" "warning" "Group test alert 3" "Third alert in group"

echo ""
echo "🎉 Test Alerts Created!"
echo "======================"
echo ""
print_warning "Check your Telegram chat for the test alerts"
print_status "You should receive:"
echo "   • 1 critical alert (immediate notification)"
echo "   • 1 warning alert (grouped notification)"
echo "   • 1 info alert (less frequent notification)"
echo "   • Multiple application, infrastructure, and system alerts"
echo "   • 3 grouped warning alerts"
echo ""
print_status "Alert types sent:"
echo "   • Critical: Application down, Prometheus down, Disk space low, Backup failed"
echo "   • Warning: Memory usage, CPU usage, Grafana down, Loki down, Disk I/O, Network issues, Backup issues"
echo "   • Info: General info alert"
echo ""
print_status "To view active alerts:"
echo "   • Alertmanager: http://localhost:9093/"
echo "   • Prometheus: http://localhost:9090/alerts"
echo ""
print_status "To clear test alerts:"
echo "   • Restart Alertmanager: docker-compose restart alertmanager"
echo "   • Or wait for alerts to expire (they will auto-resolve)"
echo ""
print_success "Test completed! Check your Telegram chat for notifications 🚀"
