# ``Discogs``

A comprehensive, modern Swift package for the Discogs API with protocol-oriented architecture and full platform support.

## Overview

The **Discogs Swift SDK** provides seamless access to the [Discogs API](https://www.discogs.com/developers), offering a type-safe, async/await interface to interact with the world's largest music database, marketplace, and user collections.

Built with Swift 6.1 and designed for the modern Swift ecosystem, this package features:

- **🔒 Type-Safe**: Comprehensive data models with full Codable support
- **⚡ Modern Swift**: Built with async/await, actors, and Sendable protocols  
- **🌍 Cross-Platform**: iOS, macOS, tvOS, watchOS, visionOS, and Linux support
- **🛡️ Robust**: Built-in rate limiting, error handling, and retry mechanisms
- **🧪 Well-Tested**: 100% test success rate with unit, integration, and live API tests
- **📚 Complete**: Full API coverage including Database, Marketplace, Collections, and more
- **🏗️ Protocol-Oriented**: Dependency injection for testable, maintainable code

## Getting Started

### Installation

Add the package to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/briannadoubt/Discogs.git", from: "1.0.0")
]
```

### Quick Start

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

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Authentication>
- <doc:ErrorHandling>
- <doc:RateLimiting>

### API Services

- ``DatabaseService``
- ``SearchService``
- ``CollectionService``
- ``MarketplaceService``
- ``UserService``
- ``WantlistService``

### Core Types

- ``Discogs``
- ``DiscogsError``
- ``RateLimit``
- ``Pagination``

### Protocol-Oriented Architecture

- ``HTTPClientProtocol``
- ``DiscogsServiceProtocol``
- ``DependencyContainer``

### Data Models

- ``Release``
- ``Artist``
- ``MasterRelease``
- ``Label``
- ``UserProfile``
- ``SearchResult``

### Advanced Features

- <doc:DependencyInjection>
- <doc:Testing>
- <doc:BestPractices>
- <doc:PlatformSupport>

## Platform Support

This package supports all modern Apple platforms and Linux with minimum deployment targets optimized for modern Swift features.

## Community and Support

For community support, bug reports, and feature requests, please visit our GitHub repository.

## See Also

- [GitHub Repository](https://github.com/briannadoubt/Discogs)
- [Issue Tracker](https://github.com/briannadoubt/Discogs/issues)
- [Discussions](https://github.com/briannadoubt/Discogs/discussions)
- [Contributing Guide](https://github.com/briannadoubt/Discogs/blob/main/.github/CONTRIBUTING.md)

---

*Built with ❤️ for the music community*
