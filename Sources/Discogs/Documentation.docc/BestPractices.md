# Best Practices

Learn the recommended patterns and practices for building robust applications with the Discogs Swift SDK.

## Overview

Following best practices ensures your application is maintainable, performant, and provides a great user experience. This guide covers architectural patterns, performance optimization, error handling, and development workflows.

## Application Architecture

### Service Layer Pattern

Organize your code using a clean service layer architecture:

```swift
// MARK: - Service Layer
protocol MusicLibraryService {
    func searchMusic(query: String) async throws -> [MusicItem]
    func getArtistDetails(id: Int) async throws -> ArtistDetails
    func getUserCollection(username: String) async throws -> Collection
}

class DefaultMusicLibraryService: MusicLibraryService {
    private let discogsService: DiscogsServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(
        discogsService: DiscogsServiceProtocol,
        cacheService: CacheServiceProtocol,
        analyticsService: AnalyticsServiceProtocol
    ) {
        self.discogsService = discogsService
        self.cacheService = cacheService
        self.analyticsService = analyticsService
    }
    
    func searchMusic(query: String) async throws -> [MusicItem] {
        analyticsService.track("music_search_initiated", properties: ["query": query])
        
        do {
            let results = try await discogsService.search(query: query)
            let musicItems = results.results.map { MusicItem(from: $0) }
            
            analyticsService.track("music_search_completed", properties: [
                "query": query,
                "results_count": musicItems.count
            ])
            
            return musicItems
        } catch {
            analyticsService.track("music_search_failed", properties: [
                "query": query,
                "error": error.localizedDescription
            ])
            throw error
        }
    }
}
```

### Repository Pattern

Use repositories to abstract data access:

```swift
protocol ArtistRepository {
    func getArtist(id: Int) async throws -> Artist
    func searchArtists(query: String) async throws -> [Artist]
    func getFavoriteArtists() async throws -> [Artist]
    func addToFavorites(artist: Artist) async throws
}

class CachedArtistRepository: ArtistRepository {
    private let discogsService: DiscogsServiceProtocol
    private let localStore: LocalStorageProtocol
    private let cache: CacheServiceProtocol
    
    init(
        discogsService: DiscogsServiceProtocol,
        localStore: LocalStorageProtocol,
        cache: CacheServiceProtocol
    ) {
        self.discogsService = discogsService
        self.localStore = localStore
        self.cache = cache
    }
    
    func getArtist(id: Int) async throws -> Artist {
        let cacheKey = "artist-\(id)"
        
        // Try cache first
        if let cached = await cache.get(cacheKey, as: Artist.self) {
            return cached
        }
        
        // Fetch from API
        let artist = try await discogsService.getArtist(id: id)
        
        // Cache the result
        await cache.set(cacheKey, value: artist, expiry: .hours(2))
        
        return artist
    }
    
    func getFavoriteArtists() async throws -> [Artist] {
        return try await localStore.getFavoriteArtists()
    }
    
    func addToFavorites(artist: Artist) async throws {
        try await localStore.addFavoriteArtist(artist)
    }
}
```

## Performance Optimization

### Efficient Data Loading

Implement smart loading strategies:

```swift
class OptimizedMusicLoader {
    private let discogsService: DiscogsServiceProtocol
    private let imageLoader: ImageLoaderProtocol
    
    // Load data in batches to avoid overwhelming the API
    func loadArtistsBatch(_ artistIds: [Int], batchSize: Int = 5) async throws -> [Artist] {
        var allArtists: [Artist] = []
        
        for batch in artistIds.chunked(into: batchSize) {
            let batchArtists = try await withThrowingTaskGroup(of: Artist.self) { group in
                for id in batch {
                    group.addTask {
                        try await self.discogsService.getArtist(id: id)
                    }
                }
                
                var artists: [Artist] = []
                for try await artist in group {
                    artists.append(artist)
                }
                return artists
            }
            
            allArtists.append(contentsOf: batchArtists)
            
            // Brief pause between batches to respect rate limits
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        return allArtists
    }
    
    // Preload images for better UX
    func preloadImagesForArtists(_ artists: [Artist]) async {
        await withTaskGroup(of: Void.self) { group in
            for artist in artists {
                for image in artist.images.prefix(3) { // Only preload first 3 images
                    group.addTask {
                        try? await self.imageLoader.preloadImage(from: image.uri)
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

### Memory Management

Implement proper memory management:

```swift
class MemoryEfficientSearchService {
    private let discogsService: DiscogsServiceProtocol
    private let maxCacheSize = 100
    private var searchCache: LRUCache<String, SearchResults>
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
        self.searchCache = LRUCache(capacity: maxCacheSize)
    }
    
    func search(query: String, page: Int = 1) async throws -> SearchResults {
        let cacheKey = "\(query)-page-\(page)"
        
        if let cached = searchCache.get(cacheKey) {
            return cached
        }
        
        let results = try await discogsService.search(
            query: query,
            page: page,
            perPage: 50
        )
        
        searchCache.set(cacheKey, value: results)
        return results
    }
    
    func clearCache() {
        searchCache.removeAll()
    }
}

// Simple LRU Cache implementation
class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        guard let value = cache[key] else { return nil }
        
        // Move to end (most recently used)
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        
        return value
    }
    
    func set(_ key: Key, value: Value) {
        if cache[key] != nil {
            // Update existing
            cache[key] = value
            accessOrder.removeAll { $0 == key }
            accessOrder.append(key)
        } else {
            // Add new
            if cache.count >= capacity {
                // Remove least recently used
                let lru = accessOrder.removeFirst()
                cache.removeValue(forKey: lru)
            }
            
            cache[key] = value
            accessOrder.append(key)
        }
    }
    
    func removeAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}
```

### Pagination Best Practices

Handle pagination efficiently:

```swift
class PaginatedSearchManager: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isLoading = false
    @Published var hasMorePages = true
    @Published var error: DiscogsError?
    
    private let discogsService: DiscogsServiceProtocol
    private var currentQuery: String = ""
    private var currentPage = 1
    private let pageSize = 50
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
    }
    
    @MainActor
    func search(query: String) async {
        guard !query.isEmpty else { return }
        
        // Reset for new search
        if query != currentQuery {
            results.removeAll()
            currentPage = 1
            hasMorePages = true
            currentQuery = query
        }
        
        await loadPage()
    }
    
    @MainActor
    func loadNextPage() async {
        guard hasMorePages && !isLoading else { return }
        currentPage += 1
        await loadPage()
    }
    
    @MainActor
    private func loadPage() async {
        isLoading = true
        error = nil
        
        do {
            let searchResults = try await discogsService.search(
                query: currentQuery,
                page: currentPage,
                perPage: pageSize
            )
            
            // Append new results
            results.append(contentsOf: searchResults.results)
            
            // Check if there are more pages
            hasMorePages = currentPage < searchResults.pagination.pages
            
        } catch let discogsError as DiscogsError {
            error = discogsError
            currentPage -= 1 // Revert page increment on error
        } catch {
            self.error = DiscogsError.networkError(error)
            currentPage -= 1
        }
        
        isLoading = false
    }
    
    func reset() {
        results.removeAll()
        currentQuery = ""
        currentPage = 1
        hasMorePages = true
        error = nil
        isLoading = false
    }
}
```

## SwiftUI Integration

### MVVM Pattern

Use proper MVVM architecture with SwiftUI:

```swift
// MARK: - ViewModel
@MainActor
class ArtistDetailViewModel: ObservableObject {
    @Published var artist: Artist?
    @Published var releases: [Release] = []
    @Published var isLoading = false
    @Published var error: DiscogsError?
    
    private let artistRepository: ArtistRepository
    private let releaseRepository: ReleaseRepository
    
    init(
        artistRepository: ArtistRepository,
        releaseRepository: ReleaseRepository
    ) {
        self.artistRepository = artistRepository
        self.releaseRepository = releaseRepository
    }
    
    func loadArtist(id: Int) async {
        isLoading = true
        error = nil
        
        do {
            async let artistTask = artistRepository.getArtist(id: id)
            async let releasesTask = releaseRepository.getArtistReleases(artistId: id)
            
            artist = try await artistTask
            releases = try await releasesTask
            
        } catch let discogsError as DiscogsError {
            error = discogsError
        } catch {
            error = DiscogsError.networkError(error)
        }
        
        isLoading = false
    }
    
    func refresh() async {
        guard let artistId = artist?.id else { return }
        await loadArtist(id: artistId)
    }
}

// MARK: - View
struct ArtistDetailView: View {
    @StateObject private var viewModel: ArtistDetailViewModel
    
    let artistId: Int
    
    init(artistId: Int, dependencies: AppDependencies) {
        self.artistId = artistId
        self._viewModel = StateObject(wrapping: ArtistDetailViewModel(
            artistRepository: dependencies.artistRepository,
            releaseRepository: dependencies.releaseRepository
        ))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading artist...")
                        .frame(maxWidth: .infinity)
                } else if let artist = viewModel.artist {
                    ArtistHeaderView(artist: artist)
                    ReleasesListView(releases: viewModel.releases)
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task { await viewModel.refresh() }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.artist?.name ?? "Artist")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadArtist(id: artistId)
        }
    }
}
```

### State Management

Implement proper state management:

```swift
// MARK: - App State
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var networkStatus: NetworkStatus = .connected
    @Published var searchHistory: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let maxHistoryItems = 20
    
    init() {
        loadSearchHistory()
    }
    
    func addToSearchHistory(_ query: String) {
        searchHistory.removeAll { $0 == query }
        searchHistory.insert(query, at: 0)
        
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }
        
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        searchHistory = userDefaults.stringArray(forKey: "search_history") ?? []
    }
    
    private func saveSearchHistory() {
        userDefaults.set(searchHistory, forKey: "search_history")
    }
}

enum NetworkStatus {
    case connected
    case disconnected
    case slow
}

// MARK: - Dependency Injection
class AppDependencies: ObservableObject {
    let discogsService: DiscogsServiceProtocol
    let artistRepository: ArtistRepository
    let releaseRepository: ReleaseRepository
    let cacheService: CacheServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    
    init(environment: Environment = .production) {
        // Configure services based on environment
        switch environment {
        case .production:
            self.discogsService = DiscogsService(apiToken: Config.apiToken)
        case .development:
            self.discogsService = DiscogsService(apiToken: Config.devApiToken)
        case .testing:
            self.discogsService = MockDiscogsService()
        }
        
        self.cacheService = CoreDataCacheService()
        self.analyticsService = FirebaseAnalyticsService()
        
        self.artistRepository = CachedArtistRepository(
            discogsService: discogsService,
            localStore: CoreDataStore(),
            cache: cacheService
        )
        
        self.releaseRepository = CachedReleaseRepository(
            discogsService: discogsService,
            cache: cacheService
        )
    }
}
```

## Error Handling Patterns

### Global Error Handling

Implement centralized error handling:

```swift
class GlobalErrorHandler: ObservableObject {
    @Published var currentError: UserFacingError?
    @Published var showError = false
    
    private let analyticsService: AnalyticsServiceProtocol
    private let logger: LoggerProtocol
    
    init(analyticsService: AnalyticsServiceProtocol, logger: LoggerProtocol) {
        self.analyticsService = analyticsService
        self.logger = logger
    }
    
    func handle(_ error: Error, context: String = "") {
        logger.error("Error in \(context): \(error)")
        
        let userError = UserFacingError.from(error)
        
        DispatchQueue.main.async {
            self.currentError = userError
            self.showError = true
        }
        
        // Report to analytics
        analyticsService.track("error_occurred", properties: [
            "error_type": String(describing: type(of: error)),
            "context": context,
            "user_message": userError.message
        ])
    }
    
    func dismissError() {
        currentError = nil
        showError = false
    }
}

struct UserFacingError {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    static func from(_ error: Error) -> UserFacingError {
        switch error {
        case DiscogsError.networkError:
            return UserFacingError(
                title: "Connection Error",
                message: "Please check your internet connection and try again.",
                actionTitle: "Retry",
                action: nil
            )
        case DiscogsError.rateLimited:
            return UserFacingError(
                title: "Too Many Requests",
                message: "Please wait a moment before trying again.",
                actionTitle: nil,
                action: nil
            )
        case DiscogsError.unauthorized:
            return UserFacingError(
                title: "Authentication Error",
                message: "Please check your login credentials.",
                actionTitle: "Login",
                action: nil
            )
        default:
            return UserFacingError(
                title: "Something Went Wrong",
                message: "An unexpected error occurred. Please try again.",
                actionTitle: "Retry",
                action: nil
            )
        }
    }
}
```

### Graceful Degradation

Implement fallback strategies:

```swift
class ResilientSearchService {
    private let primaryService: DiscogsServiceProtocol
    private let offlineStore: OfflineStorageProtocol
    private let connectivityMonitor: ConnectivityMonitorProtocol
    
    init(
        primaryService: DiscogsServiceProtocol,
        offlineStore: OfflineStorageProtocol,
        connectivityMonitor: ConnectivityMonitorProtocol
    ) {
        self.primaryService = primaryService
        self.offlineStore = offlineStore
        self.connectivityMonitor = connectivityMonitor
    }
    
    func search(query: String) async throws -> SearchResults {
        // Try online search first
        if connectivityMonitor.isConnected {
            do {
                let results = try await primaryService.search(query: query)
                // Cache results for offline access
                await offlineStore.cacheSearchResults(results, for: query)
                return results
            } catch DiscogsError.networkError {
                // Fall back to offline if network fails
                return try await searchOffline(query: query)
            } catch {
                throw error
            }
        } else {
            // Use offline search when not connected
            return try await searchOffline(query: query)
        }
    }
    
    private func searchOffline(query: String) async throws -> SearchResults {
        if let cachedResults = await offlineStore.getCachedSearchResults(for: query) {
            return cachedResults
        } else {
            throw DiscogsError.networkError(NSError(
                domain: "OfflineError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No offline data available"]
            ))
        }
    }
}
```

## Testing Strategies

### Test Organization

Organize tests effectively:

```swift
// MARK: - Unit Tests
class ArtistRepositoryUnitTests: XCTestCase {
    var repository: ArtistRepository!
    var mockService: MockDiscogsService!
    var mockCache: MockCacheService!
    
    override func setUp() {
        super.setUp()
        mockService = MockDiscogsService()
        mockCache = MockCacheService()
        repository = CachedArtistRepository(
            discogsService: mockService,
            localStore: MockLocalStore(),
            cache: mockCache
        )
    }
    
    func testGetArtist_CacheHit_ReturnsCachedArtist() async throws {
        // Given
        let expectedArtist = Artist.mock(id: 123, name: "Cached Artist")
        mockCache.setMockData(expectedArtist, for: "artist-123")
        
        // When
        let result = try await repository.getArtist(id: 123)
        
        // Then
        XCTAssertEqual(result, expectedArtist)
        XCTAssertFalse(mockService.getArtistWasCalled)
    }
}

// MARK: - Integration Tests
class SearchIntegrationTests: XCTestCase {
    var searchService: SearchService!
    var mockHTTPClient: MockHTTPClient!
    
    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        let discogsService = DiscogsService(httpClient: mockHTTPClient)
        searchService = SearchService(discogsService: discogsService)
    }
    
    func testSearch_ValidQuery_ReturnsResults() async throws {
        // Given
        let mockResponse = SearchResults.mock(resultCount: 5)
        mockHTTPClient.setMockResponse(mockResponse)
        
        // When
        let results = try await searchService.search(query: "Beatles")
        
        // Then
        XCTAssertEqual(results.results.count, 5)
    }
}
```

### Mock Implementations

Create comprehensive mocks:

```swift
extension Artist {
    static func mock(
        id: Int = 1,
        name: String = "Mock Artist",
        realName: String? = nil,
        images: [ArtistImage] = [],
        profile: String = "Mock profile"
    ) -> Artist {
        return Artist(
            id: id,
            name: name,
            realName: realName,
            images: images,
            profile: profile,
            members: [],
            urls: []
        )
    }
}

extension SearchResults {
    static func mock(resultCount: Int = 10) -> SearchResults {
        let results = (1...resultCount).map { index in
            SearchResult(
                id: index,
                type: "release",
                title: "Mock Result \(index)",
                uri: "/releases/\(index)",
                resourceUrl: "https://api.discogs.com/releases/\(index)",
                thumb: "https://example.com/thumb\(index).jpg"
            )
        }
        
        return SearchResults(
            pagination: Pagination(
                pages: 1,
                page: 1,
                perPage: resultCount,
                items: resultCount,
                urls: PaginationUrls()
            ),
            results: results
        )
    }
}
```

## Security Best Practices

### API Token Management

Secure API token handling:

```swift
class SecureTokenManager {
    private let keychain = Keychain(service: "com.yourapp.discogs")
    
    func storeAPIToken(_ token: String) throws {
        try keychain.set(token, key: "discogs_api_token")
    }
    
    func getAPIToken() -> String? {
        return try? keychain.get("discogs_api_token")
    }
    
    func removeAPIToken() throws {
        try keychain.remove("discogs_api_token")
    }
}

// Never hardcode tokens in your app
class SecureDiscogsConfiguration {
    static func createService() -> DiscogsServiceProtocol {
        let tokenManager = SecureTokenManager()
        
        guard let apiToken = tokenManager.getAPIToken() else {
            // Handle missing token appropriately
            return MockDiscogsService() // Or prompt for login
        }
        
        return DiscogsService(apiToken: apiToken)
    }
}
```

### Input Validation

Validate user inputs:

```swift
class InputValidator {
    static func validateSearchQuery(_ query: String) throws -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyQuery
        }
        
        guard trimmed.count <= 1000 else {
            throw ValidationError.queryTooLong
        }
        
        // Remove potentially dangerous characters
        let sanitized = trimmed.replacingOccurrences(of: "[<>\"']", with: "", options: .regularExpression)
        
        return sanitized
    }
    
    static func validateUsername(_ username: String) throws -> String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyUsername
        }
        
        // Basic username validation
        let usernameRegex = "^[a-zA-Z0-9_-]{3,30}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        
        guard predicate.evaluate(with: trimmed) else {
            throw ValidationError.invalidUsername
        }
        
        return trimmed
    }
}

enum ValidationError: Error, LocalizedError {
    case emptyQuery
    case queryTooLong
    case emptyUsername
    case invalidUsername
    
    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Search query cannot be empty"
        case .queryTooLong:
            return "Search query is too long"
        case .emptyUsername:
            return "Username cannot be empty"
        case .invalidUsername:
            return "Username can only contain letters, numbers, hyphens, and underscores"
        }
    }
}
```

## Development Workflow

### Configuration Management

Use proper configuration:

```swift
enum Environment {
    case development
    case staging
    case production
    case testing
}

struct Config {
    static var environment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    static var apiToken: String {
        switch environment {
        case .development:
            return ProcessInfo.processInfo.environment["DISCOGS_DEV_TOKEN"] ?? ""
        case .staging:
            return ProcessInfo.processInfo.environment["DISCOGS_STAGING_TOKEN"] ?? ""
        case .production:
            return ProcessInfo.processInfo.environment["DISCOGS_API_TOKEN"] ?? ""
        case .testing:
            return "test-token"
        }
    }
    
    static var baseURL: URL {
        switch environment {
        case .testing:
            return URL(string: "https://mock.discogs.com")!
        default:
            return URL(string: "https://api.discogs.com")!
        }
    }
    
    static var isLoggingEnabled: Bool {
        return environment != .production
    }
    
    static var cacheEnabled: Bool {
        return environment != .testing
    }
}
```

### Logging

Implement proper logging:

```swift
protocol LoggerProtocol {
    func debug(_ message: String, context: [String: Any]?)
    func info(_ message: String, context: [String: Any]?)
    func warning(_ message: String, context: [String: Any]?)
    func error(_ message: String, context: [String: Any]?)
}

class Logger: LoggerProtocol {
    private let isEnabled: Bool
    
    init(isEnabled: Bool = Config.isLoggingEnabled) {
        self.isEnabled = isEnabled
    }
    
    func debug(_ message: String, context: [String: Any]? = nil) {
        log("🐛 DEBUG", message: message, context: context)
    }
    
    func info(_ message: String, context: [String: Any]? = nil) {
        log("ℹ️ INFO", message: message, context: context)
    }
    
    func warning(_ message: String, context: [String: Any]? = nil) {
        log("⚠️ WARNING", message: message, context: context)
    }
    
    func error(_ message: String, context: [String: Any]? = nil) {
        log("🔴 ERROR", message: message, context: context)
    }
    
    private func log(_ level: String, message: String, context: [String: Any]?) {
        guard isEnabled else { return }
        
        var logMessage = "\(level): \(message)"
        
        if let context = context, !context.isEmpty {
            let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " | Context: \(contextString)"
        }
        
        print(logMessage)
    }
}
```

## Related Topics

- <doc:Testing>
- <doc:ErrorHandling>
- <doc:DependencyInjection>
- <doc:RateLimiting>
- <doc:Authentication>
