#!/usr/bin/env bash
# ============================================================================
# Desby OS — EC2 Deployment Script
# ============================================================================
# Run this LOCALLY (your Mac) to build and deploy to the EC2.
#
# Usage:
#   chmod +x deploy/scripts/deploy.sh
#   ./deploy/scripts/deploy.sh
#
# Prerequisites:
#   - Flutter SDK installed locally
#   - korra-ai-key.pem in ~/Downloads
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PEM_KEY="$HOME/Downloads/korra-ai-key.pem"
SSH_ACCESS="ubuntu@korra.work"
REMOTE_WEB_DIR="/var/www/desby/web"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/web"

echo "🚀 Desby OS — EC2 Deployment"
echo "============================="
echo "Target:   $SSH_ACCESS"
echo ""

# Step 1: Build Flutter web
echo "📦 Step 1: Building Flutter web..."
cd "$PROJECT_ROOT"
flutter build web --release --dart-define=ENV=production
echo "✅ Build complete"
echo ""

# Step 2: Create remote directory
echo "📁 Step 2: Preparing remote directory..."
ssh -i "$PEM_KEY" -o StrictHostKeyChecking=no "$SSH_ACCESS" \
    "sudo mkdir -p $REMOTE_WEB_DIR && sudo chown -R \$(whoami):\$(whoami) $REMOTE_WEB_DIR"
echo "✅ Remote directory ready"
echo ""

# Step 3: Sync build output
echo "📤 Step 3: Syncing build to EC2..."
rsync -avz --delete \
    -e "ssh -i $PEM_KEY -o StrictHostKeyChecking=no" \
    "$BUILD_DIR/" "$SSH_ACCESS:$REMOTE_WEB_DIR/"
echo "✅ Files synced"
echo ""

# Step 4: Upload Nginx config
echo "🔧 Step 4: Uploading Nginx config..."
scp -i "$PEM_KEY" -o StrictHostKeyChecking=no \
    "$PROJECT_ROOT/deploy/nginx/desby.app.conf" "$SSH_ACCESS:/tmp/desby.app.conf"
ssh -i "$PEM_KEY" -o StrictHostKeyChecking=no "$SSH_ACCESS" \
    "sudo cp /tmp/desby.app.conf /etc/nginx/sites-available/desby.app"
echo "✅ Nginx config uploaded"
echo ""

# Step 5: Enable site and reload
echo "🔄 Step 5: Enabling site and reloading Nginx..."
ssh -i "$PEM_KEY" -o StrictHostKeyChecking=no "$SSH_ACCESS" << 'REMOTECommands'
    sudo ln -sf /etc/nginx/sites-available/desby.app /etc/nginx/sites-enabled/desby.app
    sudo nginx -t && sudo systemctl reload nginx
    echo "✅ Nginx reloaded"
REMOTECommands
echo ""

# Step 6: SSL
echo "🔒 Step 6: SSL setup..."
ssh -i "$PEM_KEY" -o StrictHostKeyChecking=no "$SSH_ACCESS" << 'REMOTECommands'
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        sudo apt update && sudo apt install -y certbot python3-certbot-nginx
    fi
    if [ ! -d /etc/letsencrypt/live/desby.app ]; then
        echo "Requesting SSL certificate..."
        sudo certbot --nginx -d desby.app --non-interactive --agree-tos --email admin@desby.app
    else
        echo "SSL cert already exists, renewing..."
        sudo certbot renew --quiet
    fi
REMOTECommands
echo "✅ SSL configured"
echo ""

echo "=========================================="
echo "✅ Deployment complete!"
echo ""
echo "🌐 Visit: https://desby.app"
echo ""
echo "First deployment checklist:"
echo "  1. Point desby.app DNS A record to this EC2's public IP"
echo "  2. Port 80/443 open in EC2 security group"
echo "  3. Korra Docker container running on port 8080"
echo "=========================================="
