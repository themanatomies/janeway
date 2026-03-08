#!/bin/bash
# deployment/04-ssl-setup.sh
# Configure Let's Encrypt SSL certificates using Certbot
# Run after DNS A records are pointing to droplet and fully propagated

set -e

if [ $# -lt 1 ]; then
    echo "Usage: bash 04-ssl-setup.sh <email_for_letsencrypt>"
    echo "Example: bash 04-ssl-setup.sh admin@example.com"
    exit 1
fi

EMAIL="$1"
DOMAINS="press.djourns.com,anotherpress.djourns.com"

echo "=== Setting up SSL/HTTPS with Let's Encrypt ==="
echo "Email: $EMAIL"
echo "Domains: $DOMAINS"
echo ""
echo "Requirements:"
echo "✓ DNS A records must be pointing to this droplet"
echo "✓ Nginx must be running"
echo "✓ Ports 80 and 443 must be accessible"
echo ""
# Skip user prompt if running in non-interactive mode
if [ -t 0 ]; then
    echo "Press Enter to continue..."
    read
fi

# Ensure Nginx is running
docker ps | grep -q janeway-nginx || {
    echo "Error: Nginx container not running. Start with: cd /vol/janeway/janeway && docker compose --env-file .env.prod -f deployment/docker-compose.prod.yml up -d"
    exit 1
}

# Create SSL directories
sudo mkdir -p /vol/janeway/nginx/ssl
sudo mkdir -p /var/www/certbot
sudo chown -R $USER:$USER /vol/janeway/nginx/ssl

echo "Temporarily stopping Nginx to allow Certbot to use port 80..."
cd /vol/janeway/janeway && docker compose --env-file .env.prod -f deployment/docker-compose.prod.yml stop janeway-nginx

echo "Creating Certbot container..."
docker run --rm \
  -v /vol/janeway/nginx/ssl:/etc/letsencrypt \
  -v /var/www/certbot:/var/www/certbot \
  -p 80:80 -p 443:443 \
  certbot/certbot certonly \
  --standalone \
  --agree-tos \
  --non-interactive \
  --email "$EMAIL" \
  -d press.djourns.com \
  -d anotherpress.djourns.com

echo "Restarting Nginx..."
docker compose -f deployment/docker-compose.prod.yml start janeway-nginx

echo ""
echo "Copying certificates to Nginx..."
sudo mkdir -p /vol/janeway/nginx/ssl/press.djourns.com
sudo mkdir -p /vol/janeway/nginx/ssl/anotherpress.djourns.com

sudo cp /vol/janeway/nginx/ssl/live/press.djourns.com/fullchain.pem /vol/janeway/nginx/ssl/press.djourns.com/
sudo cp /vol/janeway/nginx/ssl/live/press.djourns.com/privkey.pem /vol/janeway/nginx/ssl/press.djourns.com/
sudo cp /vol/janeway/nginx/ssl/live/anotherpress.djourns.com/fullchain.pem /vol/janeway/nginx/ssl/anotherpress.djourns.com/
sudo cp /vol/janeway/nginx/ssl/live/anotherpress.djourns.com/privkey.pem /vol/janeway/nginx/ssl/anotherpress.djourns.com/

sleep 5

echo "Restarting Nginx..."
cd /vol/janeway/janeway && docker compose --env-file .env.prod -f deployment/docker-compose.prod.yml start janeway-nginx

echo ""
echo "=== SSL Setup Complete ==="
echo ""
echo "Testing HTTPS connections..."
echo ""

echo "Testing press.djourns.com..."
curl -I https://press.djourns.com --insecure 2>/dev/null | head -1

echo "Testing anotherpress.djourns.com..."
curl -I https://anotherpress.djourns.com --insecure 2>/dev/null | head -1

echo ""
echo "Setting up automatic certificate renewal..."
echo "Add to crontab (crontab -e):"
echo "0 3 * * * docker run --rm -v /vol/janeway/nginx/ssl:/etc/letsencrypt certbot/certbot renew --quiet"
echo ""
echo "SSL certificates installed successfully!"
