import Foundation
import Testing
@testable import Discogs

@Suite("Enhanced Rate Limiting Tests")
struct RateLimitEnhancedTests {
    
    @Test("RateLimitConfig initializes with defaults")
    func testRateLimitConfigDefaults() {
        // Given/When
        let config = RateLimitConfig.default
        
        // Then
        #expect(config.maxRetries == 3)
        #expect(config.baseDelay == 1.0)
        #expect(config.maxDelay == 60.0)
        #expect(config.enableAutoRetry == true)
        #expect(config.respectResetTime == true)
    }
    
    @Test("RateLimitConfig calculates exponential backoff correctly")
    func testExponentialBackoffCalculation() {
        // Given
        let config = RateLimitConfig(baseDelay: 1.0, maxDelay: 60.0)
        
        // When/Then
        let delay0 = config.calculateDelay(for: 0)
        let delay1 = config.calculateDelay(for: 1)
        let delay2 = config.calculateDelay(for: 2)
        
        // Verify exponential growth (with jitter, delays won't be exact)
        #expect(delay0 >= 0.8 && delay0 <= 1.2) // ~1.0 with jitter
        #expect(delay1 >= 1.6 && delay1 <= 2.4) // ~2.0 with jitter
        #expect(delay2 >= 3.2 && delay2 <= 4.8) // ~4.0 with jitter
    }
    
    @Test("RateLimitConfig respects maximum delay")
    func testMaxDelayRespected() {
        // Given
        let config = RateLimitConfig(baseDelay: 10.0, maxDelay: 15.0)
        
        // When
        let delay = config.calculateDelay(for: 5) // Would be 10 * 2^5 = 320 without max
        
        // Then
        #expect(delay <= 15.0)
    }
    
    @Test("RateLimitConfig respects reset time when rate limit exhausted")
    func testResetTimeRespected() {
        // Given
        let config = RateLimitConfig(respectResetTime: true)
        let futureResetTime = Date().timeIntervalSince1970 + 30.0
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "60",
            "X-Discogs-Ratelimit-Remaining": "0",
            "X-Discogs-Ratelimit-Reset": String(Int(futureResetTime))
        ]
        let rateLimit = RateLimit(headers: headers)
        
        // When
        let delay = config.calculateDelay(for: 0, rateLimit: rateLimit)
        
        // Then
        #expect(delay > 25.0 && delay <= 30.0) // Should be close to reset time
    }
    
    @Test("RateLimit detects approaching limit correctly")
    func testApproachingLimitDetection() {
        // Given - 5 requests remaining out of 60 (less than 10%)
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "60",
            "X-Discogs-Ratelimit-Remaining": "5",
            "X-Discogs-Ratelimit-Reset": "1234567890"
        ]
        let rateLimit = RateLimit(headers: headers)!
        
        // When/Then
        #expect(rateLimit.isApproachingLimit == true)
        
        // Given - 10 requests remaining (exactly 10%)
        let headers2: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "60",
            "X-Discogs-Ratelimit-Remaining": "6",
            "X-Discogs-Ratelimit-Reset": "1234567890"
        ]
        let rateLimit2 = RateLimit(headers: headers2)!
        
        // When/Then
        #expect(rateLimit2.isApproachingLimit == true)
        
        // Given - 20 requests remaining (more than 10%)
        let headers3: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "60",
            "X-Discogs-Ratelimit-Remaining": "20",
            "X-Discogs-Ratelimit-Reset": "1234567890"
        ]
        let rateLimit3 = RateLimit(headers: headers3)!
        
        // When/Then
        #expect(rateLimit3.isApproachingLimit == false)
    }
    
    @Test("RateLimit calculates delay until reset correctly")
    func testDelayUntilReset() {
        // Given
        let futureTime = Date().timeIntervalSince1970 + 45.0
        let headers: [AnyHashable: Any] = [
            "X-Discogs-Ratelimit": "60",
            "X-Discogs-Ratelimit-Remaining": "0",
            "X-Discogs-Ratelimit-Reset": String(Int(futureTime))
        ]
        let rateLimit = RateLimit(headers: headers)!
        
        // When
        let delay = rateLimit.delayUntilReset
        
        // Then
        #expect(delay > 40.0 && delay <= 45.0) // Should be close to 45 seconds
        #expect(delay >= 0) // Should never be negative
    }
    
    @Test("Discogs client accepts rate limit configuration")
    func testDiscogsClientWithRateLimitConfig() {
        // Given
        let customConfig = RateLimitConfig(
            maxRetries: 5,
            baseDelay: 2.0,
            enableAutoRetry: false
        )
        
        // When
        let discogs = Discogs(
            token: "test-token",
            userAgent: "TestApp/1.0",
            rateLimitConfig: customConfig
        )
        
        // Then
        Task {
            let config = await discogs.rateLimitConfig
            #expect(config.maxRetries == 5)
            #expect(config.baseDelay == 2.0)
            #expect(config.enableAutoRetry == false)
        }
    }
    
    @Test("Discogs client uses default rate limit configuration when not specified")
    func testDiscogsClientDefaultRateLimitConfig() {
        // Given/When
        let discogs = Discogs(token: "test-token", userAgent: "TestApp/1.0")
        
        // Then
        Task {
            let config = await discogs.rateLimitConfig
            #expect(config.maxRetries == 3)
            #expect(config.baseDelay == 1.0)
            #expect(config.enableAutoRetry == true)
        }
    }
    
    @Test("Predefined rate limit configurations work correctly")
    func testPredefinedConfigurations() {
        // Test default configuration
        let defaultConfig = RateLimitConfig.default
        #expect(defaultConfig.maxRetries == 3)
        #expect(defaultConfig.enableAutoRetry == true)
        
        // Test aggressive configuration  
        let aggressiveConfig = RateLimitConfig.aggressive
        #expect(aggressiveConfig.maxRetries == 5)
        #expect(aggressiveConfig.baseDelay == 0.5)
        
        // Test conservative configuration
        let conservativeConfig = RateLimitConfig.conservative
        #expect(conservativeConfig.maxRetries == 2)
        #expect(conservativeConfig.baseDelay == 2.0)
        #expect(conservativeConfig.maxDelay == 120.0)
    }
}
