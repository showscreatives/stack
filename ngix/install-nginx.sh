#!/bin/bash

# =====================================================
# LeadFlow - Nginx Installation Script
# Automated setup for Nginx + Certbot
# =====================================================

echo "🚀 LeadFlow Nginx Setup Started..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =====================================================
# Step 1: Stop existing services
# =====================================================
echo -e "${BLUE}[1/7]${NC} Stopping existing services..."
cd ~/leadflow-system
docker compose down

# =====================================================
# Step 2: Create directories
# =====================================================
echo -e "${BLUE}[2/7]${NC} Creating directories..."
mkdir -p conf.d
mkdir -p certbot-logs
mkdir -p nginx-certs/live/leadsflowsys.online
mkdir -p /var/www/certbot

# =====================================================
# Step 3: Create nginx.conf
# =====================================================
echo -e "${BLUE}[3/7]${NC} Creating nginx.conf..."
cat > nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # SSL parameters
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=api:10m rate=50r/s;

    # Include individual server configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

# =====================================================
# Step 4: Create leadsflowsys.conf
# =====================================================
echo -e "${BLUE}[4/7]${NC} Creating leadsflowsys.conf..."
cat > conf.d/leadsflowsys.conf << 'EOF'
# HTTP to HTTPS Redirect
server {
    listen 80;
    listen [::]:80;
    server_name leadsflowsys.online *.leadsflowsys.online;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# Mautic
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name mautic.leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        proxy_pass http://mautic:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}

# n8n
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name n8n.leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        proxy_pass http://n8n:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
}

# Metabase
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name metabase.leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        proxy_pass http://metabase:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}

# RabbitMQ
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name rabbitmq.leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        proxy_pass http://rabbitmq:15672;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}

# Qdrant
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name qdrant.leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        proxy_pass http://qdrant:6333;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}

# WAHA
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name waha.leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        proxy_pass http://waha:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}

# Root domain redirect
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        return 301 https://mautic.leadsflowsys.online$request_uri;
    }
}
EOF

# =====================================================
# Step 5: Setup docker-compose.yml
# =====================================================
echo -e "${BLUE}[5/7]${NC} Setting up docker-compose.yml..."
# User needs to manually get docker-compose-nginx.yml
# For now, show instruction

# =====================================================
# Step 6: Start services
# =====================================================
echo -e "${BLUE}[6/7]${NC} Starting services..."
docker compose up -d

sleep 30

# =====================================================
# Step 7: Check status
# =====================================================
echo -e "${BLUE}[7/7]${NC} Checking status..."
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Services Status:${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
docker compose ps
echo ""

# Check if certificates are ready
echo -e "${YELLOW}Waiting for Certbot to generate certificates...${NC}"
echo "This may take 1-3 minutes..."
echo ""

# Monitor certbot
timeout 180 docker compose logs -f certbot 2>/dev/null | grep -m1 "Successfully received"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Certificates generated successfully!${NC}"
    
    # Reload Nginx
    echo ""
    echo -e "${BLUE}Reloading Nginx...${NC}"
    docker compose exec nginx nginx -s reload
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ LeadFlow Setup Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Access your services at:${NC}"
    echo "  🌐 Mautic:   https://mautic.leadsflowsys.online"
    echo "  ⚙️  n8n:      https://n8n.leadsflowsys.online"
    echo "  📊 Metabase: https://metabase.leadsflowsys.online"
    echo "  🐰 RabbitMQ: https://rabbitmq.leadsflowsys.online"
    echo "  🎯 Qdrant:   https://qdrant.leadsflowsys.online"
    echo "  💬 WAHA:     https://waha.leadsflowsys.online"
    echo ""
else
    echo -e "${RED}✗ Certificate generation timeout${NC}"
    echo "Check logs with: docker compose logs certbot"
fi
