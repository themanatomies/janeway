# Janeway Production Deployment

This directory contains all scripts and configurations for deploying Janeway to a Code Ocean droplet.

## Quick Start

### 1. Prerequisites
- Code Ocean account with ability to create droplets
- djourns.com domain registered
- SSH access to your local machine

### 2. Create Code Ocean Droplet
- Create Ubuntu 22.04 LTS droplet (4GB RAM minimum)
- Note the public IP address
- Configure SSH key authentication

### 3. Run Deployment Scripts

**On the droplet (via SSH):**

```bash
# Step 1: Initialize droplet with Docker and dependencies
bash deployment/01-init-droplet.sh

# Step 2: Deploy application
bash deployment/02-deploy.sh https://github.com/themanatomies/janeway.git

# Step 3: Configure DNS (see DNS_SETUP.md)
# Wait for DNS to propagate (24-48 hours)

# Step 4: Setup SSL/HTTPS
bash deployment/04-ssl-setup.sh admin@djourns.com
```

**From your local machine:**

```bash
# Step 3: Migrate database and files
bash deployment/03-database-migrate.sh root@[DROPLET_IP]
```

## Files in This Directory

| File | Purpose |
|------|---------|
| `01-init-droplet.sh` | Initialize droplet with Docker, Docker Compose, dependencies |
| `02-deploy.sh` | Clone repository, configure environment, start services |
| `03-database-migrate.sh` | Migrate SQLite database and files to production PostgreSQL |
| `04-ssl-setup.sh` | Configure Let's Encrypt SSL certificates |
| `docker-compose.prod.yml` | Production Docker Compose configuration |
| `.env.prod.example` | Environment variables template |
| `nginx/conf.d/janeway.conf` | Nginx reverse proxy configuration for multi-domain setup |
| `DNS_SETUP.md` | Guide for configuring DNS with registrar and Code Ocean |

## Environment Configuration

1. Copy template:
   ```bash
   cp deployment/.env.prod.example deployment/.env.prod
   ```

2. Edit with production values:
   ```bash
   nano deployment/.env.prod
   ```

3. Keep `.env.prod` safe - it contains secrets
   Never commit to version control

## DNS Configuration

See `DNS_SETUP.md` for detailed instructions on:
- Updating nameservers at your registrar
- Adding DNS A records in Code Ocean
- Verifying DNS propagation
- Troubleshooting DNS issues

## Domains

The deployment configures:
- **press.djourns.com** → Press (ID 3)
- **anotherpress.djourns.com** → Another Press (ID 6)

Both domains:
- Use same PostgreSQL database
- Share uploaded files and media
- Have independent admin interfaces
- Use same SSL certificate (or separate per-domain)

## Database

- **Local (development):** SQLite at `db/janeway.sqlite3`
- **Production:** PostgreSQL in Docker container
- Migration: Use `03-database-migrate.sh` to transfer data

## SSL/HTTPS

- Automatic SSL with Let's Encrypt
- Separate certificates per domain
- Auto-renews 30 days before expiration
- Add renewal cron job after setup

## Backups

Create a backup strategy:
- Daily PostgreSQL dumps to `/vol/janeway/backups/`
- Keep minimum 14 days retention
- Optional S3 storage for off-site backup

Sample backup script (add to crontab):
```bash
0 3 * * * docker exec janeway-postgres pg_dump -U janeway janeway | gzip > /vol/janeway/backups/janeway_$(date +\%Y\%m\%d).sql.gz
```

## Monitoring

Check service health:
```bash
# View running containers
docker ps

# Check container logs
docker logs janeway-web
docker logs janeway-nginx
docker logs janeway-postgres

# Check Nginx status
docker exec janeway-nginx nginx -t

# View current configuration
docker exec janeway-nginx cat /etc/nginx/conf.d/janeway.conf
```

## Troubleshooting

### Services Won't Start
```bash
docker compose -f deployment/docker-compose.prod.yml logs janeway-web
```

### Nginx Connection Issues
```bash
docker exec janeway-nginx nginx -t  # Test configuration
docker logs janeway-nginx  # View logs
```

### Database Connection Problems
```bash
docker exec janeway-postgres psql -U janeway -d janeway -c "SELECT version();"
```

### SSL Certificate Issues
```bash
docker exec janeway-nginx ls -la /etc/nginx/ssl/
docker volume inspect janeway_certbot_data
```

## Updating Production

To update the application:
```bash
cd /vol/janeway/janeway
git pull origin master
docker compose -f deployment/docker-compose.prod.yml build janeway-web
docker compose -f deployment/docker-compose.prod.yml up -d janeway-web
docker compose -f deployment/docker-compose.prod.yml exec janeway-web python src/manage.py migrate
```

## Rollback

If something breaks:
```bash
# View recent commits
git log --oneline -10

# Checkout previous version
git checkout [COMMIT_HASH]

# Rebuild and restart
docker compose -f deployment/docker-compose.prod.yml build
docker compose -f deployment/docker-compose.prod.yml up -d
```

Database backups available at: `/vol/janeway/backups/`

## Security Reminders

- [ ] DEBUG = False in production
- [ ] SECRET_KEY is unique and complex
- [ ] Database password is strong
- [ ] SSH keys only, no password authentication
- [ ] Firewall configured (port 22, 80, 443 only)
- [ ] Regular backups stored securely
- [ ] SSL certificates auto-renewing
- [ ] Nginx security headers configured

## Support

For issues:
1. Check deployment logs: `docker logs [container_name]`
2. Review DEPLOYMENT_PLAN.md
3. Check DNS_SETUP.md for domain issues
4. Look at Nginx configuration: `deployment/nginx/conf.d/janeway.conf`

See root `DEPLOYMENT_PLAN.md` for complete deployment guide.
