#!/bin/bash

# Script to update Alertmanager configuration with real Telegram credentials
# Usage: ./update-alertmanager-config.sh <bot_token> <chat_id>

set -e

BOT_TOKEN=${1:-"your_bot_token_here"}
CHAT_ID=${2:-"your_chat_id_here"}

if [ "$BOT_TOKEN" = "your_bot_token_here" ] || [ "$CHAT_ID" = "your_chat_id_here" ]; then
    echo "❌ Error: Please provide valid bot token and chat ID"
    echo "Usage: $0 <bot_token> <chat_id>"
    echo "Example: $0 123456789:ABCdefGHIjklMNOpqrsTUVwxyz 987654321"
    exit 1
fi

ALERTMANAGER_CONFIG="/opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml"

if [ ! -f "$ALERTMANAGER_CONFIG" ]; then
    echo "❌ Error: Alertmanager config file not found at $ALERTMANAGER_CONFIG"
    exit 1
fi

echo "🔄 Updating Alertmanager configuration..."

# Create backup
cp "$ALERTMANAGER_CONFIG" "${ALERTMANAGER_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

# Update bot token and chat ID in the config file
sed -i "s/your_bot_token_here/$BOT_TOKEN/g" "$ALERTMANAGER_CONFIG"
sed -i "s/your_chat_id_here/$CHAT_ID/g" "$ALERTMANAGER_CONFIG"

echo "✅ Alertmanager configuration updated successfully!"

# Restart Alertmanager container
echo "🔄 Restarting Alertmanager container..."
docker compose -f /opt/devops-portfolio/docker-compose.yml restart alertmanager

# Wait for Alertmanager to start
echo "⏳ Waiting for Alertmanager to start..."
sleep 10

# Check if Alertmanager is running
if docker ps | grep -q alertmanager; then
    echo "✅ Alertmanager is running successfully!"
    echo "🌐 Access Alertmanager at: https://pishchik-dev.tech/alertmanager/"
else
    echo "❌ Alertmanager failed to start. Check logs:"
    docker logs alertmanager
    exit 1
fi

echo "🎉 Telegram alerting is now configured!"
echo "📱 Test alerts will be sent to your Telegram chat."
