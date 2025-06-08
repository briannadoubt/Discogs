# Rate Limiting

Learn how to handle Discogs API rate limits effectively and implement best practices for respectful API usage.

## Overview

The Discogs API implements rate limiting to ensure fair usage and maintain service quality for all users. Understanding and properly handling rate limits is crucial for building reliable applications that interact with the Discogs API.

## Rate Limit Basics

### Current Limits

Discogs API enforces the following rate limits:

- **Authenticated requests**: 60 requests per minute
- **Unauthenticated requests**: 25 requests per minute  
- **Search requests**: Additional restrictions may apply
- **Image requests**: Separate rate limiting

### Rate Limit Headers

The API returns rate limit information in response headers:

```
X-Discogs-Ratelimit: 60
X-Discogs-Ratelimit-Used: 45
X-Discogs-Ratelimit-Remaining: 15
```

## Built-in Rate Limiting

The SDK includes automatic rate limit handling:

```swift
// The SDK automatically manages rate limits
let discogsService = DiscogsService(apiToken: "your-token")

// Requests are automatically throttled
let artist = try await discogsService.getArtist(id: 1234567)
let release = try await discogsService.getRelease(id: 7654321)
```

### RateLimiter Class

The SDK uses an internal `RateLimiter` class to manage request timing:

```swift
public class RateLimiter {
    private let maxRequestsPerMinute: Int
    private let timeWindow: TimeInterval = 60.0
    private var requestTimes: [Date] = []
    private let queue = DispatchQueue(label: "rate-limiter", attributes: .concurrent)
    
    public init(maxRequestsPerMinute: Int = 60) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }
    
    public func executeRequest<T>(_ request: @escaping () async throws -> T) async throws -> T {
        await waitIfNeeded()
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let result = try await request()
                    await recordRequest()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

## Manual Rate Limit Handling

For advanced use cases, you can implement custom rate limiting:

### Basic Rate Limiting

```swift
class CustomRateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 1.0 // 1 second between requests
    
    func throttle() async {
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumInterval {
                let waitTime = minimumInterval - timeSinceLastRequest
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
}

// Usage
let rateLimiter = CustomRateLimiter()

for artistId in artistIds {
    await rateLimiter.throttle()
    let artist = try await discogsService.getArtist(id: artistId)
    // Process artist
}
```

### Token Bucket Algorithm

For more sophisticated rate limiting:

```swift
class TokenBucketRateLimiter {
    private let capacity: Int
    private let refillRate: Double // tokens per second
    private var tokens: Double
    private var lastRefill: Date
    private let queue = DispatchQueue(label: "token-bucket")
    
    init(capacity: Int, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = Double(capacity)
        self.lastRefill = Date()
    }
    
    func acquireToken() async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                self.refillTokens()
                
                if self.tokens >= 1.0 {
                    self.tokens -= 1.0
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func refillTokens() {
        let now = Date()
        let timePassed = now.timeIntervalSince(lastRefill)
        let tokensToAdd = timePassed * refillRate
        
        tokens = min(Double(capacity), tokens + tokensToAdd)
        lastRefill = now
    }
}
```

## Handling Rate Limit Responses

### Automatic Retry with Backoff

```swift
func fetchWithRateLimit<T>(
    operation: @escaping () async throws -> T,
    maxRetries: Int = 3
) async throws -> T {
    var attempt = 0
    
    while attempt < maxRetries {
        do {
            return try await operation()
        } catch DiscogsError.rateLimited(let retryAfter) {
            attempt += 1
            
            if attempt >= maxRetries {
                throw DiscogsError.rateLimited(retryAfter: retryAfter)
            }
            
            // Wait for the specified time or use exponential backoff
            let waitTime = retryAfter ?? pow(2.0, Double(attempt)) * 1.0
            print("Rate limited. Waiting \(waitTime) seconds before retry \(attempt)/\(maxRetries)")
            
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }
    
    throw DiscogsError.rateLimited(retryAfter: nil)
}

// Usage
let artist = try await fetchWithRateLimit {
    try await discogsService.getArtist(id: artistId)
}
```

### Batch Processing with Rate Limiting

```swift
func processBatch<T, R>(
    items: [T],
    batchSize: Int = 10,
    delayBetweenBatches: TimeInterval = 60.0,
    processor: @escaping (T) async throws -> R
) async throws -> [R] {
    var results: [R] = []
    
    for batch in items.chunked(into: batchSize) {
        print("Processing batch of \(batch.count) items...")
        
        // Process batch concurrently but respect rate limits
        let batchResults = try await withThrowingTaskGroup(of: R.self) { group in
            for item in batch {
                group.addTask {
                    try await processor(item)
                }
            }
            
            var batchResults: [R] = []
            for try await result in group {
                batchResults.append(result)
            }
            return batchResults
        }
        
        results.append(contentsOf: batchResults)
        
        // Wait between batches to avoid rate limiting
        if batch != items.chunked(into: batchSize).last {
            print("Waiting \(delayBetweenBatches) seconds before next batch...")
            try await Task.sleep(nanoseconds: UInt64(delayBetweenBatches * 1_000_000_000))
        }
    }
    
    return results
}
```

## Best Practices

### 1. Use Authentication

Always authenticate your requests to get higher rate limits:

```swift
// Authenticated requests get 60 requests/minute
let discogsService = DiscogsService(apiToken: "your-api-token")

// Unauthenticated requests only get 25 requests/minute
let discogsService = DiscogsService()
```

### 2. Implement Caching

Reduce API calls by caching responses:

```swift
class CachedDiscogsService {
    private let discogsService: DiscogsService
    private let cache = NSCache<NSString, AnyObject>()
    private let cacheExpiry: TimeInterval = 300 // 5 minutes
    
    init(discogsService: DiscogsService) {
        self.discogsService = discogsService
        cache.countLimit = 1000
    }
    
    func getArtist(id: Int) async throws -> Artist {
        let cacheKey = "artist-\(id)" as NSString
        
        if let cached = cache.object(forKey: cacheKey) as? CachedItem<Artist>,
           !cached.isExpired {
            return cached.item
        }
        
        let artist = try await discogsService.getArtist(id: id)
        let cachedItem = CachedItem(item: artist, expiry: Date().addingTimeInterval(cacheExpiry))
        cache.setObject(cachedItem, forKey: cacheKey)
        
        return artist
    }
}

private class CachedItem<T>: NSObject {
    let item: T
    let expiry: Date
    
    init(item: T, expiry: Date) {
        self.item = item
        self.expiry = expiry
    }
    
    var isExpired: Bool {
        return Date() > expiry
    }
}
```

### 3. Monitor Rate Limit Usage

Track your rate limit consumption:

```swift
class RateLimitMonitor {
    private var requestCount = 0
    private var windowStart = Date()
    private let windowDuration: TimeInterval = 60.0
    
    func recordRequest() {
        let now = Date()
        if now.timeIntervalSince(windowStart) >= windowDuration {
            // Reset window
            requestCount = 0
            windowStart = now
        }
        
        requestCount += 1
        print("Rate limit usage: \(requestCount)/60 requests in current minute")
        
        if requestCount >= 55 { // Warn at 90% usage
            print("⚠️ Approaching rate limit. Consider slowing down requests.")
        }
    }
    
    var remainingRequests: Int {
        let now = Date()
        if now.timeIntervalSince(windowStart) >= windowDuration {
            return 60 // Fresh window
        }
        return max(0, 60 - requestCount)
    }
}
```

### 4. Graceful Degradation

Handle rate limits gracefully in your UI:

```swift
class DiscogsRepository: ObservableObject {
    @Published var isRateLimited = false
    @Published var rateLimitRetryAfter: TimeInterval?
    
    private let discogsService: DiscogsService
    
    func fetchArtist(id: Int) async -> Artist? {
        do {
            let artist = try await discogsService.getArtist(id: id)
            isRateLimited = false
            return artist
        } catch DiscogsError.rateLimited(let retryAfter) {
            isRateLimited = true
            rateLimitRetryAfter = retryAfter
            
            // Schedule automatic retry
            if let retryAfter = retryAfter {
                DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter) {
                    Task {
                        await self.fetchArtist(id: id)
                    }
                }
            }
            
            return nil
        } catch {
            print("Error fetching artist: \(error)")
            return nil
        }
    }
}
```

## Testing Rate Limiting

### Mock Rate Limiting

```swift
class MockRateLimitedService: DiscogsServiceProtocol {
    var requestCount = 0
    var rateLimitThreshold = 5
    var shouldSimulateRateLimit = false
    
    func getArtist(id: Int) async throws -> Artist {
        requestCount += 1
        
        if shouldSimulateRateLimit && requestCount > rateLimitThreshold {
            throw DiscogsError.rateLimited(retryAfter: 60.0)
        }
        
        return Artist(id: id, name: "Test Artist")
    }
}

class RateLimitTests: XCTestCase {
    func testRateLimitHandling() async throws {
        let mockService = MockRateLimitedService()
        mockService.shouldSimulateRateLimit = true
        mockService.rateLimitThreshold = 3
        
        // First few requests should succeed
        _ = try await mockService.getArtist(id: 1)
        _ = try await mockService.getArtist(id: 2)
        _ = try await mockService.getArtist(id: 3)
        
        // Next request should trigger rate limit
        do {
            _ = try await mockService.getArtist(id: 4)
            XCTFail("Expected rate limit error")
        } catch DiscogsError.rateLimited(let retryAfter) {
            XCTAssertEqual(retryAfter, 60.0)
        }
    }
}
```

### Load Testing

```swift
func performanceTestRateLimit() async throws {
    let service = DiscogsService(apiToken: "test-token")
    let startTime = Date()
    var successCount = 0
    var rateLimitCount = 0
    
    // Send 100 requests as fast as possible
    await withTaskGroup(of: Void.self) { group in
        for i in 1...100 {
            group.addTask {
                do {
                    _ = try await service.getArtist(id: i)
                    successCount += 1
                } catch DiscogsError.rateLimited {
                    rateLimitCount += 1
                } catch {
                    print("Other error: \(error)")
                }
            }
        }
    }
    
    let duration = Date().timeIntervalSince(startTime)
    print("Completed in \(duration) seconds")
    print("Successful requests: \(successCount)")
    print("Rate limited requests: \(rateLimitCount)")
}
```

## Advanced Techniques

### Priority Queue for Requests

```swift
enum RequestPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    
    static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class PriorityRateLimiter {
    private struct PrioritizedRequest {
        let priority: RequestPriority
        let request: () async throws -> Void
        let timestamp: Date
    }
    
    private var requestQueue: [PrioritizedRequest] = []
    private let rateLimiter: RateLimiter
    
    init(rateLimiter: RateLimiter) {
        self.rateLimiter = rateLimiter
        startProcessing()
    }
    
    func enqueue<T>(
        priority: RequestPriority = .normal,
        request: @escaping () async throws -> T
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let prioritizedRequest = PrioritizedRequest(
                priority: priority,
                request: {
                    do {
                        let result = try await request()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                },
                timestamp: Date()
            )
            
            requestQueue.append(prioritizedRequest)
            requestQueue.sort { $0.priority > $1.priority }
        }
    }
    
    private func startProcessing() {
        Task {
            while true {
                if let nextRequest = requestQueue.first {
                    requestQueue.removeFirst()
                    try await rateLimiter.executeRequest {
                        try await nextRequest.request()
                    }
                } else {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
            }
        }
    }
}
```

## Related Topics

- <doc:ErrorHandling>
- <doc:Authentication>
- <doc:BestPractices>
- <doc:Testing>
