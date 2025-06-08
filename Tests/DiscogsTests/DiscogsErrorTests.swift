import Foundation
import Testing
@testable import Discogs

@Suite("Discogs Error Tests")
struct DiscogsErrorTests {
    
    @Test("DiscogsError cases are correctly defined")
    func testErrorCases() {
        // Test each error case can be created
        let invalidURL = DiscogsError.invalidURL
        let networkError = DiscogsError.networkError(URLError(.badURL))
        let invalidResponse = DiscogsError.invalidResponse
        let httpError = DiscogsError.httpError(404)
        let noData = DiscogsError.noData
        let decodingError = DiscogsError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test")))
        let encodingError = DiscogsError.encodingError
        let rateLimitExceeded = DiscogsError.rateLimitExceeded
        let authenticationError = DiscogsError.authenticationError
        
        // Verify they're all different error cases
        #expect(invalidURL != networkError)
        #expect(invalidResponse != httpError)
        #expect(noData != decodingError)
        #expect(encodingError != rateLimitExceeded)
        #expect(rateLimitExceeded != authenticationError)
        
        // Verify specific cases
        if case .invalidURL = invalidURL { } else { #expect(Bool(false)) }
        if case .networkError = networkError { } else { #expect(Bool(false)) }
        if case .invalidResponse = invalidResponse { } else { #expect(Bool(false)) }
        if case .httpError(let code) = httpError { #expect(code == 404) } else { #expect(Bool(false)) }
        if case .noData = noData { } else { #expect(Bool(false)) }
        if case .decodingError = decodingError { } else { #expect(Bool(false)) }
        if case .encodingError = encodingError { } else { #expect(Bool(false)) }
        if case .rateLimitExceeded = rateLimitExceeded { } else { #expect(Bool(false)) }
        if case .authenticationError = authenticationError { } else { #expect(Bool(false)) }
    }
    
    @Test("HTTP error stores status code correctly")
    func testHTTPError() {
        // Given
        let statusCode = 404
        
        // When
        let error = DiscogsError.httpError(statusCode)
        
        // Then
        switch error {
        case .httpError(let code):
            #expect(code == statusCode)
        default:
            Issue.record("Expected httpError case")
        }
    }
    
    @Test("Network error stores underlying error")
    func testNetworkError() {
        // Given
        let underlyingError = URLError(.badURL)
        
        // When
        let error = DiscogsError.networkError(underlyingError)
        
        // Then
        switch error {
        case .networkError(let err):
            #expect(err as? URLError == underlyingError)
        default:
            Issue.record("Expected networkError case")
        }
    }
    
    @Test("Decoding error stores underlying error")
    func testDecodingError() {
        // Given
        let underlyingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test"))
        
        // When
        let error = DiscogsError.decodingError(underlyingError)
        
        // Then
        switch error {
        case .decodingError(let err):
            #expect(err as? DecodingError != nil)
        default:
            Issue.record("Expected decodingError case")
        }
    }
    
    @Test("DiscogsError conforms to Sendable")
    func testSendableConformance() {
        // Given
        let error = DiscogsError.invalidURL
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = error
        }
    }
}
