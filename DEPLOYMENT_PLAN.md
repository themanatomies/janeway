# Janeway Multi-Press Deployment Plan

## Domain Configuration
- **Primary Domain:** djourns.com
- **Press 1:** press.djourns.com (Press)
- **Press 2:** anotherpress.djourns.com (Another Press)

## Deployment Architecture
- **Hosting:** Code Ocean (Ubuntu 22.04 recommended)
- **Containerization:** Docker & Docker Compose
- **Database:** PostgreSQL 14+
- **Web Server:** Nginx reverse proxy + Gunicorn
- **SSL/HTTPS:** Let's Encrypt (Certbot)
- **Email:** Postfix SMTP server on droplet

## Pre-Deployment Checklist

### 1. Code Ocean Droplet Setup
- [ ] Create Ubuntu 22.04 LTS droplet (4GB RAM minimum)
- [ ] Configure firewall (allow ports 80, 443, 22)
- [ ] SSH key authentication configured
- [ ] Droplet IP address noted

### 2. DNS Configuration (Required Before SSL)
- [ ] Point djourns.com nameservers to Code Ocean's DNS
- [ ] Create DNS A records:
  - `press.djourns.com` → [DROPLET_IP]
  - `anotherpress.djourns.com` → [DROPLET_IP]
  - `@` (optional, root) → [DROPLET_IP]

### 3. Domain Registrar (GoDaddy/similar)
- [ ] Update nameservers to Code Ocean's DNS servers
- [ ] Verify DNS propagation (use `dig` or `nslookup`)

## Deployment Steps

### Phase 1: Initialize Droplet
1. SSH into droplet
2. Run `deployment/01-init-droplet.sh` - installs Docker, Docker Compose, etc.

### Phase 2: Clone Repository & Configure
1. Clone Janeway repository
2. Copy production environment files from local
3. Generate Django SECRET_KEY
4. Configure PostgreSQL credentials

### Phase 3: Database Migration
1. Export local SQLite database
2. Import into PostgreSQL on droplet
3. Run Django migrations
4. Verify data integrity

### Phase 4: SSL/HTTPS Setup
1. Run Certbot to obtain Let's Encrypt certificates for both domains
2. Configure Nginx with SSL certificates
3. Set up automatic certificate renewal

### Phase 5: Start Services
1. Build Docker images
2. Start containers with Docker Compose
3. Verify services are running
4. Test both press domains

## Deployment Scripts Location
See `deployment/` directory for automated setup scripts:
- `01-init-droplet.sh` - Install Docker, dependencies
- `02-deploy.sh` - Clone repo, configure environment
- `03-database-migrate.sh` - Migrate SQLite to PostgreSQL
- `04-ssl-setup.sh` - Configure Let's Encrypt SSL
- `05-start-services.sh` - Start all services

## Important Notes

### Database
- PostgreSQL will be containerized alongside Django
- Database files persist in `/vol/janeway/db/` on droplet
- Backups should be automated (see backup section below)

### Media Files
- Uploaded files persist in `/vol/janeway/src/files/`
- Must be backed up regularly

### Environment Variables
- All sensitive data (credentials, SECRET_KEY) in `.env` file
- Never committed to version control
- Different from local development `.env`

### Backups
- Automated daily PostgreSQL dumps to S3 or local storage
- Media files included in backup
- Retention policy: keep last 14 days

### Monitoring
- Container health checks configured
- Logs accessible via `docker logs`
- Nginx access/error logs at `/var/log/nginx/`

## Post-Deployment Verification

### Test Press 1
```bash
curl -I https://press.djourns.com/
# Should return 200 OK
```

### Test Press 2
```bash
curl -I https://anotherpress.djourns.com/
# Should return 200 OK
```

### Test Press Logo (if migrated with data)
```bash
curl -I https://press.djourns.com/press/cover/
# Should return 200 OK with image file
```

### Test Admin Interface
- Access https://press.djourns.com/manager/
- Verify login works
- Verify journal/article management works

## Rollback Plan
If issues occur:
1. Keep previous Docker images (use git tags)
2. Database backups available for restore
3. Keep DNS records pointing temporarily elsewhere if needed

## Security Considerations
- [ ] Firewall configured to only allow necessary ports
- [ ] SSH key-based authentication only (no passwords)
- [ ] Regular Django `collectstatic` for static files
- [ ] ALLOWED_HOSTS configured properly in Django settings
- [ ] DEBUG = False in production
- [ ] CSRF protection enabled
- [ ] Secure cookies configured

## Next Steps
1. Create Code Ocean droplet
2. Configure DNS (A records for both subdomains)
3. Run deployment scripts in order
4. Verify all services working
5. Point live traffic to droplet

---
**Last Updated:** 2026-03-08
**Status:** Planning Phase
