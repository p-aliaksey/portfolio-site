#!/bin/bash

# Script to setup Telegram bot for alerts
# This script helps you create a Telegram bot and get the necessary credentials

echo "🤖 Setting up Telegram Bot for Alerts"
echo "======================================"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Please install jq first:"
    echo "   Ubuntu/Debian: sudo apt-get install jq"
    echo "   CentOS/RHEL: sudo yum install jq"
    echo "   macOS: brew install jq"
    echo "   Windows: Download from https://stedolan.github.io/jq/"
    exit 1
fi

echo "📱 Step 1: Create a Telegram Bot"
echo "1. Open Telegram and search for @BotFather"
echo "2. Send /newbot command"
echo "3. Choose a name for your bot (e.g., 'DevOps Portfolio Alerts')"
echo "4. Choose a username for your bot (e.g., 'devops_portfolio_alerts_bot')"
echo "5. Copy the bot token that BotFather gives you"
echo ""

read -p "Enter your bot token: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    echo "❌ Bot token cannot be empty"
    exit 1
fi

echo ""
echo "🔍 Step 2: Getting your Chat ID"
echo "1. Start a chat with your bot (search for the username you created)"
echo "2. Send any message to the bot (e.g., 'Hello')"
echo "3. Press Enter to continue after sending the message..."

read -p "Press Enter after sending a message to your bot..."

echo "Getting your chat ID..."

# Get updates from the bot
UPDATES=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates")

# Extract chat ID
CHAT_ID=$(echo "$UPDATES" | jq -r '.result[0].message.chat.id')

if [ "$CHAT_ID" = "null" ] || [ -z "$CHAT_ID" ]; then
    echo "❌ Could not get chat ID. Please make sure you sent a message to the bot."
    echo "Raw response: $UPDATES"
    exit 1
fi

echo "✅ Chat ID found: $CHAT_ID"

# Test the bot
echo ""
echo "🧪 Step 3: Testing the bot..."
TEST_MESSAGE="🤖 Test message from DevOps Portfolio setup script!"
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${TEST_MESSAGE}"

if [ $? -eq 0 ]; then
    echo "✅ Test message sent successfully!"
else
    echo "❌ Failed to send test message"
    exit 1
fi

# Create .env file
echo ""
echo "📝 Step 4: Creating .env file..."

cat > .env << EOF
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=${BOT_TOKEN}
TELEGRAM_CHAT_ID=${CHAT_ID}
EOF

echo "✅ .env file created with your bot credentials"

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo "Your Telegram bot is ready to receive alerts!"
echo ""
echo "Next steps:"
echo "1. Run: docker-compose up -d"
echo "2. Check Alertmanager at: https://pishchik-dev.tech/alertmanager"
echo "3. Check Prometheus at: https://pishchik-dev.tech/prometheus"
echo "4. Alerts will be sent to your Telegram chat"
echo ""
echo "To test alerts manually:"
echo "1. Go to Prometheus: https://pishchik-dev.tech/prometheus"
echo "2. Go to 'Alerts' tab"
echo "3. You should see your alert rules"
echo ""
echo "Happy monitoring! 🚀"
