#!/bin/bash
# deployment/05-finalize-production.sh
# Final production deployment script
# Deploys environment config and restarts containers

set -e

DROPLET_IP=${1:-159.65.249.138}
REPO_PATH="/vol/janeway/janeway"

echo "🚀 Starting final production deployment..."

# Deploy .env.prod
echo "📋 Deploying environment configuration..."
scp deployment/.env.prod root@$DROPLET_IP:$REPO_PATH/.env.prod

# Restart containers with proper env
echo "🔄 Restarting containers with environment configuration..."
ssh root@$DROPLET_IP "cd $REPO_PATH && docker-compose -f deployment/docker-compose.prod.yml --env-file .env.prod down janeway-web && docker-compose -f deployment/docker-compose.prod.yml --env-file .env.prod up -d janeway-web"

echo "⏳ Waiting for application startup..."
sleep 5

# Check logs
echo "📊 Application logs:"
ssh root@$DROPLET_IP "cd $REPO_PATH && docker-compose -f deployment/docker-compose.prod.yml logs --tail=10 janeway-web"

# Test endpoints
echo ""
echo "🧪 Testing HTTPS endpoints..."
echo "Testing https://press.djourns.com..."
curl -s -I https://press.djourns.com | head -5
echo ""
echo "Testing https://anotherpress.djourns.com..."
curl -s -I https://anotherpress.djourns.com | head -5

echo ""
echo "✅ Production deployment finalized!"
