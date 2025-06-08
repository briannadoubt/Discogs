import Testing
@testable import Discogs

@Suite("Rate Limit Tests")
struct RateLimitTests {
    
    @Test("RateLimit initializes correctly from valid headers")
    func testValidHeaderInitialization() {
        // Given
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "240",
            "X-Discogs-Ratelimit-Remaining": "199",
            "X-Discogs-Ratelimit-Reset": "1625097600"
        ]
        
        // When
        let rateLimit = RateLimit(headers: headers)
        
        // Then
        #expect(rateLimit != nil)
        #expect(rateLimit?.limit == 240)
        #expect(rateLimit?.remaining == 199)
        #expect(rateLimit?.resetTime == 1625097600)
    }
    
    @Test("RateLimit returns nil for missing headers")
    func testMissingHeaders() {
        // Given
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "240",
            // Missing remaining and reset headers
        ]
        
        // When
        let rateLimit = RateLimit(headers: headers)
        
        // Then
        #expect(rateLimit == nil)
    }
    
    @Test("RateLimit returns nil for invalid header values")
    func testInvalidHeaderValues() {
        // Given
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "not_a_number",
            "X-Discogs-Ratelimit-Remaining": "199",
            "X-Discogs-Ratelimit-Reset": "1625097600"
        ]
        
        // When
        let rateLimit = RateLimit(headers: headers)
        
        // Then
        #expect(rateLimit == nil)
    }
    
    @Test("RateLimit returns nil for wrong header types")
    func testWrongHeaderTypes() {
        // Given
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": 240, // Integer instead of string
            "X-Discogs-Ratelimit-Remaining": "199",
            "X-Discogs-Ratelimit-Reset": "1625097600"
        ]
        
        // When
        let rateLimit = RateLimit(headers: headers)
        
        // Then
        #expect(rateLimit == nil)
    }
    
    @Test("RateLimit properties are correctly stored")
    func testPropertiesStorage() {
        // Given
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "100",
            "X-Discogs-Ratelimit-Remaining": "50",
            "X-Discogs-Ratelimit-Reset": "1625097600"
        ]
        
        // When
        let rateLimit = RateLimit(headers: headers)!
        
        // Then
        #expect(rateLimit.limit == 100)
        #expect(rateLimit.remaining == 50)
        #expect(rateLimit.resetTime == 1625097600)
    }
    
    @Test("RateLimit conforms to Sendable")
    func testSendableConformance() {
        // Given
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "240",
            "X-Discogs-Ratelimit-Remaining": "199",
            "X-Discogs-Ratelimit-Reset": "1625097600"
        ]
        let rateLimit = RateLimit(headers: headers)!
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = rateLimit
        }
    }
}
