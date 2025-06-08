# Protocol-Oriented Dependency Injection Guide

This document explains how to use the new protocol-oriented dependency injection system in the Discogs Swift package.

## Overview

The Discogs Swift package now supports protocol-oriented dependency injection through the `HTTPClientProtocol` and `DiscogsServiceProtocol`. This makes the codebase more testable, maintainable, and flexible.

## Core Protocols

### HTTPClientProtocol

The `HTTPClientProtocol` defines the interface for HTTP clients:

```swift
public protocol HTTPClientProtocol: Sendable {
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String],
        body: [String: any Sendable]?
    ) async throws -> T
    
    var rateLimit: RateLimit? { get async }
    var baseURL: URL { get }
    var userAgent: String { get }
}
```

### DiscogsServiceProtocol

The `DiscogsServiceProtocol` provides base functionality for all services:

```swift
public protocol DiscogsServiceProtocol: Sendable {
    var httpClient: HTTPClientProtocol { get }
    
    // Convenience methods for common HTTP operations
    func performRequest<T: Decodable & Sendable>(endpoint: String, parameters: [String: String]) async throws -> T
    func performRequest<T: Decodable & Sendable>(endpoint: String, body: [String: any Sendable], parameters: [String: String]) async throws -> T
    func performRequest<T: Decodable & Sendable>(endpoint: String, method: HTTPMethod, parameters: [String: String], body: [String: any Sendable]?) async throws -> T
}
```

## Usage Examples

### 1. Using the Standard Discogs Client (Recommended)

```swift
import Discogs

// Create the main Discogs client
let discogs = Discogs(token: "your_token", userAgent: "YourApp/1.0")

// Use services directly from the client (they use dependency injection internally)
let release = try await discogs.database.getRelease(id: 1)
let userProfile = try await discogs.user.getProfile(username: "discogs")
let searchResults = try await discogs.search.search(query: "Nirvana", type: .release)
```

### 2. Using Services with Protocol-Oriented Approach

```swift
import Discogs

// Create the main Discogs client
let discogs = Discogs(token: "your_token", userAgent: "YourApp/1.0")

// Create services with dependency injection
let databaseService = DatabaseService(httpClient: discogs)
let collectionService = CollectionService(httpClient: discogs)

// Use the services
let release = try await databaseService.getRelease(id: 1)
let folders = try await collectionService.getFolders(username: "your_username")
```

### 3. Using Services with Legacy Backward Compatibility

```swift
import Discogs

// Create the main Discogs client
let discogs = Discogs(token: "your_token", userAgent: "YourApp/1.0")

// Create services with legacy approach (still supported)
let databaseService = DatabaseService(client: discogs)
let collectionService = CollectionService(client: discogs)

// Use the services (same API)
let release = try await databaseService.getRelease(id: 1)
let folders = try await collectionService.getFolders(username: "your_username")
```

### 4. Using the Dependency Container

```swift
import Discogs

// Create and configure the dependency container
let container = DependencyContainer()

// Register the HTTP client
let discogs = Discogs(token: "your_token", userAgent: "YourApp/1.0")
await container.register(HTTPClientProtocol.self, instance: discogs)

// Register services
let databaseService = DatabaseService(httpClient: discogs)
await container.register(DatabaseService.self, instance: databaseService)

// Resolve services
let resolvedService = await container.resolve(DatabaseService.self)
let release = try await resolvedService?.getRelease(id: 1)
```

## Testing with MockHTTPClient

The protocol-oriented approach makes testing much easier with the provided `MockHTTPClient`:

```swift
import Testing
@testable import Discogs

@Test("Database service returns release")
func testGetRelease() async throws {
    // Given
    let mockClient = MockHTTPClient()
    let service = DatabaseService(httpClient: mockClient)
    
    let mockResponse = """
    {
        "id": 1,
        "title": "Test Release",
        "year": 2023
    }
    """
    
    await mockClient.setMockResponse(json: mockResponse)
    
    // When
    let release: Release = try await service.getRelease(id: 1)
    
    // Then
    #expect(release.id == 1)
    #expect(release.title == "Test Release")
    
    // Verify the request was made correctly
    let request = await mockClient.getLastRequest()
    let requestData = try #require(request)
    #expect(requestData.url.path.contains("releases/1"))
    #expect(requestData.method == "GET")
}
```

## Migration Guide

### From Old Approach

**Old way:**
```swift
let discogs = Discogs(token: "token", userAgent: "app")
let service = DatabaseService(client: discogs)
```

**New way (recommended):**
```swift
let discogs = Discogs(token: "token", userAgent: "app")
// Use services directly from discogs client
let release = try await discogs.database.getRelease(id: 1)

// Or create services explicitly
let service = DatabaseService(httpClient: discogs)
```

### For Testing

**Old way:**
```swift
let mockClient = MockDiscogsClient()
let service = DatabaseService(client: mockClient)
```

**New way:**
```swift
let mockClient = MockHTTPClient()
let service = DatabaseService(httpClient: mockClient)
```

## Benefits

1. **Better Testability**: Easy to mock HTTP client for unit tests
2. **Flexible Architecture**: Can swap HTTP implementations without changing service code
3. **Dependency Injection**: Supports proper dependency injection patterns
4. **Backward Compatibility**: Existing code continues to work unchanged
5. **Type Safety**: Protocol conformance ensures type safety at compile time
6. **Sendable Support**: Full concurrency support with Swift's async/await

## Available Services

All services now support both initialization approaches:

- `DatabaseService` - Database operations (releases, artists, labels, etc.)
- `CollectionService` - User collection management
- `SearchService` - Search functionality
- `WantlistService` - Wantlist management
- `UserService` - User profile operations
- `MarketplaceService` - Marketplace listings and orders

Each service conforms to `DiscogsServiceProtocol` and can be initialized with either:
- `httpClient: HTTPClientProtocol` (new protocol-oriented approach)
- `client: Discogs` (backward-compatible legacy approach)
