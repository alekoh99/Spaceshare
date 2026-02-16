#!/bin/bash

# ════════════════════════════════════════════════════════════════
# GENERATE SECURE ENVIRONMENT VARIABLES
# ════════════════════════════════════════════════════════════════

echo "🔐 Generating secure environment variables..."
echo ""

# Generate JWT_SECRET
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"

# Generate ENCRYPTION_KEY  
ENCRYPTION_KEY=$(openssl rand -base64 32)
echo "ENCRYPTION_KEY=$ENCRYPTION_KEY"

# Generate REQUEST_SIGNING_KEY
REQUEST_SIGNING_KEY=$(openssl rand -base64 32)
echo "REQUEST_SIGNING_KEY=$REQUEST_SIGNING_KEY"

# Generate SESSION_SECRET
SESSION_SECRET=$(openssl rand -base64 32)
echo "SESSION_SECRET=$SESSION_SECRET"

echo ""
echo "✅ Copy these values to your .env file"
echo ""
echo "⚠️  IMPORTANT:"
echo "  - Never share these secrets"
echo "  - Store in secure secret management system"
echo "  - Rotate periodically in production"
