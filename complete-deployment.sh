#!/bin/bash
#  Complete the production deployment
# Run: bash complete-deployment.sh

DROPLET="root@159.65.249.138"
REPO_PATH="/vol/janeway/janeway"

echo "🚀 Completing Janeway production deployment..."

# Create env file directly on droplet
ssh "$DROPLET" << 'EOSSH'
cat > /vol/janeway/janeway/.env.prod << 'EOF'
DEBUG=False
SECRET_KEY=CjmCBIrc07yI5gCLzXZa48WqZuLHAgPF28D0rl8sGOy1rmuKL8z_9NRnxImxFhcDk1U
DB_VENDOR=postgres
DB_NAME=janeway
DB_USER=janeway
DB_PASSWORD=slides-e9gg-terr!fic
DB_HOST=postgres
DB_PORT=5432
ALLOWED_HOSTS=press.djourns.com,anotherpress.djourns.com,www.djourns.com
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=localhost
EMAIL_PORT=25
DEFAULT_FROM_EMAIL=noreply@djourns.com
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
EOF

echo "✅ Environment file created"

cd /vol/janeway/janeway

# pull latest code
echo "📦 Pulling latest code..."
git pull origin master

# Restart application with environment file
echo "🔄 Restarting application..."
docker-compose -f deployment/docker-compose.prod.yml --env-file .env.prod down janeway-web 2>/dev/null || true
docker-compose -f deployment/docker-compose.prod.yml --env-file .env.prod up -d janeway-web

# Wait and check
echo "⏳ Waiting for application startup..."
sleep 5

echo "📊 Application status:"
docker ps | grep janeway-web

echo ""
echo "📋 Latest logs:"
docker logs --tail=15 janeway-web

EOSSH

echo ""
echo "🧪 Testing HTTPS endpoints..."
curl -s -I https://press.djourns.com/ | head -1
curl -s -I https://anotherpress.djourns.com/ | head -1

echo ""
echo "✅ Deployment complete!"
