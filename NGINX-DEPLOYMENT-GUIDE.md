# 🚀 LeadFlow System - Nginx Reverse Proxy Setup

## 📋 Why Nginx?

| Feature | Caddy | Nginx | Traefik |
|---------|-------|-------|---------|
| Performance | Good | ⭐⭐⭐⭐⭐ Excellent | Good |
| Memory usage | Low | ⭐⭐⭐⭐⭐ Very Low | High |
| SSL setup | Auto | Manual (Certbot) | Complex |
| Configuration | Simple | Very Simple | Complex |
| Stability | Good | ⭐⭐⭐⭐⭐ Rock Solid | Good |
| Learning curve | Moderate | Easy | Steep |
| Industry standard | Yes | Yes (Most common) | No |

---

## ✅ What You Get

- **Nginx** - Lightweight, battle-tested web server
- **Certbot** - Automatic SSL certificate management
- **Auto-renewal** - Certificates renew automatically
- **High performance** - Can handle millions of requests
- **Simple config** - Easy to understand and modify

---

## ⚡ Quick Deploy (10 minutes)

### Step 1: Prepare Files

On your VPS:

```bash
ssh root@75.119.156.73
cd ~/leadflow-system

# Stop old services
docker compose down

# Create directories for Nginx config
mkdir -p conf.d
mkdir -p certbot-logs
mkdir -p /var/www/certbot

# Create a placeholder certbot directory for initial SSL request
mkdir -p nginx-certs/live/leadsflowsys.online
```

### Step 2: Create Configuration Files

Create three files in `~/leadflow-system/`:

**File 1: nginx.conf** (save in project root)
```
[Use content from file nginx.conf provided]
```

**File 2: conf.d/leadsflowsys.conf** (create conf.d directory first)
```bash
mkdir -p conf.d
# Save content from leadsflowsys.conf file into conf.d/leadsflowsys.conf
```

### Step 3: Update docker-compose.yml

Use the provided `docker-compose-nginx.yml`:

```bash
# Backup old one
mv docker-compose.yml docker-compose.yml.caddy.backup

# Use new Nginx version
mv docker-compose-nginx.yml docker-compose.yml
```

### Step 4: Start Services

```bash
# Start all services
docker compose up -d

# Wait 30 seconds for services to be ready
sleep 30

# Check status
docker compose ps

# All should be "Up" or "Up (healthy)"
```

### Step 5: Wait for Certificates

Certbot will automatically request certificates:

```bash
# Check Certbot logs
docker compose logs -f certbot

# Wait for message:
# "Successfully received certificate"
# This takes 1-3 minutes

# Once you see that, Ctrl+C to exit logs
```

### Step 6: Reload Nginx

Once certificates are ready:

```bash
# Reload Nginx configuration
docker compose exec nginx nginx -s reload

# Check Nginx logs
docker compose logs nginx | tail -20
```

### Step 7: Test Access

```bash
# Test each service
curl -I https://mautic.leadsflowsys.online
curl -I https://n8n.leadsflowsys.online
curl -I https://metabase.leadsflowsys.online

# All should return HTTP/2 200 with valid SSL ✓
```

---

## 🔧 Nginx Configuration Explained

### Basic proxy config:

```nginx
server {
    listen 443 ssl http2;
    server_name mautic.leadsflowsys.online;

    ssl_certificate /etc/nginx/certs/live/leadsflowsys.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/leadsflowsys.online/privkey.pem;

    location / {
        proxy_pass http://mautic:80;  # Route to service
        proxy_set_header Host $host;  # Pass original host
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**This means:**
- Listen on HTTPS (443) with SSL
- Use certificates from Certbot
- Route traffic to `mautic:80` (internal service)
- Pass through original request headers

---

## 📊 File Structure

Your `~/leadflow-system/` should look like:

```
leadflow-system/
├── docker-compose.yml          (docker-compose-nginx.yml)
├── nginx.conf                   (Nginx main config)
├── conf.d/
│   └── leadsflowsys.conf       (Virtual host configs)
├── .env                         (Environment variables)
├── init-databases.sql          (Database init)
├── mautic-custom-fields.json   (Mautic fields)
├── mautic-tags-structure.json  (Mautic tags)
├── nginx-certs/                (SSL certificates - auto-created)
├── certbot-logs/               (Certbot logs - auto-created)
└── data/                        (Docker volumes)
```

---

## 🔒 SSL Certificate Management

### How it works:

1. **First start**: Certbot requests certificate from Let's Encrypt
2. **Nginx serves** challenge files over HTTP
3. **Let's Encrypt verifies** domain ownership
4. **Certificate saved** to `nginx-certs/`
5. **Nginx reloads** with new certificate
6. **Auto-renewal**: Certbot renews 30 days before expiry

### Manual certificate renewal (if needed):

```bash
docker compose exec certbot certbot renew --force-renewal
docker compose exec nginx nginx -s reload
```

### View certificate info:

```bash
docker compose exec certbot certbot certificates
```

---

## 🛠️ Common Operations

### View Nginx logs:

```bash
docker compose logs -f nginx
```

### View Certbot logs:

```bash
docker compose logs -f certbot
```

### Test Nginx configuration:

```bash
docker compose exec nginx nginx -t
```

### Reload configuration (after changes):

```bash
docker compose exec nginx nginx -s reload
```

### Restart Nginx:

```bash
docker compose restart nginx
```

---

## 🚨 Troubleshooting

### Certificate not generating?

```bash
# Check DNS
nslookup mautic.leadsflowsys.online
# Should return: 75.119.156.73

# Check Certbot logs
docker compose logs certbot | tail -50

# Check if port 80 is open
sudo netstat -tulpn | grep :80
```

### Nginx not connecting to services?

```bash
# Check if services are running
docker compose ps

# Check Nginx error logs
docker compose logs nginx | grep error

# Test internal connectivity
docker compose exec nginx curl -I http://mautic:80
```

### Reload not working?

```bash
# Validate syntax first
docker compose exec nginx nginx -t

# If OK, restart
docker compose restart nginx
```

---

## 📈 Performance Tips

### Increase worker connections:

Edit `nginx.conf`:
```nginx
events {
    worker_connections 2048;  # Increase from 1024
}
```

Then reload:
```bash
docker compose exec nginx nginx -s reload
```

### Enable caching:

Add to `leadsflowsys.conf`:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=cache:10m;

location / {
    proxy_cache cache;
    proxy_cache_valid 200 1h;
}
```

---

## 🔐 Security Best Practices

### Already included:

✅ TLS 1.2 & 1.3 only  
✅ Strong ciphers  
✅ HSTS headers  
✅ X-Forwarded headers  
✅ Client max body size limit  

### Additional (optional):

```nginx
# Add to server block
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
```

---

## 📝 Nginx vs Others

### Nginx vs Caddy:

| Feature | Nginx | Caddy |
|---------|-------|-------|
| Auto SSL | No (Certbot needed) | Yes (Built-in) |
| Setup time | 10 mins | 5 mins |
| Industry adoption | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Performance | Best | Good |
| Stability | Rock solid | Good |
| Learning | Easy | Very easy |

**Nginx** = Production-proven, slightly more setup  
**Caddy** = Faster setup, auto SSL built-in

### Nginx vs Traefik:

| Feature | Nginx | Traefik |
|---------|-------|---------|
| Docker dependency | None | Requires Docker labels |
| Complexity | Simple | Complex |
| SSL setup | Manual | Automatic (but complex) |
| Performance | Excellent | Good |
| Learning | Easy | Steep |
| Docker version issues | No | Yes (API 1.44 issue) |

**Nginx** = No Docker drama, rock-solid  
**Traefik** = Auto SSL but complicated

---

## ✅ Deployment Checklist

- [ ] Created `conf.d/` directory
- [ ] Placed `nginx.conf` in root
- [ ] Placed `leadsflowsys.conf` in `conf.d/`
- [ ] Using `docker-compose-nginx.yml`
- [ ] `.env` file configured
- [ ] DNS records point to VPS
- [ ] Firewall allows 80 and 443
- [ ] `docker compose up -d` successful
- [ ] Certbot got certificates
- [ ] Can access https://mautic.leadsflowsys.online
- [ ] SSL shows green lock in browser

---

## 🎉 You're Ready!

After deployment:

1. **Mautic**: https://mautic.leadsflowsys.online
2. **n8n**: https://n8n.leadsflowsys.online
3. **Metabase**: https://metabase.leadsflowsys.online
4. **RabbitMQ**: https://rabbitmq.leadsflowsys.online
5. **Qdrant**: https://qdrant.leadsflowsys.online
6. **WAHA**: https://waha.leadsflowsys.online

All with valid SSL certificates and high performance! 🚀
