# GitHub Secrets Configuration

To use the CI/CD pipeline, you need to configure the following secrets in your GitHub repository:

## Required Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### VM Connection Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `VM_HOST` | Your VM's public IP address or domain | `52.123.45.67` or `your-vm.example.com` |
| `VM_USERNAME` | SSH username for your VM | `ubuntu` |
| `VM_SSH_KEY` | Private SSH key for VM access | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VM_PORT` | SSH port (usually 22) | `22` |

## How to Generate SSH Key

If you don't have an SSH key pair, generate one:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Copy public key to VM
ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@your-vm-ip

# Copy private key content for GitHub secret
cat ~/.ssh/id_rsa
```

## Setting Up the VM

Make sure your VM has the following installed:

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

## Testing the Setup

After setting up the secrets, you can:

1. **Automatic deployment**: Push to `main` branch to trigger automatic deployment
2. **Manual deployment**: Go to Actions → Manual Deployment → Run workflow
3. **Manual rollback**: Go to Actions → Manual Deployment → Run workflow → Select "rollback"

## Environment Variables

Make sure your VM has the `.env` file in the `packages/prisma` directory:

```bash
# On your VM
cd /home/ubuntu/devops-class25.2/packages/prisma
echo "DATABASE_URL=postgresql://neondb_owner:npg_OPT8eNJW6Gpt@ep-restless-resonance-a8pix49v.eastus2.azure.neon.tech/main?sslmode=require&channel_binding=require" > .env
```

## Monitoring

After deployment, you can monitor your services:

```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs

# Check specific service
pm2 logs http-server
pm2 logs ws-server
pm2 logs web-server

# Restart services
pm2 restart all

# Stop services
pm2 stop all
```
