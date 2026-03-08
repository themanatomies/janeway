# DNS Configuration Guide for djourns.com

## Prerequisites
- djourns.com domain purchased from registrar (GoDaddy, Namecheap, etc.)
- Code Ocean droplet created with public IP address
- Able to access domain registrar's DNS settings

## Step 1: Find Your Droplet IP

When you create your Code Ocean droplet, get the public IP address from the control panel.

```
Example: 192.168.1.100
```

## Step 2: Identify Code Ocean's Nameservers

Code Ocean provides nameservers. You'll typically see them as:
```
ns1.codeinstitute.com
ns2.codeinstitute.com
ns3.codeinstitute.com
```

Check your Code Ocean account or documentation for exact values.

## Step 3: Configure in Domain Registrar

### For GoDaddy:
1. Log in to GoDaddy account
2. Go to **My Products** → **Domain**
3. Select **djourns.com**
4. Click **DNS** → **Nameservers**
5. Click **Change**
6. Select "I'll use my own nameservers (Advanced)"
7. Enter Code Ocean's nameservers:
   ```
   ns1.codeinstitute.com
   ns2.codeinstitute.com
   ns3.codeinstitute.com
   ```
8. Save changes

### For Namecheap:
1. Log in to Namecheap
2. Go to **Dashboard** → **Domain List**
3. Select **djourns.com**
4. Click **Manage**
5. Go to **Nameservers** section
6. Select "Custom Nameservers (3 nameservers)"
7. Enter Code Ocean's nameservers
8. Save

### For Other Registrars:
Look for DNS, Nameservers, or NS Records settings and update them to Code Ocean's values.

## Step 4: Add DNS Records in Code Ocean

Once nameservers are updated (takes 24-48 hours for propagation), add A records:

### In Code Ocean Control Panel:
1. Find your droplet's DNS management section
2. Add these A records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | press | [YOUR_DROPLET_IP] | 3600 |
| A | anotherpress | [YOUR_DROPLET_IP] | 3600 |
| A | www | [YOUR_DROPLET_IP] | 3600 |

## Step 5: Verify DNS Propagation

Check if DNS is correctly pointing:

```bash
# Check A record for press.djourns.com
dig press.djourns.com A

# Check A record for anotherpress.djourns.com
dig anotherpress.djourns.com A

# Using nslookup
nslookup press.djourns.com
```

Results should show your droplet's IP address.

## Step 6: Wait for HTTPS

After DNS is propagated and pointing to your droplet:
1. Ensure Nginx is running on droplet
2. Run SSL setup script: `bash deployment/04-ssl-setup.sh admin@djourns.com`

## Troubleshooting

### DNS Not Resolving
- Wait 24-48 hours for nameserver propagation
- Check with: `dig djourns.com NS` (should show Code Ocean nameservers)

### Wrong IP in DNS
- Verify in Code Ocean control panel that A records have the correct droplet IP
- Use `dig press.djourns.com` to see what's being resolved
- May need to clear local DNS cache: `sudo dscacheutil -flushcache` (macOS)

### SSL Certificate Not Installing
- Wait for DNS to fully propagate before running SSL setup
- Ensure ports 80 and 443 are open in firewall
- Check Certbot logs: `docker logs janeway-certbot`

### Website Shows "Can't Connect"
1. Verify DNS resolves to your IP: `ping press.djourns.com`
2. Verify port 80/443 accessible: `telnet press.djourns.com 443`
3. Check if containers are running: `docker ps`
4. Check Nginx logs: `docker logs janeway-nginx`

## Keep for Reference

Your DNS configuration:
```
Domain: djourns.com
Droplet IP: [FILL IN]
Nameservers: [Code Ocean nameservers]

A Records:
  press.djourns.com → [DROPLET_IP]
  anotherpress.djourns.com → [DROPLET_IP]
  www.djourns.com → [DROPLET_IP]
```

## Next Steps
Once DNS is propagated:
1. Run SSL setup script
2. Test both domains with curl or browser
3. Verify admin interfaces are accessible
