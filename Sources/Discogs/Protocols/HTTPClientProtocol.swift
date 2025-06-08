import Foundation

/// Protocol defining the HTTP client interface for dependency injection
public protocol HTTPClientProtocol: Sendable {
    /// Perform an HTTP request and return decoded response
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - method: HTTP method to use
    ///   - parameters: Query parameters
    ///   - body: Request body (for POST/PUT/PATCH requests)
    ///   - headers: Additional HTTP headers
    /// - Returns: Decoded response of type T
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String],
        body: [String: any Sendable]?,
        headers: [String: String]?
    ) async throws -> T
    
    /// Get the current rate limit information
    var rateLimit: RateLimit? { get async }
    
    /// Base URL for the API
    var baseURL: URL { get }
    
    /// User-Agent string for requests
    var userAgent: String { get }
}

/// Default implementations for optional parameters
public extension HTTPClientProtocol {
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: String] = [:]
    ) async throws -> T {
        return try await performRequest(
            endpoint: endpoint,
            method: method,
            parameters: parameters,
            body: nil,
            headers: nil
        )
    }
}
