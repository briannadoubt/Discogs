#!/bin/bash

echo "🔍 Verifying Documentation Setup..."
echo

# Check if documentation workflow exists
if [ -f ".github/workflows/documentation.yml" ]; then
    echo "✅ Documentation workflow file exists"
else
    echo "❌ Documentation workflow file missing"
    exit 1
fi

# Check if Swift-DocC dependency is in Package.swift
if grep -q "swift-docc-plugin" Package.swift; then
    echo "✅ Swift-DocC plugin dependency found in Package.swift"
else
    echo "❌ Swift-DocC plugin dependency missing from Package.swift"
    exit 1
fi

# Check if documentation catalog exists
if [ -d "Sources/Discogs/Documentation.docc" ]; then
    echo "✅ Documentation catalog directory exists"
    
    # Count documentation files
    doc_count=$(find Sources/Discogs/Documentation.docc -name "*.md" | wc -l)
    echo "📚 Found $doc_count documentation articles"
    
    # List documentation files
    echo "📄 Documentation files:"
    find Sources/Discogs/Documentation.docc -name "*.md" -exec basename {} \; | sort | sed 's/^/   - /'
else
    echo "❌ Documentation catalog directory missing"
    exit 1
fi

# Test local documentation build
echo
echo "🔨 Testing local documentation build..."
if swift package generate-documentation > /dev/null 2>&1; then
    echo "✅ Local documentation build successful"
else
    echo "❌ Local documentation build failed"
    echo "💡 Running with verbose output:"
    swift package generate-documentation
    exit 1
fi

# Test static hosting build
echo
echo "🌐 Testing static hosting build..."
if swift package --allow-writing-to-directory /tmp/test-docs generate-documentation --target Discogs --disable-indexing --transform-for-static-hosting --hosting-base-path Discogs --output-path /tmp/test-docs > /dev/null 2>&1; then
    echo "✅ Static hosting build successful"
    rm -rf /tmp/test-docs
else
    echo "❌ Static hosting build failed"
    echo "💡 Running with verbose output:"
    swift package --allow-writing-to-directory /tmp/test-docs generate-documentation --target Discogs --disable-indexing --transform-for-static-hosting --hosting-base-path Discogs --output-path /tmp/test-docs
    exit 1
fi

echo
echo "🎉 All documentation setup verification checks passed!"
echo
echo "📋 Next Steps:"
echo "   1. Check GitHub Actions workflow status at:"
echo "      https://github.com/$(git config remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/actions"
echo
echo "   2. Enable GitHub Pages if not already enabled:"
echo "      - Go to Settings > Pages"
echo "      - Set Source to 'GitHub Actions'"
echo "      - Documentation will be available at:"
echo "        https://$(git config remote.origin.url | sed 's/.*github.com[:/]\([^/]*\)\/\([^/]*\).*/\1.github.io\/\2/' | sed 's/\.git$//')"
echo
echo "   3. Verify documentation deployment status:"
echo "      - Check the Documentation workflow in GitHub Actions"
echo "      - Monitor the GitHub Pages deployment"
echo
echo "✨ Documentation system is ready for deployment!"
