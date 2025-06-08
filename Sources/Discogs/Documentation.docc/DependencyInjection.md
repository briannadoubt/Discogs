# Dependency Injection

Learn how to use dependency injection with the Discogs Swift SDK for better testability, modularity, and maintainability.

## Overview

The Discogs Swift SDK supports dependency injection patterns to help you build testable, modular applications. This allows you to easily mock dependencies for testing, swap implementations, and follow SOLID principles.

## Core Protocols

The SDK defines several protocols that enable dependency injection:

### DiscogsServiceProtocol

The main service protocol that defines all Discogs API operations:

```swift
public protocol DiscogsServiceProtocol {
    // Database operations
    func getArtist(id: Int) async throws -> Artist
    func getRelease(id: Int) async throws -> Release
    func getMaster(id: Int) async throws -> Master
    func getLabel(id: Int) async throws -> Label
    
    // Search operations
    func search(query: String, type: SearchType?, page: Int?, perPage: Int?) async throws -> SearchResults
    
    // User operations
    func getUserProfile(username: String) async throws -> UserProfile
    func getUserCollection(username: String) async throws -> CollectionResponse
    func getUserWantlist(username: String) async throws -> WantlistResponse
}
```

### HTTPClientProtocol

Protocol for HTTP networking layer:

```swift
public protocol HTTPClientProtocol {
    func performRequest<T: Codable>(_ request: URLRequest) async throws -> T
    func performRequest(_ request: URLRequest) async throws -> Data
}
```

## Built-in Dependency Container

The SDK includes a dependency container for managing dependencies:

```swift
public class DependencyContainer {
    public static let shared = DependencyContainer()
    
    private var services: [String: Any] = [:]
    private let queue = DispatchQueue(label: "dependency-container", attributes: .concurrent)
    
    public init() {}
    
    public func register<T>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.services[key] = service
        }
    }
    
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return queue.sync {
            return services[key] as? T
        }
    }
}
```

## Basic Dependency Injection

### Constructor Injection

Inject dependencies through initializers:

```swift
class ArtistRepository {
    private let discogsService: DiscogsServiceProtocol
    private let cache: CacheProtocol
    
    init(
        discogsService: DiscogsServiceProtocol,
        cache: CacheProtocol = InMemoryCache()
    ) {
        self.discogsService = discogsService
        self.cache = cache
    }
    
    func getArtist(id: Int) async throws -> Artist {
        // Check cache first
        if let cached = await cache.get("artist-\(id)", as: Artist.self) {
            return cached
        }
        
        // Fetch from API
        let artist = try await discogsService.getArtist(id: id)
        
        // Cache the result
        await cache.set("artist-\(id)", value: artist, expiry: .minutes(30))
        
        return artist
    }
}

// Usage
let discogsService = DiscogsService(apiToken: "your-token")
let repository = ArtistRepository(discogsService: discogsService)
```

### Property Injection

Inject dependencies through properties:

```swift
class MusicLibraryService {
    var discogsService: DiscogsServiceProtocol!
    var storageService: StorageProtocol!
    
    func enrichCollection() async throws {
        guard let discogs = discogsService,
              let storage = storageService else {
            throw ServiceError.dependenciesNotConfigured
        }
        
        let localAlbums = try await storage.getAllAlbums()
        
        for album in localAlbums {
            if let searchResults = try? await discogs.search(query: album.title, type: .release) {
                // Enrich local data with Discogs metadata
                album.enrichWith(discogsData: searchResults.results.first)
            }
        }
    }
}

// Configuration
let libraryService = MusicLibraryService()
libraryService.discogsService = DiscogsService(apiToken: "your-token")
libraryService.storageService = CoreDataStorage()
```

## Advanced Dependency Injection

### Service Locator Pattern

```swift
class ServiceLocator {
    static let shared = ServiceLocator()
    
    private var services: [String: Any] = [:]
    
    private init() {
        registerDefaultServices()
    }
    
    func register<T>(_ service: T, for protocol: T.Type) {
        let key = String(describing: `protocol`)
        services[key] = service
    }
    
    func resolve<T>(_ protocol: T.Type) -> T {
        let key = String(describing: `protocol`)
        guard let service = services[key] as? T else {
            fatalError("Service \(key) not registered")
        }
        return service
    }
    
    private func registerDefaultServices() {
        register(DiscogsService() as DiscogsServiceProtocol, for: DiscogsServiceProtocol.self)
        register(URLSession.shared as HTTPClientProtocol, for: HTTPClientProtocol.self)
        register(InMemoryCache() as CacheProtocol, for: CacheProtocol.self)
    }
}

// Usage
class PlaylistBuilder {
    private let discogsService: DiscogsServiceProtocol
    private let cache: CacheProtocol
    
    init() {
        self.discogsService = ServiceLocator.shared.resolve(DiscogsServiceProtocol.self)
        self.cache = ServiceLocator.shared.resolve(CacheProtocol.self)
    }
}
```

### Factory Pattern

```swift
protocol DiscogsServiceFactory {
    func createService(apiToken: String?) -> DiscogsServiceProtocol
    func createMockService() -> DiscogsServiceProtocol
}

class DefaultDiscogsServiceFactory: DiscogsServiceFactory {
    func createService(apiToken: String?) -> DiscogsServiceProtocol {
        if let token = apiToken {
            return DiscogsService(apiToken: token)
        } else {
            return DiscogsService()
        }
    }
    
    func createMockService() -> DiscogsServiceProtocol {
        return MockDiscogsService()
    }
}

class MusicDiscoveryEngine {
    private let serviceFactory: DiscogsServiceFactory
    private let environment: Environment
    
    init(serviceFactory: DiscogsServiceFactory, environment: Environment) {
        self.serviceFactory = serviceFactory
        self.environment = environment
    }
    
    func start() async {
        let service: DiscogsServiceProtocol
        
        switch environment {
        case .production:
            service = serviceFactory.createService(apiToken: getAPIToken())
        case .testing:
            service = serviceFactory.createMockService()
        case .development:
            service = serviceFactory.createService(apiToken: getDevelopmentToken())
        }
        
        // Use the service...
    }
}
```

## Testing with Dependency Injection

### Mock Services

Create mock implementations for testing:

```swift
class MockDiscogsService: DiscogsServiceProtocol {
    var shouldThrowError = false
    var mockArtists: [Int: Artist] = [:]
    var mockSearchResults: SearchResults?
    
    func getArtist(id: Int) async throws -> Artist {
        if shouldThrowError {
            throw DiscogsError.notFound
        }
        
        return mockArtists[id] ?? Artist(
            id: id,
            name: "Mock Artist \(id)",
            realName: "Mock Real Name",
            images: [],
            profile: "Mock profile",
            members: [],
            urls: []
        )
    }
    
    func search(query: String, type: SearchType?, page: Int?, perPage: Int?) async throws -> SearchResults {
        if shouldThrowError {
            throw DiscogsError.networkError(NSError(domain: "MockError", code: 500))
        }
        
        return mockSearchResults ?? SearchResults(
            pagination: Pagination(pages: 1, page: 1, perPage: 50, items: 0, urls: PaginationUrls()),
            results: []
        )
    }
    
    // Implement other protocol methods...
}
```

### Test Setup

```swift
class ArtistRepositoryTests: XCTestCase {
    var repository: ArtistRepository!
    var mockService: MockDiscogsService!
    var mockCache: MockCache!
    
    override func setUp() {
        super.setUp()
        mockService = MockDiscogsService()
        mockCache = MockCache()
        repository = ArtistRepository(
            discogsService: mockService,
            cache: mockCache
        )
    }
    
    func testGetArtistFromCache() async throws {
        // Given
        let artistId = 123
        let cachedArtist = Artist(id: artistId, name: "Cached Artist")
        mockCache.setCachedValue(cachedArtist, for: "artist-\(artistId)")
        
        // When
        let result = try await repository.getArtist(id: artistId)
        
        // Then
        XCTAssertEqual(result.name, "Cached Artist")
        XCTAssertFalse(mockService.getArtistCalled) // Should not call API
    }
    
    func testGetArtistFromAPI() async throws {
        // Given
        let artistId = 456
        let apiArtist = Artist(id: artistId, name: "API Artist")
        mockService.mockArtists[artistId] = apiArtist
        
        // When
        let result = try await repository.getArtist(id: artistId)
        
        // Then
        XCTAssertEqual(result.name, "API Artist")
        XCTAssertTrue(mockCache.setCalled) // Should cache the result
    }
}
```

## SwiftUI Integration

### Environment Objects

Use SwiftUI's environment system for dependency injection:

```swift
class AppDependencies: ObservableObject {
    let discogsService: DiscogsServiceProtocol
    let userService: UserServiceProtocol
    let cacheService: CacheProtocol
    
    init(environment: Environment = .production) {
        switch environment {
        case .production:
            self.discogsService = DiscogsService(apiToken: getAPIToken())
            self.userService = UserService()
            self.cacheService = CoreDataCache()
        case .testing:
            self.discogsService = MockDiscogsService()
            self.userService = MockUserService()
            self.cacheService = MockCache()
        }
    }
}

@main
struct MusicApp: App {
    @StateObject private var dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
        }
    }
}

struct ArtistDetailView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @State private var artist: Artist?
    
    let artistId: Int
    
    var body: some View {
        VStack {
            if let artist = artist {
                Text(artist.name)
                // Display artist details
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                artist = try await dependencies.discogsService.getArtist(id: artistId)
            } catch {
                print("Error loading artist: \(error)")
            }
        }
    }
}
```

### Custom Environment Keys

Create custom environment keys for specific services:

```swift
struct DiscogsServiceKey: EnvironmentKey {
    static let defaultValue: DiscogsServiceProtocol = DiscogsService()
}

extension EnvironmentValues {
    var discogsService: DiscogsServiceProtocol {
        get { self[DiscogsServiceKey.self] }
        set { self[DiscogsServiceKey.self] = newValue }
    }
}

// Usage in views
struct SearchView: View {
    @Environment(\.discogsService) private var discogsService
    @State private var searchResults: [SearchResult] = []
    @State private var query = ""
    
    var body: some View {
        NavigationView {
            List(searchResults, id: \.id) { result in
                Text(result.title)
            }
            .searchable(text: $query)
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
                }
            }
        }
    }
    
    private func performSearch() async {
        do {
            let results = try await discogsService.search(query: query)
            searchResults = results.results
        } catch {
            print("Search failed: \(error)")
        }
    }
}
```

## Configuration Management

### Environment-based Configuration

```swift
enum Environment {
    case development
    case staging
    case production
    case testing
}

struct DiscogsConfiguration {
    let apiToken: String?
    let baseURL: URL
    let rateLimitPerMinute: Int
    let cacheEnabled: Bool
    
    static func configuration(for environment: Environment) -> DiscogsConfiguration {
        switch environment {
        case .development:
            return DiscogsConfiguration(
                apiToken: ProcessInfo.processInfo.environment["DISCOGS_DEV_TOKEN"],
                baseURL: URL(string: "https://api.discogs.com")!,
                rateLimitPerMinute: 60,
                cacheEnabled: true
            )
        case .staging:
            return DiscogsConfiguration(
                apiToken: ProcessInfo.processInfo.environment["DISCOGS_STAGING_TOKEN"],
                baseURL: URL(string: "https://api.discogs.com")!,
                rateLimitPerMinute: 60,
                cacheEnabled: true
            )
        case .production:
            return DiscogsConfiguration(
                apiToken: ProcessInfo.processInfo.environment["DISCOGS_API_TOKEN"],
                baseURL: URL(string: "https://api.discogs.com")!,
                rateLimitPerMinute: 60,
                cacheEnabled: true
            )
        case .testing:
            return DiscogsConfiguration(
                apiToken: nil,
                baseURL: URL(string: "https://mock.discogs.com")!,
                rateLimitPerMinute: 1000,
                cacheEnabled: false
            )
        }
    }
}

class ConfigurableDiscogsService: DiscogsServiceProtocol {
    private let configuration: DiscogsConfiguration
    private let httpClient: HTTPClientProtocol
    
    init(configuration: DiscogsConfiguration, httpClient: HTTPClientProtocol) {
        self.configuration = configuration
        self.httpClient = httpClient
    }
    
    // Implement protocol methods using configuration...
}
```

## Best Practices

### 1. Use Protocols for Abstraction

Always program against protocols rather than concrete types:

```swift
// Good
class MusicAnalyzer {
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
    }
}

// Avoid
class MusicAnalyzer {
    private let discogsService: DiscogsService // Tightly coupled
    
    init(discogsService: DiscogsService) {
        self.discogsService = discogsService
    }
}
```

### 2. Minimize Dependencies

Keep dependencies minimal and focused:

```swift
// Good - focused dependencies
class ArtistImageLoader {
    private let imageService: ImageServiceProtocol
    
    init(imageService: ImageServiceProtocol) {
        self.imageService = imageService
    }
}

// Avoid - too many dependencies
class ArtistImageLoader {
    private let discogsService: DiscogsServiceProtocol
    private let cacheService: CacheProtocol
    private let networkService: NetworkProtocol
    private let loggerService: LoggerProtocol
    // ... many more dependencies
}
```

### 3. Use Factory Methods for Complex Setup

```swift
extension DiscogsService {
    static func production() -> DiscogsServiceProtocol {
        let config = DiscogsConfiguration.configuration(for: .production)
        let httpClient = URLSessionHTTPClient()
        let rateLimiter = RateLimiter(maxRequestsPerMinute: config.rateLimitPerMinute)
        
        return DiscogsService(
            configuration: config,
            httpClient: httpClient,
            rateLimiter: rateLimiter
        )
    }
    
    static func testing() -> DiscogsServiceProtocol {
        return MockDiscogsService()
    }
}
```

### 4. Validate Dependencies

Ensure dependencies are properly configured:

```swift
class ValidationService {
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) throws {
        self.discogsService = discogsService
        
        // Validate the service is properly configured
        try validateService()
    }
    
    private func validateService() throws {
        // Check if service can perform basic operations
        // This might include connectivity checks, token validation, etc.
    }
}
```

## Related Topics

- <doc:Testing>
- <doc:Authentication>
- <doc:BestPractices>
- <doc:ErrorHandling>
