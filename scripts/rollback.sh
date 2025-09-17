#!/bin/bash

# Rollback script for VM
# This script rolls back to the previous deployment

set -e

echo "🔄 Starting rollback process..."

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

# Find the most recent backup
BACKUP_DIR=$(ls -t /home/ubuntu/devops-class25.2.backup.* 2>/dev/null | head -n1)

if [ -z "$BACKUP_DIR" ]; then
    print_error "No backup found for rollback"
    exit 1
fi

print_status "Found backup: $BACKUP_DIR"

# Stop current services
print_status "Stopping current services..."
pm2 delete all 2>/dev/null || true

# Remove current deployment
print_status "Removing current deployment..."
if [ -d "/home/ubuntu/devops-class25.2" ]; then
    rm -rf /home/ubuntu/devops-class25.2
fi

# Restore from backup
print_status "Restoring from backup..."
mv "$BACKUP_DIR" /home/ubuntu/devops-class25.2

# Start services
print_status "Starting services from backup..."
cd /home/ubuntu/devops-class25.2

# Install dependencies
pnpm install --frozen-lockfile

# Generate Prisma client
cd packages/prisma
pnpm prisma generate
cd ../..

# Build application
pnpm run build

# Start services with PM2
pm2 start apps/http-server/dist/index.js --name "http-server" -- --port 3002
pm2 start apps/ws-server/dist/index.js --name "ws-server" -- --port 8080
pm2 start "cd apps/web && npm start" --name "web-server"

pm2 save

# Health check
print_status "Performing health checks..."
sleep 10

# Check services
if curl -f http://localhost:3002/hi > /dev/null 2>&1; then
    print_status "✅ HTTP server is healthy"
else
    print_error "❌ HTTP server health check failed"
    exit 1
fi

if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Web server is healthy"
else
    print_error "❌ Web server health check failed"
    exit 1
fi

print_status "🎉 Rollback completed successfully!"
print_status "Services status:"
pm2 status
