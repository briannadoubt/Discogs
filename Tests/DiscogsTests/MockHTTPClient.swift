import Foundation
@testable import Discogs

// Define a local MockError to avoid dependency on DiscogsError definition during this refactoring
enum MockClientError: Error, Sendable {
    case mockNotConfigured(endpoint: String, method: String)
    case invalidURL(String)
    case forcedMockError
}

/// Mock HTTP client for testing that conforms to HTTPClientProtocol
actor MockHTTPClient: HTTPClientProtocol {
    // MARK: - Mock State (internal actor state)
    
    private var _mockResponseData: Data?
    private var _mockError: Error?
    // These remain actor-isolated and are updated by performRequest
    var lastRequestURL: URL?
    var lastRequestMethod: String?
    var lastRequestHeaders: [String: String]?
    var lastRequestBody: [String: any Sendable]?
    var requestHistory: [(url: URL, method: String, headers: [String: String], body: [String: any Sendable]?)] = []
    
    // Backing storage for properties that will have nonisolated setters
    private var _backing_shouldThrowError: Bool = false
    private var _backing_errorToThrow: Error?
    private var _backing_mockHeaders: [String: String] = [:]
    private var _backing_responseProvider: (@Sendable (String, HTTPMethod, [String: String], [String: any Sendable]?) -> Data?)?
    private var _backing_mockResponseData: Data? // Renamed to avoid conflict with computed property

    // MARK: - Mock Properties with nonisolated setters
    
    var mockResponse: Data? {
        get async { _backing_mockResponseData }
    }
    nonisolated func setMockResponse(_ data: Data?) {
        Task { await MainActor.run { /* if UI updates needed */ } } // Example if UI updates were tied
        // For actor state, direct mutation is fine if the setter itself doesn't need to be async
        // However, to modify actor state from a nonisolated context, we need an async task.
        // A simpler approach for tests might be to make these setters async methods.
        // Let's try async methods for clarity and safety with actor state.
        // Reverting to async methods for setting these, called from tests.
    }

    var shouldThrowError: Bool {
        get async { _backing_shouldThrowError }
    }

    var errorToThrow: Error? {
        get async { _backing_errorToThrow }
    }

    var mockHeaders: [String: String] {
        get async { _backing_mockHeaders }
    }

    var responseProvider: (@Sendable (String, HTTPMethod, [String: String], [String: any Sendable]?) -> Data?)? {
        get async { _backing_responseProvider }
    }
    
    // MARK: - Methods to mutate mock properties (called from async test contexts)

    func setShouldThrowError(_ shouldThrow: Bool) {
        self._backing_shouldThrowError = shouldThrow
    }

    func setErrorToThrow(_ error: Error?) {
        self._backing_errorToThrow = error
        if error != nil {
            self._backing_shouldThrowError = true
            self._backing_mockResponseData = nil
        } else {
            self._backing_shouldThrowError = false
        }
    }

    func setMockHeaders(_ headers: [String: String]) {
        self._backing_mockHeaders = headers
    }
    
    func setResponseProvider(_ provider: (@Sendable (String, HTTPMethod, [String: String], [String: any Sendable]?) -> Data?)?) {
        self._backing_responseProvider = provider
    }

    func setMockResponseData(_ data: Data?) async {
        self._backing_mockResponseData = data
        if data != nil {
            self._mockError = nil 
        }
    }
    
    var lastRequest: (url: URL, method: String, headers: [String: String], body: [String: any Sendable]?)? {
        get async { // This getter remains async as it accesses multiple actor-isolated properties
            guard let lastURL = self.lastRequestURL,
                  let lastMethod = self.lastRequestMethod,
                  let lastHeaders = self.lastRequestHeaders else {
                return nil
            }
            return (url: lastURL, method: lastMethod, headers: lastHeaders, body: self.lastRequestBody)
        }
    }
    
    // MARK: - Configuration Methods (ensure they correctly interact with actor state)
    
    // These methods are now nonisolated as they call the new async setters or directly modify backing stores
    // that have async getters. If they need to be called from synchronous test code,
    // the tests will need to be refactored or these will need to be async funcs.
    // For now, let's make them async to be safe and clear.

    func setMockResponse(json: String) async {
        await self.setMockResponseData(json.data(using: .utf8))
        self._backing_errorToThrow = nil 
        self._mockError = nil 
    }
    
    func setMockResponse(data: Data) async {
        await self.setMockResponseData(data)
        self._backing_errorToThrow = nil
        self._mockError = nil
    }
    
    func setMockError(_ error: Error) {
        self._mockError = error
        self._backing_mockResponseData = nil
    }
    
    func clearHistory() {
        requestHistory.removeAll()
        lastRequestURL = nil
        lastRequestMethod = nil
        lastRequestHeaders = nil
        lastRequestBody = nil
    }
    
    // MARK: - Additional Test Helper Methods
    // This method might need adjustment if it's called from non-async test contexts,
    // or tests using it should be async.
    func performMockRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: String] = [:],
        body: [String: any Sendable]? = nil
    ) async throws -> T {
        // This now calls the actor's performRequest, which is fine.
        return try await performRequest(endpoint: endpoint, method: method, parameters: parameters, body: body, headers: nil)
    }
    
    // MARK: - HTTPClientProtocol Implementation
    
    var rateLimit: RateLimit? {
        get async { nil }
    }

    nonisolated var baseURL: URL {
        URL(string: "https://api.discogs.com")!
    }

    nonisolated var userAgent: String {
        "MockDiscogsClient/1.0"
    }

    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String],
        body: [String: any Sendable]?,
        headers: [String: String]?
    ) async throws -> T {
        var components = URLComponents(string: baseURL.absoluteString)!
        components.path = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        
        if !parameters.isEmpty {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            // Simplified error throwing to avoid interpolation issues with the tool
            throw MockClientError.invalidURL("Invalid URL")
        }
        
        // Merge provided headers with mock headers
        var combinedHeaders = self._backing_mockHeaders
        if let headers = headers {
            combinedHeaders.merge(headers) { _, new in new }
        }
        
        self.lastRequestURL = url
        self.lastRequestMethod = method.rawValue
        self.lastRequestHeaders = combinedHeaders
        self.lastRequestBody = body
        
        self.requestHistory.append((url: url, method: method.rawValue, headers: combinedHeaders, body: body))
         if self._backing_shouldThrowError {
            if let error = self._backing_errorToThrow {
                // Wrap errors the same way the real Discogs class does
                if let urlError = error as? URLError {
                    throw DiscogsError.networkError(urlError)
                } else {
                    throw error
                }
            } else {
                throw MockClientError.forcedMockError
            }
        }
        
        if let error = self._mockError {
            // Wrap errors the same way the real Discogs class does
            if let urlError = error as? URLError {
                throw DiscogsError.networkError(urlError)
            } else {
                throw error
            }
        }
        
        let emptyJsonData = "{}".data(using: .utf8)!
        let successResponseData = "{\"message\": \"Success\"}".data(using: .utf8)!
        let decoder = JSONDecoder()
        // Don't apply convertFromSnakeCase since models have explicit CodingKeys mappings

        if let provider = self._backing_responseProvider {
            if let data = provider(endpoint, method, combinedHeaders, body) {
                if T.self == String.self {
                    return String(data: data, encoding: .utf8) as! T
                }
                if T.self == SuccessResponse.self && data.isEmpty {
                    do {
                        return try decoder.decode(T.self, from: successResponseData)
                    } catch {
                        throw DiscogsError.decodingError(error)
                    }
                }
                do {
                    return try decoder.decode(T.self, from: data.isEmpty && T.self != Data.self ? emptyJsonData : data)
                } catch {
                    throw DiscogsError.decodingError(error)
                }
            }
        }
        
        if let data = self._backing_mockResponseData {
            if T.self == String.self {
                return String(data: data, encoding: .utf8) as! T
            }
            if T.self == SuccessResponse.self && data.isEmpty {
                do {
                    return try decoder.decode(T.self, from: successResponseData)
                } catch {
                    throw DiscogsError.decodingError(error)
                }
            }
            
            // Use the mock data set by the tests directly
            do {
                let dataToUse = data.isEmpty && T.self != Data.self ? emptyJsonData : data
                return try decoder.decode(T.self, from: dataToUse)
            } catch {
                throw DiscogsError.decodingError(error)
            }
        }
        
        if T.self == SuccessResponse.self {
            do {
                return try decoder.decode(T.self, from: successResponseData)
            } catch {
                throw DiscogsError.decodingError(error)
            }
        }
        
        if T.self == String.self {
            return "" as! T // Return empty string if no mock data is set
        }
        
        throw MockClientError.mockNotConfigured(endpoint: endpoint, method: method.rawValue)
    }
}

// Assuming SuccessResponse is defined something like this in your main code:
// public struct SuccessResponse: Codable, Sendable {
//     public init() {} // Allows SuccessResponse()
// }

/// MockDiscogsClient provides URLRequest interface for backwards compatibility with tests
actor MockDiscogsClient: HTTPClientProtocol {
    private let mockHTTPClient = MockHTTPClient()
    
    var mockResponse: Data? {
        get async { await mockHTTPClient.mockResponse }
    }
    
    var shouldThrowError: Bool {
        get async { await mockHTTPClient.shouldThrowError }
    }
    
    var errorToThrow: Error? {
        get async { await mockHTTPClient.errorToThrow }
    }
    
    var mockHeaders: [String: String] {
        get async { await mockHTTPClient.mockHeaders }
    }
    
    var lastRequest: URLRequest? {
        get async {
            guard let request = await mockHTTPClient.lastRequest else { return nil }
            
            var urlRequest = URLRequest(url: request.url)
            urlRequest.httpMethod = request.method
            urlRequest.allHTTPHeaderFields = request.headers
            
            // Convert body to Data if needed
            if let body = request.body {
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
                } catch {
                    // If serialization fails, create empty data
                    urlRequest.httpBody = Data()
                }
            }
            
            return urlRequest
        }
    }
    
    // HTTPClientProtocol conformance
    var rateLimit: RateLimit? {
        get async { await mockHTTPClient.rateLimit }
    }
    
    nonisolated var baseURL: URL {
        mockHTTPClient.baseURL
    }
    
    nonisolated var userAgent: String {
        mockHTTPClient.userAgent
    }
    
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String],
        body: [String: any Sendable]?,
        headers: [String: String]?
    ) async throws -> T {
        return try await mockHTTPClient.performRequest(endpoint: endpoint, method: method, parameters: parameters, body: body, headers: headers)
    }
    
    // Convenience methods for test setup
    func setMockResponse(_ data: Data) async {
        await mockHTTPClient.setMockResponseData(data)
    }
    
    func setMockResponse(json: String) async {
        await mockHTTPClient.setMockResponse(json: json)
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) async {
        await mockHTTPClient.setShouldThrowError(shouldThrow)
    }
    
    func setErrorToThrow(_ error: Error) async {
        await mockHTTPClient.setErrorToThrow(error)
    }
    
    func clearHistory() async {
        await mockHTTPClient.clearHistory()
    }
    
    // Additional convenience methods needed by tests
    func performMockRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: String] = [:],
        body: [String: any Sendable]? = nil
    ) async throws -> T {
        return try await performRequest(endpoint: endpoint, method: method, parameters: parameters, body: body, headers: nil)
    }
    
    var lastRequestURL: URL? {
        get async { await mockHTTPClient.lastRequestURL }
    }
    
    func setMockError(_ error: Error) async {
        await setErrorToThrow(error)
    }
    
    func setMockHeaders(_ headers: [String: String]) async {
        await mockHTTPClient.setMockHeaders(headers)
    }
    
    func setResponseProvider(_ provider: @escaping @Sendable (String, HTTPMethod, [String: String], [String: any Sendable]?) -> Data?) async {
        await mockHTTPClient.setResponseProvider(provider)
    }
}
