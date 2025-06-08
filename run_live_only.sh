#!/bin/zsh

# Standalone Live Test Runner
# This script temporarily moves other test files to run only the live tests

echo "🚀 Running ONLY Live API Integration Tests"
echo "=========================================="

# Check if API token is set
if [[ -z "$DISCOGS_API_TOKEN" ]]; then
    echo "❌ No DISCOGS_API_TOKEN found. Please set it first."
    exit 1
else
    echo "✅ API token found: ${DISCOGS_API_TOKEN:0:10}..."
fi

cd "$(dirname "$0")"

# Create backup directory
mkdir -p /tmp/discogs_test_backup

# Move problematic test files temporarily
echo "📦 Backing up other test files..."
mv Tests/DiscogsTests/EndToEndAPIComplianceTests.swift /tmp/discogs_test_backup/ 2>/dev/null || true
mv Tests/DiscogsTests/ErrorHandlingAndRateLimitingTests.swift /tmp/discogs_test_backup/ 2>/dev/null || true
mv Tests/DiscogsTests/FinalIntegrationTests.swift /tmp/discogs_test_backup/ 2>/dev/null || true
mv Tests/DiscogsTests/DependencyInjectionIntegrationTests.swift /tmp/discogs_test_backup/ 2>/dev/null || true

echo "🧪 Running live tests..."
swift test --filter LiveAPIIntegrationTests

# Store the exit code
TEST_RESULT=$?

echo ""
echo "📦 Restoring test files..."
# Restore the files
mv /tmp/discogs_test_backup/* Tests/DiscogsTests/ 2>/dev/null || true
rmdir /tmp/discogs_test_backup 2>/dev/null || true

echo ""
if [[ $TEST_RESULT -eq 0 ]]; then
    echo "✅ Live tests completed successfully!"
else
    echo "❌ Live tests failed with code: $TEST_RESULT"
fi

echo ""
echo "📊 Live Test Results:"
echo "• Tests run against real Discogs API"
echo "• Token: ${DISCOGS_API_TOKEN:0:10}..."
echo "• Network calls made to verify actual API responses"

exit $TEST_RESULT
