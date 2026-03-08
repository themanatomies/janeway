#!/bin/bash
# deployment/05-nginx-setup.sh
# Configures Nginx for production Janeway deployment

set -e

echo "=== Nginx Setup for Janeway Production ==="

# Create nginx directories if they don't exist
mkdir -p /vol/janeway/nginx/conf.d
mkdir -p /etc/letsencrypt/live

# Copy Janeway Nginx config to both system and docker locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# For system Nginx
echo "Setting up system Nginx..."
cat > /etc/nginx/sites-available/janeway << 'EOF'
upstream janeway_app {
    server 127.0.0.1:8000;
}

# HTTP redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name press.djourns.com anotherpress.djourns.com www.djourns.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name press.djourns.com anotherpress.djourns.com www.djourns.com;

    ssl_certificate /etc/letsencrypt/live/press.djourns.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/press.djourns.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    client_max_body_size 100M;

    location /static/ {
        alias /vol/janeway/janeway/src/collected-static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /vol/janeway/janeway/src/media/;
        expires 7d;
    }

    location / {
        proxy_pass http://janeway_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable the config
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/janeway /etc/nginx/sites-enabled/janeway

# Test Nginx config
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx configuration test passed"
    systemctl reload nginx
    echo "✓ Nginx reloaded"
else
    echo "✗ Nginx configuration test failed"
    nginx -t
    exit 1
fi

# Also copy to docker location
cp "$SCRIPT_DIR/nginx/janeway.conf" /vol/janeway/nginx/conf.d/janeway.conf || true

echo "✓ Nginx setup complete"
