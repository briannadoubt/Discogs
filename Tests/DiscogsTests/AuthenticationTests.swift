import Testing
@testable import Discogs

@Suite("Authentication Tests")
struct AuthenticationTests {
    
    @Test("Token authentication case stores token correctly")
    func testTokenAuthentication() {
        // Given
        let token = "test_token_123"
        
        // When
        let authMethod = AuthMethod.token(token)
        
        // Then
        switch authMethod {
        case .token(let storedToken):
            #expect(storedToken == token)
        case .oauth:
            Issue.record("Expected token authentication but got OAuth")
        }
    }
    
    @Test("OAuth authentication case stores credentials correctly")
    func testOAuthAuthentication() {
        // Given
        let consumerKey = "consumer_key"
        let consumerSecret = "consumer_secret"
        let accessToken = "access_token"
        let accessTokenSecret = "access_token_secret"
        
        // When
        let authMethod = AuthMethod.oauth(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret
        )
        
        // Then
        switch authMethod {
        case .token:
            Issue.record("Expected OAuth authentication but got token")
        case .oauth(let key, let secret, let token, let tokenSecret):
            #expect(key == consumerKey)
            #expect(secret == consumerSecret)
            #expect(token == accessToken)
            #expect(tokenSecret == accessTokenSecret)
        }
    }
    
    @Test("AuthMethod conforms to Sendable")
    func testSendableConformance() {
        // Given
        let authMethod = AuthMethod.token("test")
        
        // When/Then - This test passes if the code compiles
        // since Sendable conformance is checked at compile time
        Task {
            let _ = authMethod
        }
    }
}
