# Getting Started with Discogs Swift SDK

Learn how to integrate and use the Discogs Swift SDK in your project.

## Overview

The Discogs Swift SDK provides a modern, type-safe interface to the Discogs API. This guide will walk you through the basic setup and common usage patterns.

## Installation

### Swift Package Manager

Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/briannadoubt/Discogs.git", from: "1.0.0")
]
```

Then import the module in your Swift files:

```swift
import Discogs
```

### Xcode Project

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/briannadoubt/Discogs.git`
3. Select your desired version range
4. Add the package to your target

## Basic Setup

### 1. Get Your API Token

Before using the SDK, you need a Discogs API token:

1. Visit [Discogs Developer Settings](https://www.discogs.com/settings/developers)
2. Create a new application or use an existing one
3. Generate a personal access token

### 2. Initialize the Client

```swift
import Discogs

let discogs = Discogs(
    token: "YOUR_PERSONAL_ACCESS_TOKEN",
    userAgent: "YourApp/1.0.0 +https://yourapp.com"
)
```

> Important: Always include a descriptive User-Agent string that identifies your application.

## Common Use Cases

### Searching the Database

```swift
// Search for releases
let releases = try await discogs.search.releases(query: "Daft Punk")

// Search for artists
let artists = try await discogs.search.artists(query: "Pink Floyd")

// Advanced search with parameters
let searchResults = try await discogs.search.search(
    query: "techno",
    type: .release,
    genre: "Electronic",
    year: 2023
)
```

### Getting Detailed Information

```swift
// Get release details
let release = try await discogs.database.getRelease(id: 249504)
print("Title: \(release.title)")
print("Year: \(release.year ?? 0)")

// Get artist information
let artist = try await discogs.database.getArtist(id: 1)
print("Artist: \(artist.name)")

// Get master release
let master = try await discogs.database.getMaster(id: 1327)
print("Master: \(master.title)")
```

### Working with User Collections

```swift
// Get user's collection folders
let folders = try await discogs.collection.getFolders(username: "username")

// Get items in a folder
let items = try await discogs.collection.getCollectionItems(
    username: "username",
    folderId: 0
)

// Add item to collection
try await discogs.collection.addToCollection(
    username: "username",
    folderId: 1,
    releaseId: 249504
)
```

### Handling Pagination

Many API responses include pagination. The SDK makes it easy to work with paginated results:

```swift
let searchResults = try await discogs.search.releases(query: "jazz")

// Access pagination info
if let pagination = searchResults.pagination {
    print("Page \(pagination.page) of \(pagination.pages)")
    print("Total items: \(pagination.items)")
}

// Get next page
if let nextPageUrl = searchResults.pagination?.urls?.next {
    let nextPage = try await discogs.search.releases(
        query: "jazz",
        page: searchResults.pagination!.page + 1
    )
}
```

### Error Handling

The SDK provides comprehensive error handling:

```swift
do {
    let release = try await discogs.database.getRelease(id: 123456)
} catch let error as DiscogsError {
    switch error {
    case .notFound:
        print("Release not found")
    case .rateLimited:
        print("Rate limit exceeded")
    case .unauthorized:
        print("Invalid API token")
    case .networkError(let underlyingError):
        print("Network error: \(underlyingError)")
    default:
        print("Other error: \(error)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Rate Limiting

The SDK automatically handles rate limiting:

```swift
// Check current rate limit status
if let rateLimit = await discogs.rateLimit {
    print("Remaining requests: \(rateLimit.remaining)")
    print("Reset time: \(rateLimit.resetTime)")
}

// The SDK will automatically wait when rate limits are hit
// You can also configure rate limiting behavior
let discogs = Discogs(
    token: "your_token",
    userAgent: "YourApp/1.0.0",
    rateLimitConfig: RateLimitConfig(
        maxRetries: 3,
        baseDelay: 1.0
    )
)
```

## Protocol-Oriented Architecture

For enhanced testability and flexibility, use the protocol-oriented approach:

```swift
// Use protocol types for dependency injection
let httpClient: HTTPClientProtocol = Discogs(
    token: "your_token",
    userAgent: "YourApp/1.0.0"
)

let databaseService = DatabaseService(httpClient: httpClient)
let release = try await databaseService.getRelease(id: 249504)
```

## Next Steps

- Learn about <doc:Authentication> for advanced auth scenarios
- Explore <doc:DependencyInjection> for testable architecture
- Check out <doc:BestPractices> for optimal usage patterns
- Review <doc:ErrorHandling> for robust error management
