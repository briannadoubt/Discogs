#!/bin/bash

# CI/CD Setup Verification Script
# Verifies that all GitHub Actions workflows and documentation are properly configured

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Discogs Swift Package CI/CD Verification${NC}"
echo "========================================"
echo

success_count=0
total_checks=0

check_file() {
    local file="$1"
    local description="$2"
    total_checks=$((total_checks + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $description${NC}"
        success_count=$((success_count + 1))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

check_yaml_syntax() {
    local file="$1"
    local description="$2"
    total_checks=$((total_checks + 1))
    
    if [ -f "$file" ]; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✅ $description${NC}"
            success_count=$((success_count + 1))
            return 0
        else
            echo -e "${RED}❌ $description (YAML syntax error)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ $description (file not found)${NC}"
        return 1
    fi
}

check_placeholder() {
    local file="$1"
    local placeholder="$2"
    local description="$3"
    total_checks=$((total_checks + 1))
    
    if [ -f "$file" ]; then
        if grep -q "$placeholder" "$file"; then
            echo -e "${YELLOW}⚠️  $description (contains placeholder: $placeholder)${NC}"
        else
            echo -e "${GREEN}✅ $description${NC}"
            success_count=$((success_count + 1))
        fi
    else
        echo -e "${RED}❌ $description (file not found)${NC}"
    fi
}

echo "📁 Core Files:"
check_file "Package.swift" "Swift Package manifest"
check_file "README.md" "Main README documentation"

echo
echo "🚀 GitHub Actions Workflows:"
check_yaml_syntax ".github/workflows/ci.yml" "CI workflow syntax"
check_yaml_syntax ".github/workflows/release.yml" "Release workflow syntax"
check_yaml_syntax ".github/workflows/maintenance.yml" "Maintenance workflow syntax"
check_yaml_syntax ".github/workflows/security.yml" "Security workflow syntax"

echo
echo "📖 Documentation:"
check_file ".github/README.md" "GitHub Actions documentation"
check_file ".github/BADGES.md" "Badge configuration guide"
check_file ".github/SETUP_CHECKLIST.md" "Setup checklist"

echo
echo "🔧 Setup Scripts:"
check_file "update_username.sh" "Username replacement script"

echo
echo "🔍 Placeholder Check:"
check_placeholder "README.md" "YOUR_USERNAME" "README.md username placeholders"
check_placeholder ".github/BADGES.md" "YOUR_USERNAME" "BADGES.md username placeholders"

echo
echo "📊 Package Structure:"
total_checks=$((total_checks + 1))
if [ -d "Sources/Discogs" ]; then
    source_count=$(find Sources/Discogs -name "*.swift" | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Source files found ($source_count Swift files)${NC}"
    success_count=$((success_count + 1))
else
    echo -e "${RED}❌ Sources/Discogs directory not found${NC}"
fi

total_checks=$((total_checks + 1))
if [ -d "Tests/DiscogsTests" ]; then
    test_count=$(find Tests/DiscogsTests -name "*.swift" | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Test files found ($test_count Swift test files)${NC}"
    success_count=$((success_count + 1))
else
    echo -e "${RED}❌ Tests/DiscogsTests directory not found${NC}"
fi

echo
echo "========================================"
echo -e "${BLUE}📈 Verification Results:${NC}"
echo "Passed: $success_count/$total_checks checks"

if [ $success_count -eq $total_checks ]; then
    echo -e "${GREEN}🎉 All checks passed! Your CI/CD setup is ready.${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Replace YOUR_USERNAME placeholders (run ./update_username.sh)"
    echo "2. Commit and push your changes"
    echo "3. Check GitHub Actions tab for first workflow run"
    echo "4. Optionally add DISCOGS_API_TOKEN secret for live API tests"
elif [ $success_count -gt $((total_checks * 3 / 4)) ]; then
    echo -e "${YELLOW}⚠️  Setup is mostly complete with minor issues.${NC}"
    echo "Review the failed checks above and address any missing files."
else
    echo -e "${RED}❌ Setup needs attention. Several components are missing.${NC}"
    echo "Please ensure all workflow files and documentation are in place."
fi

echo
echo -e "${BLUE}📁 Repository Structure:${NC}"
echo "├── .github/"
echo "│   ├── workflows/ (CI/CD pipelines)"
echo "│   ├── README.md (Actions documentation)"
echo "│   ├── BADGES.md (Badge setup guide)"
echo "│   └── SETUP_CHECKLIST.md (Setup instructions)"
echo "├── Sources/Discogs/ (Swift source code)"
echo "├── Tests/DiscogsTests/ (Test suite)"
echo "├── Package.swift (SPM manifest)"
echo "├── README.md (Main documentation)"
echo "└── update_username.sh (Helper script)"
