import Testing
import Foundation
@testable import Discogs

@Suite("Pagination Tests")
struct PaginationTests {
    
    // Helper function to create a decoder with the same settings as the real implementation
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Don't apply convertFromSnakeCase since models have explicit CodingKeys mappings
        return decoder
    }
    
    @Test("Pagination decodes correctly from JSON")
    func testPaginationDecoding() throws {
        // Given
        let json = """
        {
            "page": 1,
            "per_page": 50,
            "items": 200,
            "pages": 4,
            "urls": {
                "first": "https://api.discogs.com/database/search?page=1",
                "last": "https://api.discogs.com/database/search?page=4",
                "next": "https://api.discogs.com/database/search?page=2"
            }
        }
        """.data(using: .utf8)!
        
        // When
        let pagination = try createDecoder().decode(Pagination.self, from: json)
        
        // Then
        #expect(pagination.page == 1)
        #expect(pagination.perPage == 50)
        #expect(pagination.items == 200)
        #expect(pagination.pages == 4)
        #expect(pagination.urls?.first == "https://api.discogs.com/database/search?page=1")
        #expect(pagination.urls?.last == "https://api.discogs.com/database/search?page=4")
        #expect(pagination.urls?.next == "https://api.discogs.com/database/search?page=2")
        #expect(pagination.urls?.prev == nil)
    }
    
    @Test("Pagination decodes without URLs")
    func testPaginationWithoutURLs() throws {
        // Given
        let json = """
        {
            "page": 1,
            "per_page": 50,
            "items": 200,
            "pages": 4
        }
        """.data(using: .utf8)!
        
        // When
        let pagination = try createDecoder().decode(Pagination.self, from: json)
        
        // Then
        #expect(pagination.page == 1)
        #expect(pagination.perPage == 50)
        #expect(pagination.items == 200)
        #expect(pagination.pages == 4)
        #expect(pagination.urls == nil)
    }
    
    @Test("PaginationURLs decodes correctly")
    func testPaginationURLsDecoding() throws {
        // Given
        let json = """
        {
            "first": "https://api.discogs.com/database/search?page=1",
            "last": "https://api.discogs.com/database/search?page=10",
            "prev": "https://api.discogs.com/database/search?page=4",
            "next": "https://api.discogs.com/database/search?page=6"
        }
        """.data(using: .utf8)!
        
        // When
        let urls = try createDecoder().decode(PaginationURLs.self, from: json)
        
        // Then
        #expect(urls.first == "https://api.discogs.com/database/search?page=1")
        #expect(urls.last == "https://api.discogs.com/database/search?page=10")
        #expect(urls.prev == "https://api.discogs.com/database/search?page=4")
        #expect(urls.next == "https://api.discogs.com/database/search?page=6")
    }
    
    @Test("PaginationURLs handles missing URLs")
    func testPaginationURLsWithMissingValues() throws {
        // Given
        let json = """
        {
            "first": "https://api.discogs.com/database/search?page=1",
            "last": "https://api.discogs.com/database/search?page=10"
        }
        """.data(using: .utf8)!
        
        // When
        let urls = try createDecoder().decode(PaginationURLs.self, from: json)
        
        // Then
        #expect(urls.first == "https://api.discogs.com/database/search?page=1")
        #expect(urls.last == "https://api.discogs.com/database/search?page=10")
        #expect(urls.prev == nil)
        #expect(urls.next == nil)
    }
    
    @Test("Pagination and PaginationURLs conform to Sendable")
    func testSendableConformance() throws {
        // Given
        let json = """
        {
            "page": 1,
            "per_page": 50,
            "items": 200,
            "pages": 4,
            "urls": {
                "first": "https://api.discogs.com/database/search?page=1"
            }
        }
        """.data(using: .utf8)!
        
        let pagination = try createDecoder().decode(Pagination.self, from: json)
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = pagination
            let _ = pagination.urls
        }
    }
}
