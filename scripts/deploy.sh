#!/bin/bash

# Deployment script for VM
# This script should be run on the VM after code is deployed

set -e

echo "🚀 Starting deployment process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root."
    exit 1
fi

# Install Node.js if not already installed
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install pnpm if not already installed
if ! command -v pnpm &> /dev/null; then
    print_status "Installing pnpm..."
    sudo npm install -g pnpm@10.16.1
fi

# Install/update dependencies with memory optimization and retry
print_status "Installing dependencies..."
for i in {1..3}; do
    print_status "Attempt $i of 3..."
    if pnpm install --frozen-lockfile --prefer-offline; then
        print_status "Dependencies installed successfully"
        break
    else
        print_warning "Installation failed, retrying..."
        if [ $i -eq 3 ]; then
            print_error "All installation attempts failed"
            exit 1
        fi
        sleep 5
    fi
done

# Generate Prisma client
print_status "Generating Prisma client..."
cd packages/prisma

# Ensure Prisma is properly installed
if [ ! -f "node_modules/prisma/build/index.js" ]; then
    print_warning "Prisma binary not found, reinstalling..."
    pnpm install prisma --save-dev
fi

pnpm prisma generate
cd ../..

# Run database migrations
print_status "Running database migrations..."
cd packages/prisma
pnpm prisma db push
cd ../..

# Build the application
print_status "Building application..."
pnpm run build

# Install PM2 if not already installed
if ! command -v pm2 &> /dev/null; then
    print_status "Installing PM2..."
    npm install -g pm2
fi

# Stop existing services
print_status "Stopping existing services..."
pm2 delete all 2>/dev/null || true

# Start services with PM2
print_status "Starting services..."

# Start HTTP server
pm2 start apps/http-server/dist/index.js --name "http-server" -- --port 3002

# Start WebSocket server  
pm2 start apps/ws-server/dist/index.js --name "ws-server" -- --port 8080

# Start Web server
pm2 start "cd apps/web && npm start" --name "web-server"

# Save PM2 configuration
pm2 save

# Setup PM2 startup (only if not already done)
if ! pm2 startup | grep -q "already"; then
    print_status "Setting up PM2 startup..."
    pm2 startup
fi

# Update nginx configuration
print_status "Updating Nginx configuration..."
if [ -f "engineex.conf" ]; then
    sudo cp engineex.conf /etc/nginx/sites-available/devops-class25.2
    sudo ln -sf /etc/nginx/sites-available/devops-class25.2 /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    if sudo nginx -t; then
        sudo systemctl reload nginx
        print_status "Nginx configuration updated and reloaded"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
else
    print_warning "engineex.conf not found, skipping nginx update"
fi

# Health check
print_status "Performing health checks..."
sleep 10

# Check HTTP server
if curl -f http://localhost:3002/hi > /dev/null 2>&1; then
    print_status "✅ HTTP server is healthy"
else
    print_error "❌ HTTP server health check failed"
    exit 1
fi

# Check Web server
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Web server is healthy"
else
    print_error "❌ Web server health check failed"
    exit 1
fi

# Check WebSocket server (basic port check)
if netstat -tuln | grep -q ":8080 "; then
    print_status "✅ WebSocket server is running"
else
    print_error "❌ WebSocket server is not running"
    exit 1
fi

print_status "🎉 Deployment completed successfully!"
print_status "Services status:"
pm2 status

print_status "Available endpoints:"
print_status "  - HTTP API: http://localhost:3002"
print_status "  - WebSocket: ws://localhost:8080"
print_status "  - Web App: http://localhost:3000"
