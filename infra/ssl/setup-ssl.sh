#!/bin/bash

echo "=== НАСТРОЙКА SSL СЕРТИФИКАТОВ ==="

DOMAIN="pishchik-dev.tech"
EMAIL="admin@pishchik-dev.tech"

echo "1. Создаем директории для Let's Encrypt:"
sudo mkdir -p /etc/letsencrypt/live
sudo mkdir -p /etc/letsencrypt/archive

echo "2. Запускаем временный Nginx для получения сертификатов:"
docker run -d \
  --name nginx-temp \
  -p 80:80 \
  -v $(pwd)/infra/nginx/webroot:/var/www/certbot:ro \
  -v $(pwd)/infra/nginx/nginx-http.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:1.27-alpine

echo "3. Ждем запуска Nginx (5 секунд):"
sleep 5

echo "4. Получаем SSL сертификаты:"
docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v $(pwd)/infra/nginx/webroot:/var/www/certbot \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email $EMAIL \
  --agree-tos \
  --no-eff-email \
  -d $DOMAIN \
  -d www.$DOMAIN

echo "5. Останавливаем временный Nginx:"
docker stop nginx-temp
docker rm nginx-temp

echo "6. Проверяем сертификаты:"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL сертификаты успешно получены!"
    ls -la /etc/letsencrypt/live/$DOMAIN/
else
    echo "❌ Ошибка получения SSL сертификатов"
    exit 1
fi

echo "7. Настраиваем автообновление сертификатов:"
echo "0 12 * * * /usr/bin/docker run --rm -v /etc/letsencrypt:/etc/letsencrypt certbot/certbot renew --quiet" | sudo crontab -

echo "=== НАСТРОЙКА SSL ЗАВЕРШЕНА ==="
