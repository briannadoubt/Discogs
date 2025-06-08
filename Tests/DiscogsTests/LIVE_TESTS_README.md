# Live API Integration Tests

This directory contains live integration tests that make actual network calls to the Discogs API to verify the Swift package works correctly with real API responses.

## Setup

### 1. Get a Discogs API Token

1. Go to [Discogs Developer Settings](https://www.discogs.com/settings/developers)
2. Create a new application or use an existing one
3. Generate a **Personal Access Token** (not OAuth - that's for user authentication)
4. Copy the token

### 2. Set Environment Variable

Add your token to your environment:

```bash
export DISCOGS_API_TOKEN="your_actual_token_here"
```

For persistence, add it to your `~/.zshrc` file:

```bash
echo 'export DISCOGS_API_TOKEN="your_actual_token_here"' >> ~/.zshrc
source ~/.zshrc
```

### 3. Run the Tests

#### Option A: Use the provided script
```bash
./run_live_tests.sh
```

#### Option B: Run with Swift directly
```bash
swift test --filter LiveAPIIntegrationTests
```

#### Option C: Run specific test cases
```bash
# Run just the database tests
swift test --filter "testLiveDatabaseArtistFetch"

# Run just the search tests  
swift test --filter "testLiveSearchArtist"

# Run the complete workflow test
swift test --filter "testLiveCompleteWorkflow"
```

## What Gets Tested

The live integration tests verify:

### 🎵 **Database Service**
- Fetch famous artists (The Beatles)
- Fetch famous releases (Abbey Road)
- Fetch record labels (Apple Records)
- Verify all model properties parse correctly

### 🔍 **Search Service**
- Artist search functionality
- Release search with filters (year, format)
- Search result pagination
- Search result model parsing

### 👤 **User Service**
- User identity fetching (requires authenticated token)
- User profile data parsing

### ⚠️ **Error Handling**
- Invalid resource IDs
- Network error scenarios
- Proper error type mapping

### ⏱️ **Rate Limiting**
- Multiple sequential requests
- Rate limit compliance
- Request timing and delays

### 🔄 **Complete Workflows**
- Search → Get Details flow
- Cross-service integration
- Real-world usage patterns

### 🚀 **Performance**
- Response time verification
- API responsiveness testing

## Rate Limiting

These tests are designed to be respectful of Discogs' API rate limits:

- Built-in delays between requests
- Limited number of test requests
- Uses well-known, stable data (famous artists/releases)
- Focuses on functional verification over load testing

## Expected Results

When working correctly, you should see output like:

```
✅ Successfully fetched artist: The Beatles
✅ Found 5 artist results  
✅ API response time: 0.847 seconds
✅ Complete workflow test passed!
```

## Troubleshooting

### Common Issues

1. **"No valid API token provided"**
   - Make sure `DISCOGS_API_TOKEN` environment variable is set
   - Verify the token is valid and not expired

2. **Network/timeout errors**
   - Check your internet connection
   - Discogs API might be temporarily unavailable

3. **Rate limit errors**
   - Wait a few minutes and try again
   - Reduce the number of concurrent tests

4. **Authentication errors**
   - Your token might be invalid or expired
   - Generate a new token from Discogs developer settings

### API Documentation

- [Discogs API Documentation](https://www.discogs.com/developers/)
- [Rate Limiting Guidelines](https://www.discogs.com/developers/#page:home,header:home-rate-limiting)
- [Authentication Guide](https://www.discogs.com/developers/#page:authentication)

## Test Data

The tests use well-known, stable Discogs data:

- **Artist ID 82730**: The Beatles
- **Release ID 1362270**: Abbey Road by The Beatles  
- **Label ID 20871**: Apple Records
- **Artist ID 1**: Very first artist in Discogs database

This ensures tests are reliable and won't break due to data changes.
