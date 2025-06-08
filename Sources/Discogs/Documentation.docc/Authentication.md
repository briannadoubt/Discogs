# Authentication

Learn about authentication options for the Discogs API.

## Overview

The Discogs API supports two main authentication methods:
- **Personal Access Tokens** (recommended for most use cases)
- **OAuth 1.0a** (for applications that need to access user data on behalf of others)

## Personal Access Tokens

Personal access tokens are the simplest way to authenticate with the Discogs API. They're perfect for:
- Personal applications
- Server-side applications
- Development and testing

### Getting a Token

1. Go to [Discogs Developer Settings](https://www.discogs.com/settings/developers)
2. Create a new application or select an existing one
3. Click "Generate new token"
4. Copy the token and store it securely

### Using a Token

```swift
import Discogs

let discogs = Discogs(
    token: "YOUR_PERSONAL_ACCESS_TOKEN",
    userAgent: "YourApp/1.0.0 +https://yourapp.com"
)

// The token is automatically included in all requests
let release = try await discogs.database.getRelease(id: 249504)
```

### Token Security

> Important: Keep your tokens secure and never expose them in client-side code or public repositories.

Best practices:
- Store tokens in environment variables or secure configuration
- Use different tokens for development and production
- Regularly rotate tokens
- Monitor token usage through the Discogs developer console

## OAuth 1.0a (Advanced)

OAuth is more complex but provides better security for applications that access user data on behalf of others.

### OAuth Flow

The OAuth flow involves several steps:

1. **Request Token**: Get a temporary request token
2. **User Authorization**: Redirect user to Discogs for authorization
3. **Access Token**: Exchange the authorized request token for an access token

### Implementation Example

```swift
import Discogs

// Step 1: Initialize OAuth client
let oauth = DiscogsOAuth(
    consumerKey: "YOUR_CONSUMER_KEY",
    consumerSecret: "YOUR_CONSUMER_SECRET",
    userAgent: "YourApp/1.0.0"
)

// Step 2: Get request token
let requestToken = try await oauth.getRequestToken()

// Step 3: Build authorization URL
let authURL = oauth.buildAuthorizationURL(requestToken: requestToken.token)
// Redirect user to authURL

// Step 4: After user authorization, exchange for access token
let accessToken = try await oauth.getAccessToken(
    requestToken: requestToken.token,
    requestTokenSecret: requestToken.secret,
    verifier: "VERIFIER_FROM_CALLBACK"
)

// Step 5: Use access token for API calls
let discogs = Discogs(
    accessToken: accessToken.token,
    accessTokenSecret: accessToken.secret,
    consumerKey: "YOUR_CONSUMER_KEY",
    consumerSecret: "YOUR_CONSUMER_SECRET",
    userAgent: "YourApp/1.0.0"
)
```

## Rate Limiting with Authentication

Authenticated requests have higher rate limits than anonymous requests:

- **Anonymous**: 25 requests per minute
- **Authenticated**: 60 requests per minute

The SDK automatically handles rate limiting and will wait when limits are exceeded.

## User-Agent Requirements

The Discogs API requires a descriptive User-Agent header that includes:
- Your application name
- Version number
- Contact information (optional but recommended)

### Good User-Agent Examples

```swift
// Application name and version
"MyMusicApp/1.0.0"

// With contact info
"MyMusicApp/1.0.0 +https://myapp.com/contact"

// More detailed
"MyMusicApp/1.0.0 (iOS; com.company.myapp) +support@company.com"
```

### Bad User-Agent Examples

```swift
// Too generic
"Swift/1.0"

// No version info
"MyApp"

// Default User-Agent
"URLSession/1.0"
```

## Testing Authentication

When testing your application, you can use a test token or mock authentication:

```swift
// For testing with a real token
let testDiscogs = Discogs(
    token: "TEST_TOKEN",
    userAgent: "MyApp/1.0.0-test"
)

// For unit testing with mock authentication
let mockClient = MockHTTPClient()
let databaseService = DatabaseService(httpClient: mockClient)
```

## Error Handling

Authentication errors are handled through the ``DiscogsError`` enum:

```swift
do {
    let release = try await discogs.database.getRelease(id: 123)
} catch DiscogsError.unauthorized {
    // Invalid or expired token
    print("Authentication failed - check your token")
} catch DiscogsError.forbidden {
    // Valid token but insufficient permissions
    print("Access denied - token doesn't have required permissions")
} catch {
    print("Other error: \(error)")
}
```

## Best Practices

### Token Management

- Store tokens securely (Keychain on iOS/macOS)
- Don't hardcode tokens in your application
- Use environment variables for development
- Consider token refresh strategies for long-running applications

### User-Agent Management

- Include your application name and version
- Update User-Agent when releasing new versions
- Include contact information for API support

### Request Optimization

- Cache responses when possible
- Use pagination efficiently
- Respect rate limits
- Implement proper error handling and retry logic

## Related Topics

- <doc:ErrorHandling> - Handling authentication errors
- <doc:RateLimiting> - Understanding rate limits
- <doc:BestPractices> - General usage recommendations
