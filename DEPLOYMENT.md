# Deployment Guide

This project includes a comprehensive CI/CD pipeline for automated deployment to a VM.

## 🚀 Quick Start

### 1. Set up GitHub Secrets

Follow the instructions in [.github/SECRETS_TEMPLATE.md](.github/SECRETS_TEMPLATE.md) to configure your VM connection secrets.

### 2. Deploy Automatically

Push to the `main` branch to trigger automatic deployment:

```bash
git add .
git commit -m "feat: add new feature"
git push origin main
```

### 3. Deploy Manually

Go to GitHub Actions → Manual Deployment → Run workflow

## 📁 Project Structure

```
├── .github/workflows/
│   ├── ci-cd.yml          # Automatic CI/CD pipeline
│   └── manual-deploy.yml  # Manual deployment workflow
├── scripts/
│   ├── deploy.sh          # Deployment script
│   ├── rollback.sh        # Rollback script
│   └── health-check.sh    # Health check script
├── engineex.conf          # Nginx configuration
└── DEPLOYMENT.md          # This file
```

## 🔧 Available Scripts

### Local Development
```bash
pnpm dev              # Start all services in development mode
pnpm build            # Build all packages
pnpm lint             # Lint all code
pnpm check-types      # Type check all packages
```

### Deployment
```bash
pnpm deploy           # Deploy to VM (run on VM)
pnpm rollback         # Rollback to previous version (run on VM)
pnpm health-check     # Check all services health (run on VM)
pnpm quick-health     # Quick health check (run anywhere)
```

## 🏗️ CI/CD Pipeline

### Automatic Pipeline (ci-cd.yml)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch

**Jobs:**
1. **Test & Build**: Lint, type check, and build all packages
2. **Deploy**: Deploy to VM (only on `main` branch push)

### Manual Pipeline (manual-deploy.yml)

**Triggers:**
- Manual workflow dispatch

**Options:**
- Environment: `production` or `staging`
- Action: `deploy` or `rollback`

## 🖥️ VM Requirements

Your VM should have:

- **OS**: Ubuntu 20.04+ (recommended)
- **Node.js**: 18.x
- **pnpm**: 9.0.0
- **PM2**: For process management
- **Nginx**: For reverse proxy
- **SSH access**: For deployment

### VM Setup Commands

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install pnpm
npm install -g pnpm@9.0.0

# Install PM2
npm install -g pm2

# Install Nginx
sudo apt install nginx -y

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

## 🔍 Monitoring

### Check Service Status

```bash
# On VM
pm2 status                    # Show all services
pm2 logs                      # Show all logs
pm2 logs http-server          # Show HTTP server logs
pm2 logs ws-server            # Show WebSocket server logs
pm2 logs web-server           # Show web server logs
```

### Health Checks

```bash
# Comprehensive health check
pnpm health-check

# Quick health check
pnpm quick-health

# Manual checks
curl http://localhost:3002/hi  # HTTP API
curl http://localhost:3000     # Web app
netstat -tuln | grep :8080    # WebSocket server
```

## 🔄 Rollback Process

If something goes wrong:

1. **Automatic rollback**: Use GitHub Actions → Manual Deployment → Select "rollback"
2. **Manual rollback**: SSH to VM and run `pnpm rollback`

The rollback script will:
- Stop current services
- Restore from the most recent backup
- Restart services
- Verify health

## 🛠️ Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   pm2 logs
   pm2 restart all
   ```

2. **Database connection issues**
   ```bash
   cd packages/prisma
   pnpm prisma db push
   ```

3. **Nginx configuration issues**
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```

4. **Port conflicts**
   ```bash
   sudo lsof -i :3000
   sudo lsof -i :3002
   sudo lsof -i :8080
   ```

### Logs Location

- **PM2 logs**: `~/.pm2/logs/`
- **Nginx logs**: `/var/log/nginx/`
- **System logs**: `journalctl -u nginx`

## 📊 Service Endpoints

After successful deployment:

- **HTTP API**: `http://your-vm-ip:3002`
- **WebSocket**: `ws://your-vm-ip:8080`
- **Web App**: `http://your-vm-ip:3000`

With Nginx configured:
- **HTTP API**: `http://httpserver.jagatraj.xyz`
- **WebSocket**: `ws://websocket.jagatraj.xyz`
- **Web App**: `http://webserver.jagatraj.xyz`

## 🔐 Security Notes

- Keep your SSH keys secure
- Regularly update your VM
- Monitor logs for suspicious activity
- Use HTTPS in production (configure SSL certificates)
- Set up firewall rules as needed

## 📝 Environment Variables

Make sure your VM has the correct environment variables:

```bash
# In packages/prisma/.env
DATABASE_URL=postgresql://neondb_owner:npg_OPT8eNJW6Gpt@ep-restless-resonance-a8pix49v.eastus2.azure.neon.tech/main?sslmode=require&channel_binding=require
```
