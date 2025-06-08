import Foundation

/// Rate limit information provided by the Discogs API
public struct RateLimit: Sendable {
    /// Total number of requests allowed per minute
    public let limit: Int
    
    /// Number of remaining requests in the current window
    public let remaining: Int
    
    /// Time when the rate limit window resets (in seconds since epoch)
    public let resetTime: TimeInterval
    
    /// Initialize from HTTP response headers
    init?(headers: [AnyHashable: Any]) {
        guard let limitString = headers["X-Discogs-Ratelimit"] as? String,
              let remainingString = headers["X-Discogs-Ratelimit-Remaining"] as? String,
              let resetString = headers["X-Discogs-Ratelimit-Reset"] as? String,
              let limit = Int(limitString),
              let remaining = Int(remainingString),
              let reset = TimeInterval(resetString) else {
            return nil
        }
        
        self.limit = limit
        self.remaining = remaining
        self.resetTime = reset
    }
    
    /// Check if we're approaching the rate limit (less than 10% remaining)
    public var isApproachingLimit: Bool {
        let threshold = max(1, limit / 10) // At least 1 request, or 10% of limit
        return remaining <= threshold
    }
    
    /// Calculate delay until rate limit resets
    public var delayUntilReset: TimeInterval {
        let now = Date().timeIntervalSince1970
        return max(0, resetTime - now)
    }
}

/// Rate limiting configuration and retry logic
public struct RateLimitConfig: Sendable {
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Base delay for exponential backoff (in seconds)
    public let baseDelay: TimeInterval
    
    /// Maximum delay between retries (in seconds)
    public let maxDelay: TimeInterval
    
    /// Whether to enable automatic retries
    public let enableAutoRetry: Bool
    
    /// Whether to respect rate limit reset time
    public let respectResetTime: Bool
    
    /// Initialize rate limit configuration
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - baseDelay: Base delay for exponential backoff in seconds (default: 1.0)
    ///   - maxDelay: Maximum delay between retries in seconds (default: 60.0)
    ///   - enableAutoRetry: Whether to enable automatic retries (default: true)
    ///   - respectResetTime: Whether to respect rate limit reset time (default: true)
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        enableAutoRetry: Bool = true,
        respectResetTime: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.enableAutoRetry = enableAutoRetry
        self.respectResetTime = respectResetTime
    }
    
    /// Calculate exponential backoff delay
    /// 
    /// Calculates the delay before retrying a failed request using exponential
    /// backoff with jitter. If rate limit information is available and the limit
    /// is exceeded, respects the reset time.
    /// - Parameters:
    ///   - attempt: The current retry attempt number (0-based)
    ///   - rateLimit: Optional rate limit information from the API
    /// - Returns: The delay in seconds before the next retry attempt
    public func calculateDelay(for attempt: Int, rateLimit: RateLimit? = nil) -> TimeInterval {
        // If we have rate limit info and should respect reset time
        if respectResetTime, let rateLimit = rateLimit, rateLimit.remaining == 0 {
            // Wait until rate limit resets, but cap at maxDelay
            return min(rateLimit.delayUntilReset, maxDelay)
        }
        
        // Exponential backoff: baseDelay * (2^attempt) with jitter
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0.8...1.2) // Add 20% jitter
        let delayWithJitter = exponentialDelay * jitter
        
        return min(delayWithJitter, maxDelay)
    }
}

/// Default rate limit configuration presets
/// 
/// Provides common rate limiting configurations for different use cases.
public extension RateLimitConfig {
    /// Default configuration: 3 retries, 1s base delay, 60s max delay
    static let `default` = RateLimitConfig()
    
    /// Aggressive configuration: More retries with shorter delays for high-throughput scenarios
    static let aggressive = RateLimitConfig(maxRetries: 5, baseDelay: 0.5)
    
    /// Conservative configuration: Fewer retries with longer delays for reliability
    static let conservative = RateLimitConfig(maxRetries: 2, baseDelay: 2.0, maxDelay: 120.0)
}