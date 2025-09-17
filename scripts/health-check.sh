#!/bin/bash

# Health check script for all services

set -e

echo "🏥 Performing health checks..."

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

# Check if services are running
check_pm2_services() {
    print_status "Checking PM2 services..."
    
    if ! command -v pm2 &> /dev/null; then
        print_error "PM2 is not installed"
        return 1
    fi
    
    # Get PM2 status
    pm2_status=$(pm2 jlist 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "")
    
    if [ -z "$pm2_status" ]; then
        print_error "No PM2 services found"
        return 1
    fi
    
    print_status "PM2 services running:"
    pm2 status
}

# Check HTTP server
check_http_server() {
    print_status "Checking HTTP server (port 3002)..."
    
    if curl -f -s http://localhost:3002/hi > /dev/null; then
        print_status "✅ HTTP server is healthy"
        return 0
    else
        print_error "❌ HTTP server is not responding"
        return 1
    fi
}

# Check Web server
check_web_server() {
    print_status "Checking Web server (port 3000)..."
    
    if curl -f -s http://localhost:3000 > /dev/null; then
        print_status "✅ Web server is healthy"
        return 0
    else
        print_error "❌ Web server is not responding"
        return 1
    fi
}

# Check WebSocket server
check_websocket_server() {
    print_status "Checking WebSocket server (port 8080)..."
    
    if netstat -tuln 2>/dev/null | grep -q ":8080 "; then
        print_status "✅ WebSocket server is listening on port 8080"
        return 0
    else
        print_error "❌ WebSocket server is not listening on port 8080"
        return 1
    fi
}

# Check database connection
check_database() {
    print_status "Checking database connection..."
    
    if [ -f "packages/prisma/.env" ]; then
        cd packages/prisma
        if pnpm prisma db pull > /dev/null 2>&1; then
            print_status "✅ Database connection is healthy"
            cd ../..
            return 0
        else
            print_error "❌ Database connection failed"
            cd ../..
            return 1
        fi
    else
        print_warning "⚠️  No .env file found in packages/prisma/"
        return 1
    fi
}

# Check Nginx
check_nginx() {
    print_status "Checking Nginx..."
    
    if systemctl is-active --quiet nginx; then
        print_status "✅ Nginx is running"
        return 0
    else
        print_error "❌ Nginx is not running"
        return 1
    fi
}

# Main health check
main() {
    local exit_code=0
    
    check_pm2_services || exit_code=1
    check_http_server || exit_code=1
    check_web_server || exit_code=1
    check_websocket_server || exit_code=1
    check_database || exit_code=1
    check_nginx || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        print_status "🎉 All services are healthy!"
    else
        print_error "💥 Some services are not healthy"
    fi
    
    exit $exit_code
}

# Run main function
main
