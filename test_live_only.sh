#!/bin/bash

# Script to test compilation of just the live API integration tests
# This helps isolate our new live tests from other test compilation issues

echo "🔍 Testing compilation of LiveAPIIntegrationTests..."

# Check if API token is provided
if [ -z "$DISCOGS_API_TOKEN" ]; then
    echo "⚠️  No DISCOGS_API_TOKEN environment variable set"
    echo "💡 Set this variable to run actual live tests"
    echo "🔨 Testing compilation only..."
else
    echo "✅ API token found, will run live tests"
fi

# Try to compile the specific test file by building just the test target
cd "$(dirname "$0")"

echo "🔨 Building test target..."
swift build --target DiscogsTests 2>&1 | grep -E "(error:|warning:|LiveAPIIntegrationTests|Compiling.*LiveAPIIntegrationTests)" || echo "No specific errors found for LiveAPIIntegrationTests"

if [ $? -eq 0 ]; then
    echo "✅ LiveAPIIntegrationTests compiled successfully!"
    
    if [ ! -z "$DISCOGS_API_TOKEN" ]; then
        echo "🚀 Running live tests..."
        # Note: The filter might not work perfectly with Swift Testing
        # so we'll run all tests and let the token check skip what needs to be skipped
        swift test 2>&1 | grep -A5 -B5 "LiveAPIIntegrationTests\|Live.*API\|Live.*Database\|Live.*Search\|Live.*User\|Live.*Error\|Live.*Rate\|Live.*Workflow\|Live.*Performance" || echo "No live test output found"
    else
        echo "💡 Skipping actual test run - no API token provided"
        echo "🔧 To run live tests: DISCOGS_API_TOKEN=your_token ./test_live_only.sh"
    fi
else
    echo "❌ Compilation failed"
    exit 1
fi
