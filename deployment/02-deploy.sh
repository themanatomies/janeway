#!/bin/bash
# deployment/02-deploy.sh
# Deploy Janeway to Code Ocean droplet
# Run as: bash 02-deploy.sh <github_repo_url> <droplet_ip_or_domain>

set -e

if [ $# -lt 2 ]; then
    echo "Usage: bash 02-deploy.sh <github_repo_url> <droplet_ip_or_domain>"
    echo "Example: bash 02-deploy.sh https://github.com/themanatomies/janeway.git 192.168.1.100"
    exit 1
fi

REPO_URL="$1"
DROPLET_HOST="$2"

echo "=== Janeway Deployment to Code Ocean ==="
echo "Repository: $REPO_URL"
echo "Target Host: $DROPLET_HOST"
echo ""

# SSH into droplet and run deployment
ssh -v "root@$DROPLET_HOST" <<'REMOTE_SCRIPT'

set -e

cd /vol/janeway

echo "1. Cloning repository..."
if [ ! -d "janeway" ]; then
    git clone https://github.com/themanatomies/janeway.git janeway
    cd janeway
else
    cd janeway
    git pull origin master
fi

echo "2. Creating necessary directories..."
mkdir -p /vol/janeway/logs
mkdir -p /vol/janeway/nginx/ssl
mkdir -p /vol/janeway/backups

echo "3. Copying production environment file..."
if [ ! -f ".env.prod" ]; then
    cp deployment/.env.prod.example .env.prod
    echo ""
    echo "⚠️  IMPORTANT: Edit .env.prod with your production values:"
    echo "   - SECRET_KEY (generate a new one)"
    echo "   - DB_PASSWORD"
    echo "   - Email credentials"
    echo ""
    echo "Edit with: nano .env.prod"
    echo "Then run: bash deployment/02-deploy-continue.sh"
    exit 0
fi

echo "4. Creating Nginx configuration..."
mkdir -p /vol/janeway/nginx/conf.d

if [ ! -f "/vol/janeway/nginx/conf.d/janeway.conf" ]; then
    cp deployment/nginx/conf.d/janeway.conf /vol/janeway/nginx/conf.d/
fi

echo "5. Building Docker images..."
docker compose -f deployment/docker-compose.prod.yml build

echo "6. Starting services..."
docker compose -f deployment/docker-compose.prod.yml up -d

echo "7. Waiting for services to be ready..."
sleep 10

echo "8. Running database migrations..."
docker compose -f deployment/docker-compose.prod.yml exec -T janeway-web python src/manage.py migrate

echo "9. Collecting static files..."
docker compose -f deployment/docker-compose.prod.yml exec -T janeway-web python src/manage.py collectstatic --noinput

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Next steps:"
echo "1. Configure DNS A records for your domains (see DEPLOYMENT_PLAN.md)"
echo "2. Run: bash deployment/04-ssl-setup.sh"
echo "3. Test: curl https://press.djourns.com"
echo ""

REMOTE_SCRIPT

echo "Script completed successfully!"
