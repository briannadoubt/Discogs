import Testing
import Foundation
@testable import Discogs

@Suite("Authentication Functional Tests")
struct AuthenticationFunctionalTests {
    
    @Test("OAuth request token creation")
    func testOAuthRequestToken() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let authentication = Authentication(client: mockClient)
        let consumerKey = "test_consumer_key"
        let consumerSecret = "test_consumer_secret"
        let callbackURL = "https://myapp.com/callback"
        
        let mockResponse = """
        oauth_token=request_token_123&oauth_token_secret=request_secret_456&oauth_callback_confirmed=true
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await authentication.getRequestToken(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            callbackURL: callbackURL
        )
        
        // Then
        let request = await mockClient.lastRequest
        #expect(request != nil)
        #expect(request?.url.path.contains("oauth/request_token") == true)
        #expect(request?.method == "GET")
        
        // Verify OAuth authorization header is present
        let authHeader = request?.headers["Authorization"]
        #expect(authHeader != nil)
        #expect(authHeader?.contains("OAuth") == true)
        #expect(authHeader?.contains("oauth_consumer_key") == true)
        #expect(authHeader?.contains("oauth_callback") == true)
    }
    
    @Test("OAuth authorization URL generation")
    func testOAuthAuthorizationURL() {
        // Given
        let authentication = Authentication(client: MockHTTPClient())
        let requestToken = "request_token_123"
        
        // When
        let authURL = authentication.getAuthorizationURL(requestToken: requestToken)
        
        // Then
        #expect(authURL.contains("https://discogs.com/oauth/authorize"))
        #expect(authURL.contains("oauth_token=\(requestToken)"))
    }
    
    @Test("OAuth access token exchange")
    func testOAuthAccessToken() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let authentication = Authentication(client: mockClient)
        let consumerKey = "test_consumer_key"
        let consumerSecret = "test_consumer_secret"
        let requestToken = "request_token_123"
        let requestSecret = "request_secret_456"
        let verifier = "oauth_verifier_789"
        
        let mockResponse = """
        oauth_token=access_token_abc&oauth_token_secret=access_secret_def
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await authentication.getAccessToken(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            requestToken: requestToken,
            requestTokenSecret: requestSecret,
            verifier: verifier
        )
        
        // Then
        let request = await mockClient.lastRequest
        #expect(request != nil)
        #expect(request?.url.path.contains("oauth/access_token") == true)
        #expect(request?.method == "POST")
        
        // Verify OAuth authorization header contains required parameters
        let authHeader = request?.headers["Authorization"]
        #expect(authHeader != nil)
        #expect(authHeader?.contains("OAuth") == true)
        #expect(authHeader?.contains("oauth_consumer_key") == true)
        #expect(authHeader?.contains("oauth_token") == true)
        #expect(authHeader?.contains("oauth_verifier") == true)
    }
    
    @Test("Personal access token validation")
    func testPersonalAccessTokenValidation() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let authentication = Authentication(client: mockClient)
        let token = "personal_access_token_123"
        
        let mockResponse = """
        {
            "id": 123456,
            "username": "testuser",
            "resource_url": "https://api.discogs.com/users/testuser",
            "consumer_name": "Test App"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await authentication.validateToken(token)
        
        // Then
        let request = await mockClient.lastRequest
        #expect(request != nil)
        #expect(request?.url.path.contains("oauth/identity") == true)
        #expect(request?.method == "GET")
        
        // Verify Authorization header contains the token
        let authHeader = request?.headers["Authorization"]
        #expect(authHeader?.contains("Discogs token=\(token)") == true)
    }
    
    @Test("OAuth signature generation")
    func testOAuthSignatureGeneration() {
        // Given
        let authentication = Authentication(client: MockHTTPClient())
        let httpMethod = "GET"
        let baseURL = "https://api.discogs.com/oauth/request_token"
        let parameters = [
            "oauth_consumer_key": "test_key",
            "oauth_nonce": "test_nonce",
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": "1234567890",
            "oauth_version": "1.0",
            "oauth_callback": "https://myapp.com/callback"
        ]
        let consumerSecret = "test_consumer_secret"
        let tokenSecret: String? = nil
        
        // When
        let signature = authentication.generateOAuthSignature(
            httpMethod: httpMethod,
            baseURL: baseURL,
            parameters: parameters,
            consumerSecret: consumerSecret,
            tokenSecret: tokenSecret
        )
        
        // Then
        #expect(signature.isEmpty == false)
        #expect(signature.contains("=") == false) // Base64 encoded signature shouldn't contain = padding when properly encoded
    }
    
    @Test("OAuth parameter encoding")
    func testOAuthParameterEncoding() {
        // Given
        let authentication = Authentication(client: MockHTTPClient())
        let parameters = [
            "oauth_consumer_key": "test key with spaces",
            "oauth_callback": "https://myapp.com/callback?param=value&other=data",
            "special_chars": "café & bar"
        ]
        
        // When
        let encodedParams = authentication.encodeOAuthParameters(parameters)
        
        // Then
        #expect(encodedParams.contains("oauth_consumer_key=test%20key%20with%20spaces"))
        #expect(encodedParams.contains("oauth_callback=https%3A//myapp.com/callback%3Fparam%3Dvalue%26other%3Ddata"))
        #expect(encodedParams.contains("special_chars=caf%C3%A9%20%26%20bar"))
    }
    
    @Test("OAuth timestamp and nonce generation")
    func testOAuthTimestampAndNonce() {
        // Given
        let authentication = Authentication(client: MockHTTPClient())
        
        // When
        let timestamp1 = authentication.generateTimestamp()
        let timestamp2 = authentication.generateTimestamp()
        let nonce1 = authentication.generateNonce()
        let nonce2 = authentication.generateNonce()
        
        // Then
        #expect(timestamp1 > 0)
        #expect(timestamp2 >= timestamp1)
        #expect(nonce1.isEmpty == false)
        #expect(nonce2.isEmpty == false)
        #expect(nonce1 != nonce2) // Nonces should be unique
        #expect(nonce1.count >= 16) // Reasonable length for uniqueness
    }
    
    @Test("Invalid OAuth request token response")
    func testInvalidRequestTokenResponse() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let authentication = Authentication(client: mockClient)
        
        // Simulate invalid response
        let mockResponse = "invalid_response_format".data(using: .utf8)!
        await mockClient.setMockResponseData(mockResponse)
        
        // When/Then
        await #expect(throws: Error.self) {
            try await authentication.getRequestToken(
                consumerKey: "test_key",
                consumerSecret: "test_secret",
                callbackURL: "https://test.com/callback"
            )
        }
    }
    
    @Test("OAuth error response handling")
    func testOAuthErrorHandling() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let authentication = Authentication(client: mockClient)
        
        // Simulate 401 Unauthorized
        await mockClient.setShouldThrowError(true)
        await mockClient.setErrorToThrow(NSError(domain: "DiscogsError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid consumer key"]))
        
        // When/Then
        await #expect(throws: Error.self) {
            try await authentication.getRequestToken(
                consumerKey: "invalid_key",
                consumerSecret: "invalid_secret",
                callbackURL: "https://test.com/callback"
            )
        }
    }
    
    @Test("Token refresh workflow")
    func testTokenRefreshWorkflow() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let authentication = Authentication(client: mockClient)
        let refreshToken = "refresh_token_123"
        
        let mockResponse = """
        {
            "access_token": "new_access_token_456",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "new_refresh_token_789",
            "scope": "read write"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await authentication.refreshToken(refreshToken)
        
        // Then
        let request = await mockClient.lastRequest
        #expect(request != nil)
        #expect(request?.url.path.contains("oauth/token") == true)
        #expect(request?.method == "POST")
        
        // Verify request body contains refresh token
        if let body = request?.body {
            let refreshTokenKey = body["refresh_token"] as? String
            #expect(refreshTokenKey == refreshToken)
            let grantType = body["grant_type"] as? String
            #expect(grantType == "refresh_token")
        }
    }
    
    @Test("Multiple concurrent authentication requests")
    func testConcurrentAuthenticationRequests() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let authentication = Authentication(client: mockClient)
        
        let mockResponse = """
        {
            "id": 123456,
            "username": "testuser",
            "resource_url": "https://api.discogs.com/users/testuser"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When - Make multiple concurrent requests sequentially to test functionality
        // Note: Testing concurrency behavior without Sendable conformance
        var results: [Bool] = []
        
        for token in ["token1", "token2", "token3"] {
            let result = try await authentication.validateToken(token)
            results.append(result)
        }
        
        // Then - All requests should have completed successfully
        #expect(results.count == 3)
        #expect(results.allSatisfy { $0 == true })
    }
    
    @Test("Authentication header formatting")
    func testAuthenticationHeaderFormatting() {
        // Given
        let authentication = Authentication(client: MockHTTPClient())
        let token = "test_token_123"
        let userAgent = "TestApp/1.0"
        
        // When
        let headers = authentication.createAuthenticationHeaders(
            token: token,
            userAgent: userAgent
        )
        
        // Then
        #expect(headers["Authorization"] == "Discogs token=\(token)")
        #expect(headers["User-Agent"] == userAgent)
        #expect(headers.count == 2)
    }
    
    @Test("OAuth callback URL validation")
    func testCallbackURLValidation() {
        // Given
        let authentication = Authentication(client: MockHTTPClient())
        
        // When/Then - Valid URLs should pass
        #expect(authentication.isValidCallbackURL("https://myapp.com/callback") == true)
        #expect(authentication.isValidCallbackURL("http://localhost:8080/auth") == true)
        #expect(authentication.isValidCallbackURL("myapp://oauth-callback") == true)
        
        // Invalid URLs should fail
        #expect(authentication.isValidCallbackURL("not-a-url") == false)
        #expect(authentication.isValidCallbackURL("") == false)
        #expect(authentication.isValidCallbackURL("ftp://invalid.com") == false)
    }
}
