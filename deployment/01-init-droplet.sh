#!/bin/bash
# deployment/01-init-droplet.sh
# Initialize Code Ocean droplet with Docker, Docker Compose, and dependencies

set -e

echo "=== Janeway Droplet Initialization ==="
echo "Installing system dependencies..."

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add current user to docker group
sudo usermod -aG docker $USER

# Install other dependencies
echo "Installing additional dependencies..."
sudo apt-get install -y \
    git \
    vim \
    htop \
    wget \
    curl \
    certbot \
    python3-certbot-nginx \
    nginx \
    postgresql-client \
    redis-tools

# Create necessary directories
echo "Creating directories..."
sudo mkdir -p /vol/janeway
sudo mkdir -p /vol/janeway/db
sudo mkdir -p /vol/janeway/src
sudo mkdir -p /vol/janeway/backups

# Set permissions
sudo chown $USER:$USER /vol/janeway -R

# Enable Docker daemon
sudo systemctl start docker
sudo systemctl enable docker

echo "=== Initialization Complete ==="
echo ""
echo "Important setup notes:"
echo "1. You may need to log out and back in for docker group permissions to take effect"
echo "2. Run 'docker ps' to verify Docker is working"
echo "3. Next: Clone repository and run 02-deploy.sh"
echo ""
echo "If you're running this remotely, execute:"
echo "  newgrp docker"
echo "to activate docker group membership in current session"
