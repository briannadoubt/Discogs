#!/bin/bash

echo "🔍 CI Ubuntu Fix Validation Script"
echo "=================================="
echo

# Test 1: Verify Swift 6.0 Ubuntu 22.04 availability
echo "📋 Test 1: Swift 6.0 Ubuntu 22.04 Availability"
SWIFT_URL="https://download.swift.org/swift-6.0-release/ubuntu2204/swift-6.0-RELEASE/swift-6.0-RELEASE-ubuntu22.04.tar.gz"
if curl -I "$SWIFT_URL" 2>/dev/null | grep -q "200 OK"; then
    echo "✅ Swift 6.0 for Ubuntu 22.04 is available"
else
    echo "❌ Swift 6.0 for Ubuntu 22.04 is NOT available"
fi
echo

# Test 2: Check current local Swift version
echo "📋 Test 2: Local Swift Version"
if command -v swift &> /dev/null; then
    echo "✅ Swift is installed: $(swift --version | head -1)"
else
    echo "❌ Swift is not installed locally"
fi
echo

# Test 3: Verify project builds
echo "📋 Test 3: Project Build Verification"
if swift build &> /dev/null; then
    echo "✅ Project builds successfully"
else
    echo "❌ Project build failed"
fi
echo

# Test 4: Check CI workflow syntax
echo "📋 Test 4: CI Workflow Syntax"
if command -v yq &> /dev/null; then
    if yq eval '.jobs.build-and-test.strategy.matrix.os' .github/workflows/ci.yml | grep -q "ubuntu-22.04"; then
        echo "✅ CI workflow uses ubuntu-22.04"
    else
        echo "❌ CI workflow doesn't use ubuntu-22.04"
    fi
else
    # Fallback grep check
    if grep -q "ubuntu-22.04" .github/workflows/ci.yml; then
        echo "✅ CI workflow contains ubuntu-22.04"
    else
        echo "❌ CI workflow doesn't contain ubuntu-22.04"
    fi
fi
echo

# Test 5: Verify Ubuntu Swift condition
echo "📋 Test 5: Ubuntu Swift Installation Condition"
if grep -q "matrix.os == 'ubuntu-22.04'" .github/workflows/ci.yml; then
    echo "✅ CI workflow has correct Ubuntu condition"
else
    echo "❌ CI workflow missing Ubuntu condition"
fi
echo

echo "🎉 Validation Complete!"
echo
echo "📊 Summary:"
echo "- All tests should pass ✅ for the CI fix to work properly"
echo "- The GitHub Actions should now build successfully on Ubuntu 22.04"
echo "- Monitor: https://github.com/briannadoubt/Discogs/actions"
