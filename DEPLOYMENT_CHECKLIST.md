# Code Ocean Deployment Checklist

## Pre-Deployment (Local)
- [ ] Review DEPLOYMENT_PLAN.md
- [ ] Domain registered: djourns.com ✓
- [ ] Read deployment/README.md
- [ ] Review DNS_SETUP.md
- [ ] Backup local database: `cp db/janeway.sqlite3 db/janeway.sqlite3.backup`
- [ ] Verify all local tests pass

## Code Ocean Setup
- [ ] Create Ubuntu 22.04 droplet (4GB RAM minimum)
- [ ] Note public IP address: ____________
- [ ] Configure SSH key authentication
- [ ] Test SSH access: `ssh root@[IP_ADDRESS]`
- [ ] SSH into droplet

## Step 1: Initialize Droplet (on droplet via SSH)
```bash
cd /tmp
wget https://raw.githubusercontent.com/themanatomies/janeway/master/deployment/01-init-droplet.sh
bash 01-init-droplet.sh
exit  # Log out and back in to activate docker group
```
- [ ] Initialization completed successfully
- [ ] Docker installed and working: `docker ps`

## Step 2: Deploy Application (on droplet via SSH)
```bash
cd /vol/janeway
bash deployment/02-deploy.sh
# Edit .env.prod with production values
nano .env.prod
```
- [ ] Repository cloned
- [ ] `.env.prod` configured with:
  - [ ] SECRET_KEY (long random string)
  - [ ] DB_PASSWORD (strong password)
  - [ ] EMAIL configuration
- [ ] Docker services starting

## Step 3: Configure DNS (via domain registrar)
See: `deployment/DNS_SETUP.md`

Follow instructions for your registrar:
- [ ] GoDaddy / Namecheap / Other: Update nameservers to Code Ocean
- [ ] Add A records in Code Ocean DNS:
  - [ ] press.djourns.com → [DROPLET_IP]
  - [ ] anotherpress.djourns.com → [DROPLET_IP]
- [ ] Verify DNS propagation (24-48 hours wait typical)

Commands to check:
```bash
dig press.djourns.com A
dig anotherpress.djourns.com A
```

## Step 4: Migrate Database & Files (from local machine)
```bash
bash deployment/03-database-migrate.sh root@[DROPLET_IP]
```
- [ ] Database exported and migrated
- [ ] Media files uploaded
- [ ] Django migrations ran
- [ ] Static files collected

## Step 5: Setup SSL/HTTPS (on droplet via SSH)
```bash
bash deployment/04-ssl-setup.sh admin@djourns.com
```
**IMPORTANT: Run this AFTER DNS is fully propagated**

- [ ] DNS is propagated (verified with `dig`)
- [ ] Certbot created certificates for both domains
- [ ] SSL certificates installed in Nginx
- [ ] Nginx reloaded successfully

## Post-Deployment Testing

### Test HTTP→HTTPS Redirect
```bash
curl -I http://press.djourns.com
# Should show: HTTP/1.1 301 Moved Permanently
# Location: https://press.djourns.com/
```
- [ ] HTTP redirects to HTTPS

### Test HTTPS Connection
```bash
curl -I https://press.djourns.com/
curl -I https://anotherpress.djourns.com/
# Should show: HTTP/1.1 200 OK
```
- [ ] Both domains respond over HTTPS
- [ ] SSL certificates are valid

### Test Web Interface
- [ ] Access https://press.djourns.com in browser
- [ ] Access https://anotherpress.djourns.com in browser
- [ ] Verify home pages load correctly
- [ ] Check press logos display (if data migrated)

### Test Admin/Manager
- [ ] Admin login: https://press.djourns.com/admin/
- [ ] Manager login: https://press.djourns.com/manager/
- [ ] Verify journals and articles visible
- [ ] Test downloading a galley (if data migrated)

### Test Email Configuration
- [ ] Check Postfix running: `docker exec janeway-web ps aux | grep postfix`
- [ ] Send test email from admin interface
- [ ] Verify email received

### Container Health Checks
```bash
docker ps
# All containers should show STATUS: Up ...

docker logs janeway-web
docker logs janeway-postgres
docker logs janeway-nginx
# Check for any ERROR logs
```
- [ ] All containers healthy
- [ ] No error logs in services

## Production Tasks (After Deployment Works)

### Setup Automated Backups
Add to crontab (crontab -e on droplet):
```bash
0 3 * * * docker exec janeway-postgres pg_dump -U janeway janeway | gzip > /vol/janeway/backups/janeway_$(date +\%Y\%m\%d).sql.gz
```
- [ ] Backup cron job configured

### Setup Certificate Renewal
Add to crontab:
```bash
0 3 * * 1 docker run --rm -v /vol/janeway/nginx/ssl:/etc/letsencrypt certbot/certbot renew --quiet
```
- [ ] Certificate renewal cron job configured

### Monitor Regularly
- [ ] Check Docker container status daily or weekly
- [ ] Review Nginx error logs for issues
- [ ] Monitor disk space on droplet
- [ ] Test email delivery periodically
- [ ] Verify backups are created

## Troubleshooting

### Services Won't Start
```bash
docker compose -f deployment/docker-compose.prod.yml logs [service_name]
# Review error messages and .env.prod configuration
```

### DNS Not Resolving
- Verify nameservers updated at registrar (wait up to 48 hours)
- Check: `dig djourns.com NS`

### SSL Certificate Installation Fails
- Wait for DNS propagation before running SSL setup
- Ensure ports 80/443 are open in firewall
- Check: `docker logs certbot`

### Database Migration Issues
- Ensure PostgreSQL is running: `docker ps | grep postgres`
- Check database credentials in .env.prod
- Review migration logs: `docker compose logs janeway-web`

## Important Notes

- **SECRET_KEY in .env.prod:** Must be unique and random (never use example values)
- **Backups:** Setup automated backups immediately
- **Monitoring:** Regularly check container logs and disk space
- **Updates:** Keep Janeway repository updated for security patches
- **Firewall:** Only open ports 22, 80, 443 for security

## Support & Documentation

- Full deployment guide: `DEPLOYMENT_PLAN.md`
- DNS setup: `deployment/DNS_SETUP.md`
- Deployment scripts: `deployment/README.md`
- Production nginx config: `deployment/nginx/conf.d/janeway.conf`
- Environment reference: `deployment/.env.prod.example`

## Deployment Date
**Started:** ___________
**Completed:** ___________
**Deployed By:** ___________

## Production Access Info
- **Domain 1:** https://press.djourns.com
- **Domain 2:** https://anotherpress.djourns.com
- **Droplet IP:** ___________
- **SSH User:** root
- **SSH Key:** ~/.ssh/id_rsa

---
Last Updated: 2026-03-08
