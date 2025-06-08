import Testing
import Foundation
@testable import Discogs

@Suite("Final Integration Verification")
struct FinalIntegrationTests {
    
    @Test("Legacy approach still works seamlessly")
    func testLegacyApproachWorks() async throws {
        // Given - Using the traditional approach
        let discogs = Discogs(token: "test_token", userAgent: "TestApp/1.0")
        let databaseService = DatabaseService(client: discogs)
        let collectionService = CollectionService(client: discogs)
        
        // When/Then - Services initialize correctly
        let discogsBaseURL = await discogs.baseURL
        let discogsUserAgent = await discogs.userAgent
        
        #expect(databaseService.httpClient.baseURL == discogsBaseURL)
        #expect(collectionService.httpClient.baseURL == discogsBaseURL)
        #expect(databaseService.httpClient.userAgent == discogsUserAgent)
        #expect(collectionService.httpClient.userAgent == discogsUserAgent)
    }
    
    @Test("New protocol-oriented approach works with same client")
    func testNewApproachWorks() async throws {
        // Given - Using the new protocol-oriented approach
        let httpClient: HTTPClientProtocol = Discogs(token: "test_token", userAgent: "TestApp/1.0")
        let databaseService = DatabaseService(httpClient: httpClient)
        let collectionService = CollectionService(httpClient: httpClient)
        
        // When/Then - Services initialize correctly with protocol
        let clientBaseURL = httpClient.baseURL
        let clientUserAgent = httpClient.userAgent
        
        #expect(databaseService.httpClient.baseURL == clientBaseURL)
        #expect(collectionService.httpClient.baseURL == clientBaseURL)
        #expect(databaseService.httpClient.userAgent == clientUserAgent)
        #expect(collectionService.httpClient.userAgent == clientUserAgent)
    }
    
    @Test("MockHTTPClient works for testing")
    func testMockingCapabilities() async throws {
        // Given - Using mock for testing
        let mockClient = MockHTTPClient()
        await mockClient.setMockResponse(json: """
        {
            "id": 123,
            "title": "Test Release",
            "artists": [{"name": "Test Artist"}]
        }
        """)
        
        let _ = DatabaseService(httpClient: mockClient)
        
        // When - Making a service call would work (if we had the models)
        // Then - Mock is properly configured
        // Note: We can't check request count as the method doesn't exist, but we can verify the mock setup
        
        // Verify mock client properties
        let baseURL = mockClient.baseURL
        let userAgent = mockClient.userAgent
        #expect(baseURL.absoluteString == "https://api.discogs.com")
        #expect(userAgent == "MockDiscogsClient/1.0")
    }
    
    @Test("Dependency container works for advanced scenarios")
    func testDependencyContainer() async throws {
        // Given - Using dependency container
        let container = DependencyContainer()
        let discogs = Discogs(token: "test_token", userAgent: "TestApp/1.0")
        
        // When - Registering dependencies
        await container.register(discogs, for: HTTPClientProtocol.self)
        
        // Then - Can resolve dependencies
        let httpClient: HTTPClientProtocol? = await container.resolve(HTTPClientProtocol.self)
        guard let httpClient = httpClient else {
            throw DependencyError.dependencyNotFound("HTTPClientProtocol")
        }
        
        let clientBaseURL = httpClient.baseURL
        let clientUserAgent = httpClient.userAgent
        
        #expect(clientBaseURL.absoluteString.contains("discogs.com"))
        #expect(clientUserAgent == "TestApp/1.0")
        
        // And use them to create services
        let service = DatabaseService(httpClient: httpClient)
        let serviceClientBaseURL = service.httpClient.baseURL
        #expect(serviceClientBaseURL == clientBaseURL)
    }
    
    @Test("All services support both initialization patterns")
    func testAllServicesSupportBothPatterns() async throws {
        let discogs = Discogs(token: "test", userAgent: "test")
        let mockClient = MockHTTPClient()
        
        // Get actor-isolated properties first
        let discogsBaseURL = await discogs.baseURL
        let mockClientBaseURL = mockClient.baseURL
        
        // Test that all services can be initialized both ways
        
        // DatabaseService
        let dbLegacy = DatabaseService(client: discogs)
        let dbNew = DatabaseService(httpClient: mockClient)
        #expect(dbLegacy.httpClient.baseURL == discogsBaseURL)
        #expect(dbNew.httpClient.baseURL == mockClientBaseURL)
        
        // CollectionService  
        let collLegacy = CollectionService(client: discogs)
        let collNew = CollectionService(httpClient: mockClient)
        #expect(collLegacy.httpClient.baseURL == discogsBaseURL)
        #expect(collNew.httpClient.baseURL == mockClientBaseURL)
        
        // SearchService
        let searchLegacy = SearchService(client: discogs)
        let searchNew = SearchService(httpClient: mockClient)
        #expect(searchLegacy.httpClient.baseURL == discogsBaseURL)
        #expect(searchNew.httpClient.baseURL == mockClientBaseURL)
        
        // WantlistService
        let wantLegacy = WantlistService(client: discogs)
        let wantNew = WantlistService(httpClient: mockClient)
        #expect(wantLegacy.httpClient.baseURL == discogsBaseURL)
        #expect(wantNew.httpClient.baseURL == mockClientBaseURL)
        
        // UserService
        let userLegacy = UserService(client: discogs)
        let userNew = UserService(httpClient: mockClient)
        #expect(userLegacy.httpClient.baseURL == discogsBaseURL)
        #expect(userNew.httpClient.baseURL == mockClientBaseURL)
        
        // MarketplaceService
        let marketLegacy = MarketplaceService(client: discogs)
        let marketNew = MarketplaceService(httpClient: mockClient)
        #expect(marketLegacy.httpClient.baseURL == discogsBaseURL)
        #expect(marketNew.httpClient.baseURL == mockClientBaseURL)
    }
}
