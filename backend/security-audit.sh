#!/bin/bash

# ════════════════════════════════════════════════════════════════
# SPACESHARE SECURITY AUDIT SCRIPT
# ════════════════════════════════════════════════════════════════

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     SPACESHARE BACKEND SECURITY AUDIT & VERIFICATION           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo "   Copy .env.example to .env and configure"
    exit 1
fi

# ════════════════════════════════════════════════════════════════
# 1. ENVIRONMENT VARIABLES CHECK
# ════════════════════════════════════════════════════════════════
echo "📋 Checking environment variables..."

required_vars=(
    "JWT_SECRET"
    "NODE_ENV"
    "DATABASE_URL"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if grep -q "^${var}=" .env; then
        echo -e "${GREEN}  ✅ ${var}${NC}"
    else
        echo -e "${RED}  ❌ ${var} (missing)${NC}"
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing critical variables: ${missing_vars[*]}${NC}"
    exit 1
fi

# ════════════════════════════════════════════════════════════════
# 2. FILE PERMISSIONS CHECK
# ════════════════════════════════════════════════════════════════
echo ""
echo "📁 Checking file permissions..."

files_to_check=(
    ".env"
    "serviceAccountKey.json"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
        echo "  $file: $perms"
        
        # Check if readable by others
        if [ "$perms" != "600" ] && [ "$perms" != "400" ]; then
            echo -e "${YELLOW}  ⚠️  ${file} has permissive permissions (should be 400 or 600)${NC}"
        fi
    fi
done

# ════════════════════════════════════════════════════════════════
# 3. DEPENDENCY VULNERABILITIES CHECK
# ════════════════════════════════════════════════════════════════
echo ""
echo "🔍 Checking for dependency vulnerabilities..."

if npm audit --omit=dev > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ No high-severity vulnerabilities found${NC}"
else
    echo -e "${YELLOW}  ⚠️  Run 'npm audit' for details${NC}"
fi

# ════════════════════════════════════════════════════════════════
# 4. NODE_ENV VERIFICATION
# ════════════════════════════════════════════════════════════════
echo ""
echo "🌍 Checking NODE_ENV..."

node_env=$(grep "^NODE_ENV=" .env | cut -d'=' -f2)
if [ "$node_env" = "production" ]; then
    echo -e "${GREEN}  ✅ Production environment detected${NC}"
    echo -e "${YELLOW}  ⚠️  Ensure all security measures are in place${NC}"
else
    echo -e "${YELLOW}  ℹ️  NODE_ENV: $node_env (non-production)${NC}"
fi

# ════════════════════════════════════════════════════════════════
# 5. SECURITY MIDDLEWARE CHECK
# ════════════════════════════════════════════════════════════════
echo ""
echo "🔐 Checking security middleware files..."

middleware_files=(
    "middleware/security.js"
    "middleware/auth.js"
    "middleware/encryption.js"
    "middleware/csrf.js"
    "middleware/inputValidation.js"
    "middleware/dataRedaction.js"
    "middleware/secretsManager.js"
)

for file in "${middleware_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✅ ${file}${NC}"
    else
        echo -e "${RED}  ❌ ${file} (missing)${NC}"
    fi
done

# ════════════════════════════════════════════════════════════════
# 6. DATABASE SECURITY FILES CHECK
# ════════════════════════════════════════════════════════════════
echo ""
echo "💾 Checking database security configurations..."

db_files=(
    "security/postgresql-security.sql"
    "security/mongodb-security.js"
)

for file in "${db_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✅ ${file}${NC}"
    else
        echo -e "${RED}  ❌ ${file} (missing)${NC}"
    fi
done

# ════════════════════════════════════════════════════════════════
# 7. FIRESTORE & STORAGE RULES CHECK
# ════════════════════════════════════════════════════════════════
echo ""
echo "🔥 Checking Firebase security rules..."

if [ -f "../firestore.rules" ]; then
    if grep -q "default deny" ../firestore.rules 2>/dev/null; then
        echo -e "${GREEN}  ✅ Firestore rules have default deny${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Review Firestore rules for security${NC}"
    fi
fi

if [ -f "../storage.rules" ]; then
    if grep -q "allow read, write: if false" ../storage.rules; then
        echo -e "${GREEN}  ✅ Storage rules have default deny${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Review Storage rules for security${NC}"
    fi
fi

# ════════════════════════════════════════════════════════════════
# 8. SUMMARY
# ════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Security audit completed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and apply database security configurations"
echo "  2. Deploy security middleware in production"
echo "  3. Configure monitoring and alerting"
echo "  4. Run regular security audits"
echo "  5. Keep dependencies updated (npm audit fix)"
echo ""
