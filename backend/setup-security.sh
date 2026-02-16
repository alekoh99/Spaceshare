#!/bin/bash

# ════════════════════════════════════════════════════════════════
# SPACESHARE SECURITY SETUP SCRIPT
# ════════════════════════════════════════════════════════════════

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         SPACESHARE SECURITY INITIALIZATION SCRIPT              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created. Update it with your values."
else
    echo "✅ .env file already exists"
fi

# Step 2: Set proper permissions
echo ""
echo "🔐 Setting file permissions..."
chmod 600 .env
if [ -f serviceAccountKey.json ]; then
    chmod 600 serviceAccountKey.json
fi
echo "✅ File permissions updated"

# Step 3: Generate secrets
echo ""
echo "🔑 Generating secure secrets..."
echo ""
echo "Add these to your .env file:"
echo "────────────────────────────────────"
bash generate-secrets.sh
echo "────────────────────────────────────"
echo ""

# Step 4: Install dependencies
echo "📦 Installing dependencies..."
npm install

# Step 5: Run audit
echo ""
echo "🔍 Running security audit..."
bash security-audit.sh

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Security initialization complete!"
echo ""
echo "Next steps:"
echo "  1. Update .env with your configuration"
echo "  2. Run database migrations:"
echo "     - PostgreSQL: psql -U postgres -d spaceshare < migrations/001_enable_rls.sql"
echo "     - MongoDB: mongo < migrations/mongodb-indexes.js"
echo "  3. Deploy Firestore/Storage rules:"
echo "     firebase deploy --only firestore:rules,storage"
echo "  4. Start the server: npm start"
echo ""
