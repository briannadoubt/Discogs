#!/bin/bash

# GitHub Username Replacement Script
# This script helps replace placeholder username in badge URLs and documentation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 GitHub Username Replacement Script${NC}"
echo "This script will replace 'YOUR_USERNAME' placeholders with your actual GitHub username."
echo

# Get GitHub username from user
read -p "Enter your GitHub username: " username

if [ -z "$username" ]; then
    echo -e "${RED}❌ Username cannot be empty${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 Replacing 'YOUR_USERNAME' with '$username'...${NC}"

# Files to update
files=(
    "README.md"
    ".github/BADGES.md"
    ".github/SETUP_CHECKLIST.md"
)

# Backup and replace
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  Updating $file..."
        # Create backup
        cp "$file" "$file.backup"
        # Replace placeholder
        sed -i.tmp "s/YOUR_USERNAME/$username/g" "$file"
        # Remove temp file (macOS compatibility)
        rm -f "$file.tmp"
        echo -e "  ${GREEN}✅ Updated $file${NC}"
    else
        echo -e "  ${YELLOW}⚠️  File not found: $file${NC}"
    fi
done

echo
echo -e "${GREEN}🎉 Username replacement complete!${NC}"
echo "The following files have been updated:"
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  - $file"
    fi
done

echo
echo "Backup files created (*.backup) - you can delete these once you're satisfied."
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the updated files"
echo "2. Commit and push your changes"
echo "3. Check the GitHub Actions tab after pushing"
echo "4. Add DISCOGS_API_TOKEN secret if you want live API testing"

# Verify the replacement worked
echo
echo -e "${GREEN}🔍 Verification:${NC}"
if grep -q "YOUR_USERNAME" README.md 2>/dev/null; then
    echo -e "${RED}❌ Some placeholders may still exist in README.md${NC}"
else
    echo -e "${GREEN}✅ README.md looks good${NC}"
fi
