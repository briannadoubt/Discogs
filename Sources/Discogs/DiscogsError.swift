import Foundation

/// Errors that can occur when using the Discogs API
/// 
/// This enum represents all the possible errors that can occur when making
/// requests to the Discogs API, including network issues, authentication
/// problems, and data parsing errors.
public enum DiscogsError: Error, Sendable {
    /// The requested URL was invalid or malformed
    case invalidURL
    
    /// A network error occurred during the request
    /// - Parameter Error: The underlying network error
    case networkError(Error)
    
    /// The server response was not in the expected format
    case invalidResponse
    
    /// The server returned an HTTP error status code
    /// - Parameters:
    ///   - Int: The HTTP status code returned by the server.
    ///   - String: The server's response body (decoded as UTF-8), if any.
    ///     Discogs frequently puts a JSON `message` field here explaining
    ///     what's wrong, which is the only way to distinguish, say, "instance
    ///     not found in that folder" from a generic internal error.
    case httpError(Int, String)
    
    /// No data was returned from the server when data was expected
    case noData
    
    /// Error occurred while decoding the response data
    /// - Parameter Error: The underlying decoding error
    case decodingError(Error)
    
    /// Error occurred while encoding the request data
    case encodingError
    
    /// API rate limit was exceeded, retry after some time
    case rateLimitExceeded
    
    /// Authentication failed or token is invalid
    case authenticationError
    
    /// Invalid input parameters were provided
    /// - Parameter String: Description of the invalid input
    case invalidInput(String)
    
    /// Custom error with a specific message
    /// - Parameter String: The error message
    case custom(String)
}

// MARK: - Equatable Conformance

extension DiscogsError: Equatable {
    public static func == (lhs: DiscogsError, rhs: DiscogsError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.noData, .noData),
             (.encodingError, .encodingError),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.authenticationError, .authenticationError):
            return true
        case (.httpError(let lhsCode, let lhsBody), .httpError(let rhsCode, let rhsBody)):
            return lhsCode == rhsCode && lhsBody == rhsBody
        case (.custom(let lhsMessage), .custom(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Helper Methods

extension DiscogsError {
    /// Create an invalid input error with a custom message
    /// - Parameter message: The error message describing the invalid input
    /// - Returns: A DiscogsError with the invalidInput case
    static func createInvalidInputError(_ message: String) -> DiscogsError {
        return .invalidInput(message)
    }
}