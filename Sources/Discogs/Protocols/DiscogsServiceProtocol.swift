import Foundation

/// Protocol defining the base interface for all Discogs services
public protocol DiscogsServiceProtocol: Sendable {
    /// The HTTP client used for making requests
    var httpClient: HTTPClientProtocol { get }
    
    /// Initialize with an HTTP client
    init(httpClient: HTTPClientProtocol)
}

/// Extension providing convenience methods for services
public extension DiscogsServiceProtocol {
    /// Perform a GET request
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        parameters: [String: String] = [:]
    ) async throws -> T {
        return try await httpClient.performRequest(
            endpoint: endpoint,
            method: .get,
            parameters: parameters,
            body: nil,
            headers: nil
        )
    }
    
    /// Perform a POST request
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        body: [String: any Sendable],
        parameters: [String: String] = [:]
    ) async throws -> T {
        return try await httpClient.performRequest(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            body: body,
            headers: nil
        )
    }
    
    /// Perform a request with custom method
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String] = [:],
        body: [String: any Sendable]? = nil
    ) async throws -> T {
        return try await httpClient.performRequest(
            endpoint: endpoint,
            method: method,
            parameters: parameters,
            body: body,
            headers: nil
        )
    }
}
