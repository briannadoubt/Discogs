import Testing
@testable import Discogs

@Suite("Integration Tests - Dependency Injection")
struct DependencyInjectionIntegrationTests {
    
    @Test("All services can be initialized with HTTPClientProtocol")
    func testProtocolOrientedInitialization() async throws {
        // Given
        let mockClient = MockHTTPClient()
        
        // When - Create all services with protocol-oriented approach
        let database = DatabaseService(httpClient: mockClient)
        let collection = CollectionService(httpClient: mockClient)
        let search = SearchService(httpClient: mockClient)
        let wantlist = WantlistService(httpClient: mockClient)
        let user = UserService(httpClient: mockClient)
        let marketplace = MarketplaceService(httpClient: mockClient)
        
        // Then - All should initialize successfully
        #expect(database.httpClient as? MockHTTPClient === mockClient)
        #expect(collection.httpClient as? MockHTTPClient === mockClient)
        #expect(search.httpClient as? MockHTTPClient === mockClient)
        #expect(wantlist.httpClient as? MockHTTPClient === mockClient)
        #expect(user.httpClient as? MockHTTPClient === mockClient)
        #expect(marketplace.httpClient as? MockHTTPClient === mockClient)
    }
    
    @Test("All services can be initialized with legacy Discogs client")
    func testLegacyInitialization() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When - Create all services with legacy approach
        let database = DatabaseService(client: discogs)
        let collection = CollectionService(client: discogs)
        let search = SearchService(client: discogs)
        let wantlist = WantlistService(client: discogs)
        let user = UserService(client: discogs)
        let marketplace = MarketplaceService(client: discogs)
        
        // Then - All should initialize successfully and use the discogs client
        #expect(database.httpClient as? Discogs === discogs)
        #expect(collection.httpClient as? Discogs === discogs)
        #expect(search.httpClient as? Discogs === discogs)
        #expect(wantlist.httpClient as? Discogs === discogs)
        #expect(user.httpClient as? Discogs === discogs)
        #expect(marketplace.httpClient as? Discogs === discogs)
    }
    
    @Test("Discogs client conforms to HTTPClientProtocol")
    func testDiscogsHTTPClientConformance() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When - Cast to protocol
        let httpClient: HTTPClientProtocol = discogs
        
        // Then - Should work correctly
        #expect(httpClient.baseURL.absoluteString.contains("discogs.com"))
        #expect(httpClient.userAgent == "test")
    }
    
    @Test("DependencyContainer works with protocol types")
    func testDependencyContainer() async throws {
        // Given
        let container = DependencyContainer()
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        
        // When - Register and resolve
        await container.register(mockClient, for: HTTPClientProtocol.self)
        await container.register(service, for: DatabaseService.self)
        
        let resolvedClient = await container.resolve(HTTPClientProtocol.self)
        let resolvedService = await container.resolve(DatabaseService.self)
        
        // Then
        #expect(resolvedClient != nil)
        #expect(resolvedService != nil)
        #expect(resolvedService?.httpClient as? MockHTTPClient === mockClient)
    }
    
    @Test("MockHTTPClient can handle actual service requests")
    func testMockHTTPClientFunctionality() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        
        let mockResponse = """
        {
            "id": 123,
            "title": "Test Release",
            "year": 2023,
            "artists": [{"name": "Test Artist", "id": 1}],
            "labels": [{"name": "Test Label", "id": 1}],
            "genres": ["Electronic"],
            "styles": ["Ambient"]
        }
        """
        
        await mockClient.setMockResponse(json: mockResponse)
        
        // When
        let release: ReleaseDetails = try await service.getRelease(id: 123)
        
        // Then
        #expect(release.id == 123)
        #expect(release.title == "Test Release")
        #expect(release.year == 2023)
        
        // Verify request was made correctly
        let request = await mockClient.lastRequest
        #expect(request != nil)
        let requestData = try #require(request)
        #expect(requestData.url.pathComponents.contains("releases"))
        #expect(requestData.url.pathComponents.contains("123"))
        #expect(requestData.method == "GET")
    }
    
    @Test("Protocol-oriented and legacy approaches produce same results")
    func testConsistencyBetweenApproaches() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // Create services both ways
        let protocolService = DatabaseService(httpClient: mockClient)
        let legacyService = DatabaseService(client: discogs)
        
        // Mock response
        let mockResponse = """
        {
            "id": 456,
            "name": "Test Artist",
            "resource_url": "https://api.discogs.com/artists/456"
        }
        """
        
        await mockClient.setMockResponse(json: mockResponse)
        
        // When - Test protocol-oriented service
        let protocolResult: Artist = try await protocolService.getArtist(id: 456)
        
        // Then - Both services should have same interface
        #expect(protocolResult.id == 456)
        #expect(protocolResult.name == "Test Artist")
        
        // Verify both services have the same public interface
        #expect(type(of: protocolService) == type(of: legacyService))
    }
}
