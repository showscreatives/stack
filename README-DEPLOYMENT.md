# 🚀 LeadFlow System - Production Deployment Guide

## 📋 Overview

**Domain:** leadsflowsys.online  
**VPS IP:** 75.119.156.73  
**Deployment Date:** November 13, 2025  
**Stack:** Docker Compose, PostgreSQL, Mautic, n8n, Metabase, WAHA, Traefik

This is a complete AI-powered lead management and cold outreach automation platform designed for agencies.

---

## 🎯 Quick Start

### Prerequisites
- Ubuntu 20.04+ or similar Linux distribution
- Docker 20.10+
- Docker Compose v2+
- Domain DNS already configured (✅ Completed)
- Minimum 8GB RAM (16GB recommended)
- 50GB+ disk space

### DNS Records Required (Already Added)

Ensure these DNS A records point to `75.119.156.73`:

```
@ (root domain)              → 75.119.156.73
*.leadsflowsys.online        → 75.119.156.73 (wildcard)
```

Or individual subdomains:
```
mautic.leadsflowsys.online    → 75.119.156.73
n8n.leadsflowsys.online       → 75.119.156.73
metabase.leadsflowsys.online  → 75.119.156.73
traefik.leadsflowsys.online   → 75.119.156.73
rabbitmq.leadsflowsys.online  → 75.119.156.73
qdrant.leadsflowsys.online    → 75.119.156.73
waha.leadsflowsys.online      → 75.119.156.73
```

---

## 📦 Installation Steps

### Step 1: Prepare VPS

```bash
# SSH into your VPS
ssh root@75.119.156.73

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose-plugin -y

# Verify installations
docker --version
docker compose version

# Create project directory
mkdir -p ~/leadflow-system
cd ~/leadflow-system
```

### Step 2: Upload Files

Upload these files to `~/leadflow-system/`:
1. `.env` - Environment variables (generated)
2. `docker-compose.yml` - Docker services configuration
3. `init-databases.sql` - PostgreSQL initialization script
4. `mautic-custom-fields.json` - Mautic field definitions (from attachments)
5. `mautic-tags-structure.json` - Mautic tag definitions (from attachments)

```bash
# Example using SCP from your local machine
scp .env docker-compose.yml init-databases.sql root@75.119.156.73:~/leadflow-system/
scp mautic-*.json root@75.119.156.73:~/leadflow-system/
```

### Step 3: Configure Firewall

```bash
# Install UFW if not already installed
apt install ufw -y

# Allow SSH (important!)
ufw allow 22/tcp

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw --force enable

# Check status
ufw status
```

### Step 4: Start Services

```bash
cd ~/leadflow-system

# Create necessary directories
mkdir -p data/{postgres,mautic,n8n,metabase,rabbitmq,qdrant,waha,redis}
mkdir -p logs backups

# Set permissions
chmod 600 .env
chmod +x init-databases.sql

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### Step 5: Verify Deployment

Wait 3-5 minutes for all services to start, then check:

```bash
# Check all containers are running
docker compose ps

# Expected output: All services should show "Up" status

# Test SSL certificates (may take a few minutes)
curl -I https://mautic.leadsflowsys.online
curl -I https://n8n.leadsflowsys.online
curl -I https://metabase.leadsflowsys.online
```

---

## 🔐 Access Credentials

### Service URLs and Login Details

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **Mautic** | https://mautic.leadsflowsys.online | `admin` | `r$SqQ28prGc$W*IH` |
| **n8n** | https://n8n.leadsflowsys.online | `admin` | `Z56sDUXL3%zK*BQ%` |
| **Metabase** | https://metabase.leadsflowsys.online | Setup on first visit | - |
| **Traefik** | https://traefik.leadsflowsys.online | `admin` | `Z56sDUXL3%zK*BQ%` |
| **RabbitMQ** | https://rabbitmq.leadsflowsys.online | `mautic` | `Jx8yqP*4Z39Ky$r9iQxjB49h` |
| **Qdrant** | https://qdrant.leadsflowsys.online | API Key | `dEbkc9$qFsRIbDr$I9e38N%qA$#B6fJr` |
| **WAHA** | https://waha.leadsflowsys.online | API Key | `yN&4%zO6h7H!DhQ@3eJd2i!^o#^&3^e^` |

**⚠️ IMPORTANT:** Save these credentials in a secure password manager!

### Database Access

```bash
# PostgreSQL connection details
Host: 75.119.156.73 (or localhost if on VPS)
Port: Not exposed externally (secure)
Database: leadflow
Username: postgres
Password: @&ae0SEKvw9AyG^*T^z3T2Cx8ZPi2Psc

# To access via psql
docker compose exec postgres psql -U postgres -d leadflow
```

---

## ⚙️ Post-Installation Configuration

### 1. Configure Mautic

Access: https://mautic.leadsflowsys.online

1. **Complete Setup Wizard** (if prompted)
   - Database should auto-configure
   - Login with admin credentials above

2. **Configure SMTP for Email Sending**
   - Go to Settings → Configuration → Email Settings
   - Choose SMTP provider (SendGrid, Amazon SES, etc.)
   - Update `.env` file with SMTP credentials
   - Restart Mautic: `docker compose restart mautic`

3. **Import Custom Fields**
   - Use the `mautic-custom-fields.json` file from attachments
   - Go to Settings → Custom Fields → Import
   - Or create manually using the JSON as reference

4. **Import Tags**
   - Use `mautic-tags-structure.json` as reference
   - Create tags via Settings → Tags

### 2. Configure n8n

Access: https://n8n.leadsflowsys.online

1. **Set Owner Account**
   - First login will prompt for owner account setup
   - Use strong credentials

2. **Add OpenAI Credentials**
   - Go to Credentials → New
   - Select "OpenAI API"
   - Add your API key (update in .env file)

3. **Add Mautic Credentials**
   - Credential type: "Mautic OAuth2 API"
   - Base URL: https://mautic.leadsflowsys.online
   - Follow OAuth2 setup process

4. **Import Workflows**
   - Upload workflow JSON files for:
     - AI Pitch Generation
     - Lead Sync to Mautic
     - Follow-up Automation
     - Welcome Sequences

### 3. Configure Metabase

Access: https://metabase.leadsflowsys.online

1. **Initial Setup**
   - Create admin account
   - Skip or add LeadFlow database connection

2. **Connect to PostgreSQL**
   - Database type: PostgreSQL
   - Host: postgres (container name)
   - Port: 5432
   - Database: leadflow
   - Username: postgres
   - Password: @&ae0SEKvw9AyG^*T^z3T2Cx8ZPi2Psc

3. **Create Dashboards**
   - Lead pipeline overview
   - Campaign performance
   - Engagement metrics
   - Conversion tracking

### 4. Configure WAHA (WhatsApp)

Access: https://waha.leadsflowsys.online

1. **Start WhatsApp Session**
   ```bash
   curl -X POST https://waha.leadsflowsys.online/api/sessions/start \
     -H "X-Api-Key: yN&4%zO6h7H!DhQ@3eJd2i!^o#^&3^e^" \
     -H "Content-Type: application/json" \
     -d '{"name": "default"}'
   ```

2. **Scan QR Code**
   - Get QR: `GET https://waha.leadsflowsys.online/api/sessions/default/qr`
   - Scan with WhatsApp app

3. **Configure Webhook in n8n**
   - Create webhook node in n8n
   - Point WAHA webhooks to n8n endpoint

---

## 🔧 Common Commands

### Service Management

```bash
# View all services status
docker compose ps

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f mautic

# Restart a service
docker compose restart mautic

# Stop all services
docker compose down

# Start all services
docker compose up -d

# Update all services to latest images
docker compose pull
docker compose up -d
```

### Database Operations

```bash
# Access PostgreSQL
docker compose exec postgres psql -U postgres -d leadflow

# Create database backup
docker compose exec postgres pg_dump -U postgres leadflow > backup_$(date +%Y%m%d).sql

# Restore database
cat backup_20251113.sql | docker compose exec -T postgres psql -U postgres -d leadflow

# View database size
docker compose exec postgres psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('leadflow'));"
```

### Monitoring

```bash
# Check disk usage
df -h

# Check Docker disk usage
docker system df

# Monitor container resources
docker stats

# View system resources
htop
```

---

## 📊 Monitoring & Maintenance

### Daily Checks

1. **Service Health**
   ```bash
   docker compose ps
   # All services should be "Up"
   ```

2. **Disk Space**
   ```bash
   df -h
   # Ensure sufficient space on /var/lib/docker
   ```

3. **SSL Certificates**
   - Traefik auto-renews Let's Encrypt certificates
   - Check dashboard: https://traefik.leadsflowsys.online

### Weekly Tasks

1. **Review Logs**
   ```bash
   docker compose logs --tail=100 mautic
   docker compose logs --tail=100 n8n
   ```

2. **Database Backup**
   ```bash
   cd ~/leadflow-system
   docker compose exec postgres pg_dump -U postgres leadflow | gzip > backups/leadflow_$(date +%Y%m%d).sql.gz
   ```

3. **Clean Up Docker**
   ```bash
   docker system prune -a --volumes
   # WARNING: This removes unused images and volumes
   ```

### Monthly Tasks

1. **Update Services**
   ```bash
   docker compose pull
   docker compose up -d
   ```

2. **Review Security**
   - Check for Docker image updates
   - Review firewall rules
   - Rotate API keys if needed

3. **Backup Verification**
   - Test restore process
   - Verify backup integrity

---

## 🚨 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose logs service_name

# Common issues:
# 1. Port already in use
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# 2. Permission issues
sudo chown -R 1000:1000 data/

# 3. Database connection issues
docker compose exec postgres pg_isready -U postgres
```

### SSL Certificate Issues

```bash
# Check Traefik logs
docker compose logs traefik | grep acme

# Force certificate regeneration
docker compose down
rm -rf data/traefik/letsencrypt/acme.json
docker compose up -d
```

### Database Connection Issues

```bash
# Test PostgreSQL
docker compose exec postgres psql -U postgres -c "SELECT version();"

# Check Mautic database connection
docker compose exec mautic cat /var/www/html/config/local.php | grep database

# Reset database password
docker compose exec postgres psql -U postgres -c "ALTER USER mauticuser WITH PASSWORD 'new_password';"
```

### High Resource Usage

```bash
# Check container resources
docker stats

# Identify resource hogs
docker compose top

# Restart resource-intensive service
docker compose restart mautic

# Clear logs
docker compose logs --tail=0 -f mautic > /dev/null 2>&1
```

---

## 🔒 Security Best Practices

### Implemented

✅ Firewall configured (UFW)  
✅ SSL/TLS encryption (Let's Encrypt)  
✅ Strong random passwords  
✅ Database not exposed externally  
✅ Traefik dashboard password protected  
✅ Secure container network isolation  

### Recommended Additional Steps

1. **Enable Fail2Ban**
   ```bash
   apt install fail2ban -y
   systemctl enable fail2ban
   systemctl start fail2ban
   ```

2. **Regular Password Rotation**
   - Rotate passwords every 90 days
   - Update `.env` and restart services

3. **Monitoring**
   - Set up Uptime monitoring (UptimeRobot, etc.)
   - Configure alerts for service downtime

4. **Backups**
   - Automated daily backups to external storage
   - Test restore procedures monthly

5. **Updates**
   - Apply security updates promptly
   - Subscribe to security mailing lists

---

## 📈 Scaling Considerations

### Current Setup
- Single-server deployment
- Suitable for: 1,000-10,000 leads/month
- Shared PostgreSQL database

### To Scale Up

1. **Vertical Scaling**
   - Upgrade VPS resources
   - Add more CPU/RAM
   - Increase disk space

2. **Database Optimization**
   ```bash
   # Increase PostgreSQL resources in docker-compose.yml
   POSTGRES_MAX_CONNECTIONS=500
   POSTGRES_SHARED_BUFFERS=1GB
   ```

3. **Horizontal Scaling**
   - Separate database server
   - Load balancer for Mautic/n8n
   - Redis cluster for caching

---

## 📞 Support & Resources

### Documentation
- Mautic: https://docs.mautic.org
- n8n: https://docs.n8n.io
- Traefik: https://doc.traefik.io/traefik/

### Community
- Mautic Community: https://forum.mautic.org
- n8n Community: https://community.n8n.io

### Contact
- Email: showsceatives@gmail.com
- Timezone: Africa/Nairobi (EAT)

---

## 📝 Next Steps

After deployment, you should:

1. **Configure SMTP** - Update `.env` with real SMTP credentials
2. **Add OpenAI API Key** - Update `.env` with your OpenAI key
3. **Import Mautic Fields** - Use the provided JSON files
4. **Import Mautic Tags** - Set up tag structure
5. **Create n8n Workflows** - Import or create automation workflows
6. **Set Up Metabase Dashboards** - Create analytics dashboards
7. **Test End-to-End** - Send a test lead through the system

---

## 📝 Changelog

### Version 1.0 - November 13, 2025
- Initial production deployment
- All services configured and running
- SSL certificates enabled
- Documentation complete

---

**🎉 LeadFlow System is now live at leadsflowsys.online!**

*Built for agencies. Powered by AI. Deployed with Docker.*
