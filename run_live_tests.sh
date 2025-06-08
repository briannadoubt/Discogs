#!/bin/zsh

# Live API Test Runner for Discogs Swift Package
# This script helps set up and run live integration tests

echo "🚀 Discogs Swift Package - Live API Integration Tests"
echo "======================================================"

# Check if API token is set
if [[ -z "$DISCOGS_API_TOKEN" ]]; then
    echo ""
    echo "⚠️  No Discogs API token found in environment variables"
    echo ""
    echo "To run live tests, you need a Discogs API token:"
    echo "1. Go to https://www.discogs.com/settings/developers"
    echo "2. Create a new application or use an existing one"
    echo "3. Generate a personal access token"
    echo "4. Set the environment variable:"
    echo ""
    echo "   export DISCOGS_API_TOKEN=\"your_token_here\""
    echo ""
    echo "💡 You can also add this to your ~/.zshrc file for persistence"
    echo ""
    read -q "?Do you want to continue with mock tests only? (y/n): "
    echo ""
    if [[ $REPLY != "y" ]]; then
        echo "Exiting..."
        exit 0
    fi
else
    echo "✅ Discogs API token found: ${DISCOGS_API_TOKEN:0:10}..."
    echo ""
fi

# Run the tests
echo "🧪 Running live integration tests..."
echo ""

# Change to the package directory
cd "$(dirname "$0")"

# Run the live tests specifically
echo "Running live API integration tests..."
swift test --filter LiveAPIIntegrationTests

echo ""
echo "📊 Test Results Summary:"
echo "========================"

if [[ $? -eq 0 ]]; then
    echo "✅ All live integration tests passed!"
    echo ""
    echo "🎉 Your Discogs Swift package is working correctly with the live API!"
    echo ""
    echo "What was tested:"
    echo "• Database service (artists, releases, labels)"
    echo "• Search service (with filters)"
    echo "• User service (identity)"
    echo "• Error handling (invalid requests)"
    echo "• Rate limiting (multiple requests)"
    echo "• Complete workflow (search → details)"
    echo "• Performance (response times)"
else
    echo "❌ Some tests failed. Check the output above for details."
    echo ""
    echo "Common issues:"
    echo "• Invalid or expired API token"
    echo "• Network connectivity problems"
    echo "• Rate limiting (try again later)"
    echo "• API endpoints temporarily unavailable"
fi

echo ""
echo "📚 For more information:"
echo "• Discogs API docs: https://www.discogs.com/developers/"
echo "• Rate limits: https://www.discogs.com/developers/#page:home,header:home-rate-limiting"
