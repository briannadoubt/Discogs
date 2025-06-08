# Error Handling

Learn how to handle errors effectively when using the Discogs Swift SDK.

## Overview

The Discogs Swift SDK provides comprehensive error handling to help you build robust applications. Understanding how to handle different types of errors will ensure your app gracefully manages API failures, network issues, and data validation problems.

## Error Types

The SDK defines several error types to help you identify and handle specific failure scenarios.

### DiscogsError

The primary error type that encapsulates all SDK-specific errors:

```swift
public enum DiscogsError: Error, Equatable {
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case rateLimited(retryAfter: TimeInterval?)
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case invalidURL
    case missingAPIToken
    case validationError(String)
}
```

### Network Errors

Handle network connectivity and request failures:

```swift
do {
    let release = try await discogsService.getRelease(id: 1234567)
    // Process release data
} catch DiscogsError.networkError(let underlyingError) {
    print("Network error occurred: \(underlyingError.localizedDescription)")
    // Implement retry logic or show connectivity message
} catch DiscogsError.invalidURL {
    print("Invalid URL constructed")
    // Log the error and check request parameters
}
```

### API Response Errors

Handle API-specific error responses:

```swift
do {
    let artist = try await discogsService.getArtist(id: artistId)
    // Process artist data
} catch DiscogsError.unauthorized {
    print("API token is invalid or missing")
    // Redirect to authentication flow
} catch DiscogsError.forbidden {
    print("Access to this resource is forbidden")
    // Check user permissions or resource availability
} catch DiscogsError.notFound {
    print("Artist not found")
    // Show user-friendly "not found" message
} catch DiscogsError.serverError(let statusCode) {
    print("Server error with status code: \(statusCode)")
    // Implement exponential backoff retry
}
```

### Rate Limiting

Handle rate limiting gracefully:

```swift
do {
    let searchResults = try await discogsService.search(query: "The Beatles")
    // Process results
} catch DiscogsError.rateLimited(let retryAfter) {
    if let retryAfter = retryAfter {
        print("Rate limited. Retry after \(retryAfter) seconds")
        // Wait for the specified time before retrying
        try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
        // Retry the request
    } else {
        print("Rate limited. Please wait before making more requests")
        // Implement default backoff strategy
    }
}
```

### Data Validation Errors

Handle data parsing and validation issues:

```swift
do {
    let release = try await discogsService.getRelease(id: releaseId)
    // Process release
} catch DiscogsError.decodingError(let decodingError) {
    print("Failed to decode response: \(decodingError)")
    // Log the error for debugging
    // Implement fallback data handling
} catch DiscogsError.validationError(let message) {
    print("Validation error: \(message)")
    // Show user-friendly validation message
}
```

## Best Practices

### 1. Comprehensive Error Handling

Always handle the full range of possible errors:

```swift
func fetchArtistSafely(id: Int) async -> Artist? {
    do {
        return try await discogsService.getArtist(id: id)
    } catch DiscogsError.unauthorized {
        // Handle authentication issues
        await reauthenticate()
        return nil
    } catch DiscogsError.rateLimited(let retryAfter) {
        // Handle rate limiting
        await handleRateLimit(retryAfter: retryAfter)
        return nil
    } catch DiscogsError.networkError {
        // Handle connectivity issues
        await showNetworkErrorMessage()
        return nil
    } catch DiscogsError.notFound {
        // Resource doesn't exist
        return nil
    } catch {
        // Handle unexpected errors
        logger.error("Unexpected error: \(error)")
        return nil
    }
}
```

### 2. Retry Logic with Exponential Backoff

Implement smart retry strategies for transient errors:

```swift
func fetchWithRetry<T>(
    operation: @escaping () async throws -> T,
    maxRetries: Int = 3,
    baseDelay: TimeInterval = 1.0
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch DiscogsError.rateLimited(let retryAfter) {
            // Respect the server's retry-after header
            let delay = retryAfter ?? pow(2.0, Double(attempt)) * baseDelay
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            lastError = error
        } catch DiscogsError.networkError {
            // Retry network errors with exponential backoff
            if attempt < maxRetries - 1 {
                let delay = pow(2.0, Double(attempt)) * baseDelay
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                lastError = error
            } else {
                throw error
            }
        } catch {
            // Don't retry non-transient errors
            throw error
        }
    }
    
    throw lastError ?? DiscogsError.networkError(NSError(domain: "RetryFailed", code: -1))
}
```

### 3. User-Friendly Error Messages

Convert technical errors into user-friendly messages:

```swift
extension DiscogsError {
    var userFriendlyMessage: String {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .unauthorized:
            return "Please sign in to access this feature."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "The requested item could not be found."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError:
            return "Server is temporarily unavailable. Please try again later."
        case .invalidResponse, .decodingError:
            return "Unable to process the response. Please try again."
        case .validationError(let message):
            return message
        case .invalidURL, .missingAPIToken:
            return "Configuration error. Please contact support."
        }
    }
}
```

### 4. Logging and Monitoring

Implement comprehensive error logging:

```swift
import OSLog

class ErrorHandler {
    private let logger = Logger(subsystem: "com.yourapp.discogs", category: "errors")
    
    func handle(_ error: Error, context: String) {
        switch error {
        case let discogsError as DiscogsError:
            logger.error("Discogs error in \(context): \(discogsError)")
            
            // Send to analytics/crash reporting
            Analytics.record(error: discogsError, context: context)
            
        default:
            logger.error("Unexpected error in \(context): \(error)")
            Analytics.record(error: error, context: context)
        }
    }
}
```

## Error Recovery Strategies

### Graceful Degradation

Implement fallback mechanisms when primary data sources fail:

```swift
func getArtistWithFallback(id: Int) async -> ArtistDisplayModel {
    do {
        let artist = try await discogsService.getArtist(id: id)
        return ArtistDisplayModel(from: artist)
    } catch {
        errorHandler.handle(error, context: "getArtist")
        
        // Try to load from cache
        if let cachedArtist = cache.artist(for: id) {
            return ArtistDisplayModel(from: cachedArtist, isFromCache: true)
        }
        
        // Return minimal model with error state
        return ArtistDisplayModel.unavailable(id: id)
    }
}
```

### Circuit Breaker Pattern

Prevent cascading failures by temporarily disabling failing services:

```swift
class CircuitBreaker {
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let threshold = 5
    private let timeout: TimeInterval = 60
    
    enum State {
        case closed, open, halfOpen
    }
    
    private var state: State = .closed
    
    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .open:
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > timeout {
                state = .halfOpen
            } else {
                throw DiscogsError.serverError(statusCode: 503)
            }
        case .halfOpen, .closed:
            break
        }
        
        do {
            let result = try await operation()
            if state == .halfOpen {
                reset()
            }
            return result
        } catch {
            recordFailure()
            throw error
        }
    }
    
    private func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
        
        if failureCount >= threshold {
            state = .open
        }
    }
    
    private func reset() {
        failureCount = 0
        lastFailureTime = nil
        state = .closed
    }
}
```

## Testing Error Scenarios

Create comprehensive tests for error handling:

```swift
class ErrorHandlingTests: XCTestCase {
    func testNetworkErrorHandling() async throws {
        // Mock network failure
        let mockService = MockDiscogsService()
        mockService.shouldFailWithNetworkError = true
        
        do {
            _ = try await mockService.getArtist(id: 1)
            XCTFail("Expected network error")
        } catch DiscogsError.networkError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRateLimitHandling() async throws {
        let mockService = MockDiscogsService()
        mockService.shouldFailWithRateLimit = true
        mockService.rateLimitRetryAfter = 30
        
        do {
            _ = try await mockService.search(query: "test")
            XCTFail("Expected rate limit error")
        } catch DiscogsError.rateLimited(let retryAfter) {
            XCTAssertEqual(retryAfter, 30)
        }
    }
}
```

## Related Topics

- <doc:RateLimiting>
- <doc:Authentication>
- <doc:BestPractices>
- <doc:Testing>
