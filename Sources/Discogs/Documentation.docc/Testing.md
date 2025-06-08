# Testing

Learn how to effectively test applications that use the Discogs Swift SDK, including unit testing, integration testing, and mocking strategies.

## Overview

The Discogs Swift SDK is designed with testability in mind, providing protocols, dependency injection, and mock implementations to make testing your applications straightforward and reliable.

## Testing Approaches

### Unit Testing

Test individual components in isolation using mocks and stubs:

```swift
import XCTest
@testable import Discogs

class ArtistRepositoryTests: XCTestCase {
    var repository: ArtistRepository!
    var mockService: MockDiscogsService!
    var mockCache: MockCacheService!
    
    override func setUp() {
        super.setUp()
        mockService = MockDiscogsService()
        mockCache = MockCacheService()
        repository = ArtistRepository(
            discogsService: mockService,
            cacheService: mockCache
        )
    }
    
    override func tearDown() {
        repository = nil
        mockService = nil
        mockCache = nil
        super.tearDown()
    }
    
    func testGetArtistFromCache() async throws {
        // Given
        let expectedArtist = Artist(id: 123, name: "Test Artist")
        mockCache.setMockData(expectedArtist, for: "artist-123")
        
        // When
        let result = try await repository.getArtist(id: 123)
        
        // Then
        XCTAssertEqual(result.id, expectedArtist.id)
        XCTAssertEqual(result.name, expectedArtist.name)
        XCTAssertFalse(mockService.getArtistWasCalled)
        XCTAssertTrue(mockCache.getWasCalled)
    }
    
    func testGetArtistFromAPI() async throws {
        // Given
        let expectedArtist = Artist(id: 456, name: "API Artist")
        mockService.setMockArtist(expectedArtist, for: 456)
        mockCache.shouldReturnNil = true
        
        // When
        let result = try await repository.getArtist(id: 456)
        
        // Then
        XCTAssertEqual(result.id, expectedArtist.id)
        XCTAssertEqual(result.name, expectedArtist.name)
        XCTAssertTrue(mockService.getArtistWasCalled)
        XCTAssertTrue(mockCache.setWasCalled)
    }
}
```

### Integration Testing

Test the interaction between multiple components:

```swift
class DiscogsIntegrationTests: XCTestCase {
    var discogsService: DiscogsService!
    var httpClient: MockHTTPClient!
    
    override func setUp() {
        super.setUp()
        httpClient = MockHTTPClient()
        discogsService = DiscogsService(httpClient: httpClient)
    }
    
    func testSearchIntegration() async throws {
        // Given
        let mockResponse = SearchResults(
            pagination: Pagination(pages: 1, page: 1, perPage: 50, items: 1, urls: PaginationUrls()),
            results: [
                SearchResult(
                    id: 123,
                    type: "release",
                    title: "Test Album",
                    uri: "/releases/123",
                    resourceUrl: "https://api.discogs.com/releases/123",
                    thumb: "https://example.com/thumb.jpg"
                )
            ]
        )
        
        httpClient.setMockResponse(mockResponse, for: "https://api.discogs.com/database/search")
        
        // When
        let results = try await discogsService.search(query: "test")
        
        // Then
        XCTAssertEqual(results.results.count, 1)
        XCTAssertEqual(results.results.first?.title, "Test Album")
        XCTAssertTrue(httpClient.requestWasMade)
    }
    
    func testErrorPropagation() async throws {
        // Given
        httpClient.shouldThrowError = URLError(.notConnectedToInternet)
        
        // When/Then
        do {
            _ = try await discogsService.search(query: "test")
            XCTFail("Expected error to be thrown")
        } catch DiscogsError.networkError(let error) {
            XCTAssertTrue(error is URLError)
        }
    }
}
```

## Mock Implementations

### MockDiscogsService

A comprehensive mock implementation of the main service:

```swift
class MockDiscogsService: DiscogsServiceProtocol {
    // Tracking properties
    var getArtistWasCalled = false
    var getReleaseWasCalled = false
    var searchWasCalled = false
    var lastSearchQuery: String?
    
    // Mock data
    private var mockArtists: [Int: Artist] = [:]
    private var mockReleases: [Int: Release] = [:]
    private var mockSearchResults: SearchResults?
    
    // Error simulation
    var shouldThrowError: DiscogsError?
    var errorDelay: TimeInterval = 0
    
    // MARK: - Setup Methods
    
    func setMockArtist(_ artist: Artist, for id: Int) {
        mockArtists[id] = artist
    }
    
    func setMockRelease(_ release: Release, for id: Int) {
        mockReleases[id] = release
    }
    
    func setMockSearchResults(_ results: SearchResults) {
        mockSearchResults = results
    }
    
    func reset() {
        getArtistWasCalled = false
        getReleaseWasCalled = false
        searchWasCalled = false
        lastSearchQuery = nil
        mockArtists.removeAll()
        mockReleases.removeAll()
        mockSearchResults = nil
        shouldThrowError = nil
        errorDelay = 0
    }
    
    // MARK: - DiscogsServiceProtocol Implementation
    
    func getArtist(id: Int) async throws -> Artist {
        getArtistWasCalled = true
        
        if errorDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(errorDelay * 1_000_000_000))
        }
        
        if let error = shouldThrowError {
            throw error
        }
        
        guard let artist = mockArtists[id] else {
            throw DiscogsError.notFound
        }
        
        return artist
    }
    
    func getRelease(id: Int) async throws -> Release {
        getReleaseWasCalled = true
        
        if let error = shouldThrowError {
            throw error
        }
        
        guard let release = mockReleases[id] else {
            throw DiscogsError.notFound
        }
        
        return release
    }
    
    func search(query: String, type: SearchType?, page: Int?, perPage: Int?) async throws -> SearchResults {
        searchWasCalled = true
        lastSearchQuery = query
        
        if let error = shouldThrowError {
            throw error
        }
        
        return mockSearchResults ?? SearchResults(
            pagination: Pagination(pages: 0, page: 1, perPage: 50, items: 0, urls: PaginationUrls()),
            results: []
        )
    }
    
    // Implement other protocol methods...
    func getUserProfile(username: String) async throws -> UserProfile {
        if let error = shouldThrowError {
            throw error
        }
        
        return UserProfile(
            id: 1,
            username: username,
            email: "test@example.com",
            profile: "",
            wantlistUrl: "",
            rank: 0,
            numPending: 0,
            numForSale: 0,
            homePage: "",
            location: "",
            collectionFoldersUrl: "",
            collectionFieldsUrl: "",
            wantlistUrl: "",
            avatarUrl: ""
        )
    }
}
```

### MockHTTPClient

Mock the HTTP layer for lower-level testing:

```swift
class MockHTTPClient: HTTPClientProtocol {
    var requestWasMade = false
    var lastRequest: URLRequest?
    var shouldThrowError: Error?
    var mockResponses: [String: Any] = [:]
    var responseDelay: TimeInterval = 0
    
    func setMockResponse<T: Codable>(_ response: T, for urlString: String) {
        mockResponses[urlString] = response
    }
    
    func performRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        requestWasMade = true
        lastRequest = request
        
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        if let error = shouldThrowError {
            throw error
        }
        
        guard let url = request.url?.absoluteString,
              let response = mockResponses[url] as? T else {
            throw DiscogsError.notFound
        }
        
        return response
    }
    
    func performRequest(_ request: URLRequest) async throws -> Data {
        requestWasMade = true
        lastRequest = request
        
        if let error = shouldThrowError {
            throw error
        }
        
        return Data()
    }
}
```

## Testing Patterns

### Testing Async/Await Code

```swift
class AsyncTestingExamples: XCTestCase {
    
    func testAsyncOperation() async throws {
        // Test async operations directly
        let service = DiscogsService(apiToken: "test-token")
        let artist = try await service.getArtist(id: 123)
        XCTAssertNotNil(artist)
    }
    
    func testAsyncOperationWithTimeout() async throws {
        // Add timeout for long-running operations
        let service = SlowDiscogsService()
        
        let result = try await withTimeout(seconds: 5) {
            try await service.getArtist(id: 123)
        }
        
        XCTAssertNotNil(result)
    }
    
    func testConcurrentOperations() async throws {
        let service = MockDiscogsService()
        let ids = [1, 2, 3, 4, 5]
        
        // Set up mock data
        for id in ids {
            service.setMockArtist(Artist(id: id, name: "Artist \(id)"), for: id)
        }
        
        // Test concurrent requests
        let artists = try await withThrowingTaskGroup(of: Artist.self) { group in
            for id in ids {
                group.addTask {
                    try await service.getArtist(id: id)
                }
            }
            
            var results: [Artist] = []
            for try await artist in group {
                results.append(artist)
            }
            return results
        }
        
        XCTAssertEqual(artists.count, ids.count)
    }
}

// Helper for timeout testing
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {}
```

### Testing Error Scenarios

```swift
class ErrorScenarioTests: XCTestCase {
    
    func testNetworkErrorHandling() async throws {
        let mockService = MockDiscogsService()
        mockService.shouldThrowError = DiscogsError.networkError(URLError(.notConnectedToInternet))
        
        do {
            _ = try await mockService.getArtist(id: 123)
            XCTFail("Expected network error")
        } catch DiscogsError.networkError(let error) {
            XCTAssertTrue(error is URLError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRateLimitingScenario() async throws {
        let mockService = MockDiscogsService()
        mockService.shouldThrowError = DiscogsError.rateLimited(retryAfter: 60)
        
        do {
            _ = try await mockService.search(query: "test")
            XCTFail("Expected rate limit error")
        } catch DiscogsError.rateLimited(let retryAfter) {
            XCTAssertEqual(retryAfter, 60)
        }
    }
    
    func testAuthenticationFailure() async throws {
        let mockService = MockDiscogsService()
        mockService.shouldThrowError = DiscogsError.unauthorized
        
        do {
            _ = try await mockService.getUserProfile(username: "test")
            XCTFail("Expected unauthorized error")
        } catch DiscogsError.unauthorized {
            // Expected
        }
    }
}
```

### Testing with XCTestExpectation

For complex async scenarios that need precise control:

```swift
class ExpectationTests: XCTestCase {
    
    func testCallbackBasedCode() throws {
        let expectation = expectation(description: "API call completes")
        var receivedArtist: Artist?
        var receivedError: Error?
        
        // Test code that uses callbacks instead of async/await
        DiscogsServiceWithCallbacks.getArtist(id: 123) { result in
            switch result {
            case .success(let artist):
                receivedArtist = artist
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertNotNil(receivedArtist)
        XCTAssertNil(receivedError)
    }
    
    func testMultipleAsyncOperations() throws {
        let searchExpectation = expectation(description: "Search completes")
        let artistExpectation = expectation(description: "Artist fetch completes")
        
        Task {
            do {
                _ = try await discogsService.search(query: "Beatles")
                searchExpectation.fulfill()
            } catch {
                XCTFail("Search failed: \(error)")
            }
        }
        
        Task {
            do {
                _ = try await discogsService.getArtist(id: 123)
                artistExpectation.fulfill()
            } catch {
                XCTFail("Artist fetch failed: \(error)")
            }
        }
        
        waitForExpectations(timeout: 10.0)
    }
}
```

## Performance Testing

### Load Testing

```swift
class PerformanceTests: XCTestCase {
    
    func testSearchPerformance() throws {
        let service = DiscogsService(apiToken: "test-token")
        
        measure {
            let group = DispatchGroup()
            
            for i in 1...10 {
                group.enter()
                Task {
                    do {
                        _ = try await service.search(query: "test \(i)")
                    } catch {
                        print("Search \(i) failed: \(error)")
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
    }
    
    func testConcurrentRequests() throws {
        let service = MockDiscogsService()
        
        // Set up mock data
        for i in 1...100 {
            service.setMockArtist(Artist(id: i, name: "Artist \(i)"), for: i)
        }
        
        measureAsync {
            let artists = try await withThrowingTaskGroup(of: Artist.self) { group in
                for i in 1...100 {
                    group.addTask {
                        try await service.getArtist(id: i)
                    }
                }
                
                var results: [Artist] = []
                for try await artist in group {
                    results.append(artist)
                }
                return results
            }
            
            XCTAssertEqual(artists.count, 100)
        }
    }
}

// Helper for async performance testing
extension XCTestCase {
    func measureAsync(_ block: @escaping () async throws -> Void) {
        measure {
            let expectation = expectation(description: "Async performance test")
            
            Task {
                do {
                    try await block()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 30.0)
        }
    }
}
```

### Memory Testing

```swift
class MemoryTests: XCTestCase {
    
    func testMemoryLeaks() async throws {
        weak var weakService: DiscogsService?
        
        autoreleasepool {
            let service = DiscogsService(apiToken: "test-token")
            weakService = service
            
            // Perform operations
            Task {
                try? await service.search(query: "test")
            }
        }
        
        // Allow some time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertNil(weakService, "DiscogsService should be deallocated")
    }
    
    func testLargeDataHandling() async throws {
        let service = MockDiscogsService()
        
        // Create large mock dataset
        let largeResults = SearchResults(
            pagination: Pagination(pages: 100, page: 1, perPage: 50, items: 5000, urls: PaginationUrls()),
            results: (1...5000).map { id in
                SearchResult(
                    id: id,
                    type: "release",
                    title: "Large Dataset Item \(id)",
                    uri: "/releases/\(id)",
                    resourceUrl: "https://api.discogs.com/releases/\(id)",
                    thumb: "https://example.com/thumb\(id).jpg"
                )
            }
        )
        
        service.setMockSearchResults(largeResults)
        
        let results = try await service.search(query: "large dataset")
        XCTAssertEqual(results.results.count, 5000)
    }
}
```

## Test Configuration

### Test Schemes and Environment Variables

```swift
class TestConfiguration {
    static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    static var shouldUseLiveAPI: Bool {
        return ProcessInfo.processInfo.environment["USE_LIVE_API"] == "true"
    }
    
    static var testAPIToken: String? {
        return ProcessInfo.processInfo.environment["DISCOGS_TEST_TOKEN"]
    }
}

class ConfigurableTests: XCTestCase {
    var discogsService: DiscogsServiceProtocol!
    
    override func setUp() {
        super.setUp()
        
        if TestConfiguration.shouldUseLiveAPI {
            guard let token = TestConfiguration.testAPIToken else {
                XCTFail("Live API testing requires DISCOGS_TEST_TOKEN environment variable")
                return
            }
            discogsService = DiscogsService(apiToken: token)
        } else {
            discogsService = MockDiscogsService()
        }
    }
}
```

### Test Data Management

```swift
class TestDataManager {
    static let shared = TestDataManager()
    
    private let bundle = Bundle(for: TestDataManager.self)
    
    func loadTestData<T: Codable>(_ filename: String, as type: T.Type) throws -> T {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw TestError.testDataNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
    
    func loadArtistTestData() throws -> Artist {
        return try loadTestData("test-artist", as: Artist.self)
    }
    
    func loadSearchResultsTestData() throws -> SearchResults {
        return try loadTestData("test-search-results", as: SearchResults.self)
    }
}

enum TestError: Error {
    case testDataNotFound(String)
}

// Usage in tests
class TestDataTests: XCTestCase {
    
    func testWithRealData() throws {
        let artist = try TestDataManager.shared.loadArtistTestData()
        
        // Test with realistic data structure
        XCTAssertFalse(artist.name.isEmpty)
        XCTAssertGreaterThan(artist.id, 0)
    }
}
```

## Continuous Integration Testing

### GitHub Actions Test Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run unit tests
      run: swift test --filter DiscogsTests
      
  integration-tests:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run integration tests
      run: swift test --filter IntegrationTests
      env:
        DISCOGS_TEST_TOKEN: ${{ secrets.DISCOGS_TEST_TOKEN }}
        USE_LIVE_API: "false"
        
  live-api-tests:
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    - name: Run live API tests
      run: swift test --filter LiveAPITests
      env:
        DISCOGS_TEST_TOKEN: ${{ secrets.DISCOGS_TEST_TOKEN }}
        USE_LIVE_API: "true"
```

## Best Practices

### 1. Test Organization

```swift
// Organize tests by feature/component
class ArtistServiceTests: XCTestCase {
    // Test one component thoroughly
}

class SearchServiceTests: XCTestCase {
    // Test another component
}

class IntegrationTests: XCTestCase {
    // Test component interactions
}
```

### 2. Test Naming

```swift
// Use descriptive test names that explain the scenario
func testGetArtist_WhenValidID_ReturnsArtist() async throws {
    // Test implementation
}

func testGetArtist_WhenInvalidID_ThrowsNotFoundError() async throws {
    // Test implementation
}

func testSearch_WhenRateLimited_RetriesWithBackoff() async throws {
    // Test implementation
}
```

### 3. Test Independence

```swift
class IndependentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset state before each test
        MockDiscogsService.shared.reset()
    }
    
    override func tearDown() {
        // Clean up after each test
        TestConfiguration.reset()
        super.tearDown()
    }
}
```

### 4. Testing Edge Cases

```swift
class EdgeCaseTests: XCTestCase {
    
    func testEmptySearchQuery() async throws {
        // Test with empty string
        let results = try await discogsService.search(query: "")
        XCTAssertEqual(results.results.count, 0)
    }
    
    func testVeryLongSearchQuery() async throws {
        // Test with extremely long query
        let longQuery = String(repeating: "a", count: 10000)
        // Should handle gracefully without crashing
        _ = try? await discogsService.search(query: longQuery)
    }
    
    func testSpecialCharactersInQuery() async throws {
        // Test with special characters
        let specialQuery = "Björk & The Sugarcubes"
        let results = try await discogsService.search(query: specialQuery)
        // Should handle Unicode characters properly
    }
}
```

## Related Topics

- <doc:DependencyInjection>
- <doc:ErrorHandling>
- <doc:BestPractices>
- <doc:Authentication>
