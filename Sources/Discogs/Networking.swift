import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP methods supported by the Discogs API
/// 
/// Defines the standard HTTP methods that can be used when making requests
/// to the Discogs API endpoints.
public enum HTTPMethod: String, Sendable {
    /// GET method for retrieving data
    case get = "GET"
    
    /// POST method for creating new resources
    case post = "POST"
    
    /// PUT method for updating existing resources
    case put = "PUT"
    
    /// DELETE method for removing resources
    case delete = "DELETE"
    
    /// PATCH method for partially updating resources
    case patch = "PATCH"
}

/// Extension providing HTTP networking functionality for the Discogs client
extension Discogs {
    /// Perform an HTTP request with automatic retry and rate limiting
    /// 
    /// This is the main method for making HTTP requests to the Discogs API.
    /// It includes automatic retry logic for rate limiting and network errors.
    /// - Parameters:
    ///   - endpoint: The API endpoint path (relative to the base URL)
    ///   - method: The HTTP method to use (default: GET)
    ///   - parameters: Query parameters to include in the request (default: empty)
    ///   - body: Request body data for POST/PUT/PATCH requests (default: nil)
    ///   - headers: Additional HTTP headers to include (default: nil)
    /// - Returns: The decoded response of type T
    /// - Throws: `DiscogsError` if the request fails after all retries
    public func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: String] = [:],
        body: [String: any Sendable]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        return try await performRequestWithRetry(
            endpoint: endpoint,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers,
            attempt: 0
        )
    }
    
    private func performRequestWithRetry<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String],
        body: [String: any Sendable]?,
        headers: [String: String]?,
        attempt: Int
    ) async throws -> T {
        do {
            return try await performSingleRequest(
                endpoint: endpoint,
                method: method,
                parameters: parameters,
                body: body,
                headers: headers
            )
        } catch DiscogsError.rateLimitExceeded {
            // Check if we should retry
            guard rateLimitConfig.enableAutoRetry && attempt < rateLimitConfig.maxRetries else {
                throw DiscogsError.rateLimitExceeded
            }
            
            // Calculate delay for this attempt
            let delay = rateLimitConfig.calculateDelay(for: attempt, rateLimit: _rateLimit)
            
            // Wait before retrying
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Retry with incremented attempt counter
            return try await performRequestWithRetry(
                endpoint: endpoint,
                method: method,
                parameters: parameters,
                body: body,
                headers: headers,
                attempt: attempt + 1
            )
        } catch {
            // For non-rate-limit errors, don't retry
            throw error
        }
    }
    
    private func performSingleRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String],
        body: [String: any Sendable]?,
        headers: [String: String]?
    ) async throws -> T {
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true) else {
            throw DiscogsError.invalidURL
        }
        
        // Add query parameters
        if !parameters.isEmpty {
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw DiscogsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add required headers
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        // Add authentication
        try await addAuthentication(to: &request, method: method, url: url, parameters: parameters)
        
        // Add custom headers
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body if needed
        if let body = body, method != .get {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw DiscogsError.encodingError
            }
        }
        
        // Perform the data task
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw DiscogsError.networkError(error)
        }
        
        // Handle HTTPURLResponse with Linux Foundation compatibility
        #if canImport(FoundationNetworking)
        // On Linux, URLResponse might be returned as AnyObject, so we need explicit casting
        var httpResponse: HTTPURLResponse
        if let directResponse = response as? HTTPURLResponse {
            httpResponse = directResponse
        } else if let anyResponse = response as AnyObject as? HTTPURLResponse {
            httpResponse = anyResponse
        } else {
            throw DiscogsError.invalidResponse
        }
        
        // Extract values with explicit type conversion for Linux compatibility
        let statusCode = Int(httpResponse.statusCode)
        let headerFields = httpResponse.allHeaderFields
        
        // Convert headers to [AnyHashable: Any] ensuring compatibility
        var allHeaderFields: [AnyHashable: Any] = [:]
        for (key, value) in headerFields {
            allHeaderFields[key] = value
        }
        #else
        // macOS/iOS standard behavior
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DiscogsError.invalidResponse
        }
        
        let statusCode = httpResponse.statusCode
        let allHeaderFields = httpResponse.allHeaderFields
        #endif
        
        // Update rate limit information
        self._rateLimit = RateLimit(headers: allHeaderFields)
        
        // Handle rate limiting
        if statusCode == 429 {
            throw DiscogsError.rateLimitExceeded
        }
        
        // Handle other error status codes
        guard (200...299).contains(statusCode) else {
            throw DiscogsError.httpError(statusCode)
        }
        
        // Attempt to decode the response
        do {
            let decoder = JSONDecoder()
            // Don't apply convertFromSnakeCase since models have explicit CodingKeys mappings
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            throw DiscogsError.decodingError(error)
        }
    }
    
    private func addAuthentication(to request: inout URLRequest, method: HTTPMethod, url: URL, parameters: [String: String]) async throws {
        switch authMethod {
        case .token(let token):
            request.addValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
        case .oauth(let consumerKey, let consumerSecret, let accessToken, let accessTokenSecret):
            // Generate OAuth signature
            let auth = Authentication(client: self)
            let timestamp = String(auth.generateTimestamp())
            let nonce = auth.generateNonce()
            
            var oauthParams = [
                "oauth_consumer_key": consumerKey,
                "oauth_token": accessToken,
                "oauth_signature_method": "HMAC-SHA1",
                "oauth_timestamp": timestamp,
                "oauth_nonce": nonce,
                "oauth_version": "1.0"
            ]
            
            // Combine OAuth params with query parameters for signature
            var allParams = oauthParams
            for (key, value) in parameters {
                allParams[key] = value
            }
            
            let signature = auth.generateOAuthSignature(
                httpMethod: method.rawValue,
                baseURL: url.absoluteString.components(separatedBy: "?")[0], // Remove query string
                parameters: allParams,
                consumerSecret: consumerSecret,
                tokenSecret: accessTokenSecret
            )
            
            oauthParams["oauth_signature"] = signature
            
            // Create OAuth authorization header
            let authHeader = "OAuth " + oauthParams
                .sorted { $0.key < $1.key }
                .map { "\(auth.encodeURIComponent($0.key))=\"\(auth.encodeURIComponent($0.value))\"" }
                .joined(separator: ", ")
            
            request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        }
    }
}
