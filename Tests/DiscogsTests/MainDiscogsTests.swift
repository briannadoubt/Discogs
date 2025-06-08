import Testing
@testable import Discogs

@Suite("Discogs Tests")
struct DiscogsTests {
    
    @Test("Discogs initializes with token authentication")
    func testTokenInitialization() async {
        // Given
        let token = "test_token_123"
        let userAgent = "TestApp/1.0"
        
        // When
        let discogs = Discogs(token: token, userAgent: userAgent)
        
        // Then
        #expect(await discogs.userAgent == userAgent)
        switch await discogs.authMethod {
        case .token(let storedToken):
            #expect(storedToken == token)
        case .oauth:
            Issue.record("Expected token authentication")
        }
    }
    
    @Test("Discogs initializes with OAuth authentication")
    func testOAuthInitialization() async {
        // Given
        let consumerKey = "consumer_key"
        let consumerSecret = "consumer_secret" 
        let accessToken = "access_token"
        let accessTokenSecret = "access_token_secret"
        let userAgent = "TestApp/1.0"
        
        // When
        let discogs = Discogs(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret,
            userAgent: userAgent
        )
        
        // Then
        #expect(await discogs.userAgent == userAgent)
        switch await discogs.authMethod {
        case .token:
            Issue.record("Expected OAuth authentication")
        case .oauth(let key, let secret, let token, let tokenSecret):
            #expect(key == consumerKey)
            #expect(secret == consumerSecret)
            #expect(token == accessToken)
            #expect(tokenSecret == accessTokenSecret)
        }
    }
    
    @Test("Discogs base URL is correct")
    func testBaseURL() async {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // Then
        #expect(await discogs.baseURL.absoluteString == "https://api.discogs.com")
    }
    
    @Test("Discogs services are lazily initialized")
    func testServiceInitialization() async {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When/Then - Accessing services should not throw
        let _ = await discogs.database
        let _ = await discogs.collection
        let _ = await discogs.marketplace
        let _ = await discogs.user
        let _ = await discogs.wantlist
        let _ = await discogs.search
    }
    
    @Test("Rate limit is initially nil")
    func testInitialRateLimit() async {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // Then
        #expect(await discogs.rateLimit == nil)
    }
    
    @Test("Discogs is an actor")
    func testActorConformance() async {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When/Then - This test passes if we can access properties in async context
        let userAgent = await discogs.userAgent
        let baseURL = await discogs.baseURL
        #expect(!userAgent.isEmpty)
        #expect(baseURL.absoluteString == "https://api.discogs.com")
    }
}
