# Discogs API Swift Package

[![CI](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml)
[![Release](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml)
[![Security](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgrey)
![Swift](https://img.shields.io/badge/swift-6.1-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

A modern, comprehensive Swift package for accessing the [Discogs API](https://www.discogs.com/developers). This package provides a type-safe, async/await interface to interact with the Discogs database, marketplace, and user collections.

## Features

- ✅ **Complete API Coverage**: Database, Marketplace, Collection, User, Search, and Wantlist services
- ✅ **Modern Swift**: Built with Swift 6.1, async/await, and Sendable protocols
- ✅ **Multi-Platform**: Support for iOS 15+, macOS 12+, tvOS 15+, watchOS 8+, visionOS 1+, and Linux
- ✅ **Type Safety**: Comprehensive data models with Codable support
- ✅ **Authentication**: Personal Access Token and OAuth support
- ✅ **Rate Limiting**: Built-in rate limit handling and monitoring
- ✅ **Error Handling**: Detailed error types for robust error handling
- ✅ **Dependency Injection**: Testable architecture with protocol-based design
- ✅ **Comprehensive Testing**: Unit, integration, and live API tests
- ✅ **CI/CD Pipeline**: Automated testing, security audits, and release management

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/Discogs.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. Go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/YOUR_USERNAME/Discogs.git`
3. Select your desired version range

## Quick Start

### Personal Access Token (Recommended)

```swift
import Discogs

// Initialize the client with your personal access token
let discogs = Discogs(
    token: "YOUR_PERSONAL_ACCESS_TOKEN",
    userAgent: "YourApp/1.0.0 +https://yourapp.com"
)

// Search for releases
do {
    let searchResults = try await discogs.search.releases(
        query: "Pink Floyd Dark Side of the Moon"
    )
    print("Found \(searchResults.results.count) releases")
} catch {
    print("Search failed: \(error)")
}

// Get release details
do {
    let release = try await discogs.database.getRelease(id: 249504)
    print("Release: \(release.title) by \(release.artists?.first?.name ?? "Unknown")")
} catch {
    print("Failed to get release: \(error)")
}
```

### OAuth Authentication

```swift
import Discogs

let discogs = Discogs(
    consumerKey: "YOUR_CONSUMER_KEY",
    consumerSecret: "YOUR_CONSUMER_SECRET", 
    accessToken: "YOUR_ACCESS_TOKEN",
    accessTokenSecret: "YOUR_ACCESS_TOKEN_SECRET",
    userAgent: "YourApp/1.0.0 +https://yourapp.com"
)
```

## API Services

### Database Service

Access the Discogs database for releases, artists, labels, and masters.

```swift
// Get a release
let release = try await discogs.database.getRelease(id: 249504)

// Get an artist
let artist = try await discogs.database.getArtist(id: 108713)

// Get a label
let label = try await discogs.database.getLabel(id: 1)

// Get a master release
let master = try await discogs.database.getMaster(id: 18512)
```

### Search Service

Search across the Discogs database.

```swift
// Search for releases
let releases = try await discogs.search.releases(
    query: "Miles Davis",
    genre: "Jazz",
    year: 1959
)

// Search for artists
let artists = try await discogs.search.artists(query: "John Coltrane")

// Search for labels
let labels = try await discogs.search.labels(query: "Blue Note")
```

### Collection Service

Manage user collections (requires authentication).

```swift
// Get user's collection
let collection = try await discogs.collection.getCollection(username: "username")

// Add item to collection
try await discogs.collection.addToCollection(
    username: "username",
    releaseId: 249504
)

// Get collection value
let value = try await discogs.collection.getCollectionValue(username: "username")
```

### Marketplace Service

Access marketplace listings and statistics.

```swift
// Get marketplace listing
let listing = try await discogs.marketplace.getListing(id: 123456)

// Search marketplace
let listings = try await discogs.marketplace.search(
    releaseId: 249504,
    condition: .nearMint
)

// Get price suggestions
let price = try await discogs.marketplace.getPriceSuggestions(releaseId: 249504)
```

### User Service

Access user profiles and identity information.

```swift
// Get user identity (requires authentication)
let identity = try await discogs.user.getIdentity()

// Get user profile
let profile = try await discogs.user.getUser(username: "username")
```

### Wantlist Service

Manage user wantlists (requires authentication).

```swift
// Get user's wantlist
let wantlist = try await discogs.wantlist.getWantlist(username: "username")

// Add item to wantlist
try await discogs.wantlist.addToWantlist(
    username: "username",
    releaseId: 249504
)
```

## Rate Limiting

The package includes built-in rate limiting to respect Discogs API limits:

```swift
// Configure rate limiting
let rateLimitConfig = RateLimitConfig(
    maxRequestsPerMinute: 60,
    respectRateLimits: true,
    defaultDelay: 1.0
)

let discogs = Discogs(
    token: "YOUR_TOKEN",
    userAgent: "YourApp/1.0.0",
    rateLimitConfig: rateLimitConfig
)

// Check current rate limit status
if let rateLimit = await discogs.rateLimit {
    print("Remaining requests: \(rateLimit.remaining)")
    print("Reset time: \(rateLimit.resetTime)")
}
```

## Error Handling

The package provides comprehensive error handling:

```swift
do {
    let release = try await discogs.database.getRelease(id: 123)
} catch let error as DiscogsError {
    switch error {
    case .notFound:
        print("Release not found")
    case .rateLimitExceeded:
        print("Rate limit exceeded")
    case .unauthorized:
        print("Authentication required")
    case .networkError(let underlying):
        print("Network error: \(underlying)")
    case .decodingError(let underlying):
        print("Data parsing error: \(underlying)")
    case .apiError(let code, let message):
        print("API error \(code): \(message)")
    }
}
```

## Authentication

### Getting a Personal Access Token

1. Go to your [Discogs developer settings](https://www.discogs.com/settings/developers)
2. Click "Generate new token"
3. Use the generated token in your app

### OAuth Flow

For OAuth authentication, you'll need to:

1. Register your application at [Discogs Developer Settings](https://www.discogs.com/settings/developers)
2. Implement the OAuth flow to get access tokens
3. Use the tokens with the package

## Testing

The package includes comprehensive test coverage:

- **Unit Tests**: Test individual components and services
- **Integration Tests**: Test service interactions and data flow
- **Live API Tests**: Test against the actual Discogs API (optional)
- **Platform Tests**: Ensure compatibility across all supported platforms

Run tests locally:

```bash
# Run all tests
swift test

# Run only unit tests
swift test --filter DiscogsTests

# Run with live API testing (requires DISCOGS_API_TOKEN environment variable)
DISCOGS_API_TOKEN=your_token swift test
```

## Documentation

- [Discogs API Documentation](https://www.discogs.com/developers)
- [Package API Documentation](.github/README.md) - GitHub Actions setup and development guide

## Requirements

- **Swift**: 6.1 or later
- **iOS**: 15.0 or later
- **macOS**: 12.0 or later
- **tvOS**: 15.0 or later
- **watchOS**: 8.0 or later
- **visionOS**: 1.0 or later
- **Linux**: Ubuntu 20.04 or later

## Contributing

We welcome contributions! Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Run tests: `swift test`
3. Make your changes
4. Ensure tests pass
5. Submit a pull request

### CI/CD Pipeline

This package includes a comprehensive CI/CD pipeline with:

- ✅ Multi-platform builds (macOS, Ubuntu, iOS, tvOS, watchOS)
- ✅ Comprehensive testing (unit, integration, live API)
- ✅ Code quality analysis
- ✅ Security audits
- ✅ Automated releases
- ✅ Documentation generation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Discogs](https://www.discogs.com) for providing the comprehensive music database API
- The Swift community for excellent tools and libraries

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

---

**Note**: Replace `YOUR_USERNAME` in the badge URLs and installation instructions with your actual GitHub username before publishing.
