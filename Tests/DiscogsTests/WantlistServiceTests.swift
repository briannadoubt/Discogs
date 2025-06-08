import Foundation
import Testing
@testable import Discogs

@Suite("Wantlist Service Tests")
struct WantlistServiceTests {
    
    // Helper function to create a decoder with the same settings as the real implementation
    private    func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Don't apply convertFromSnakeCase since models have explicit CodingKeys mappings
        return decoder
    }
    
    @Test("WantlistService initializes with httpClient")
    func testInitialization() {
        // Given
        let mockClient = MockHTTPClient()
        
        // When
        let _ = WantlistService(httpClient: mockClient)
        
        // Then
        #expect(true)
    }
    
    @Test("WantlistService initializes with client for backward compatibility")
    func testLegacyInitialization() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When
        let _ = WantlistService(client: discogs)
        
        // Then
        #expect(true)
    }
    
    @Test("WantlistService conforms to Sendable")
    func testSendableConformance() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        let service = WantlistService(client: discogs)
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = service
        }
    }
    
    @Test("Get user wantlist")
    func testGetWantlist() async throws {
        // Given
        let mockHTTPClient = MockHTTPClient()
        let service = WantlistService(httpClient: mockHTTPClient)
        let username = "testuser"
        let page = 1
        let perPage = 50
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 150,
                "pages": 3
            },
            "wants": [
                {
                    "id": 12345,
                    "resource_url": "https://api.discogs.com/users/testuser/wants/12345",
                    "date_added": "2023-01-15T10:30:00-08:00",
                    "notes": "Looking for original pressing",
                    "rating": 0,
                    "basic_information": {
                        "id": 12345,
                        "title": "Wanted Album",
                        "year": 1990,
                        "resource_url": "https://api.discogs.com/releases/12345",
                        "artists": [
                            {
                                "name": "Test Artist",
                                "anv": "",
                                "join": "",
                                "role": "",
                                "tracks": "",
                                "id": 567,
                                "resource_url": "https://api.discogs.com/artists/567"
                            }
                        ],
                        "formats": [
                            {
                                "name": "Vinyl",
                                "qty": "1",
                                "descriptions": ["LP", "Album"]
                            }
                        ]
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockHTTPClient.setMockResponseData(mockResponse)

        // When
        let _ = try await service.getWantlist(username: username, page: page, perPage: perPage)

        // Then
        let request = try #require(await mockHTTPClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("users/\(username)/wants"))
        #expect(urlString.contains("page=\(page)"))
        #expect(urlString.contains("per_page=\(perPage)"))
        #expect(request.method == "GET")
    }
    
    @Test("Add release to wantlist")
    func testAddReleaseToWantlist() async throws {
        // Given
        let mockHTTPClient = MockHTTPClient()
        let service = WantlistService(httpClient: mockHTTPClient)
        let username = "testuser"
        let releaseId = 12345
        let notes = "Must have this album!"
        let rating = 5
        
        let mockResponse = """
        {
            "id": 12345,
            "resource_url": "https://api.discogs.com/users/testuser/wants/12345",
            "date_added": "2023-01-15T10:30:00-08:00",
            "notes": "Must have this album!",
            "rating": 5,
            "basic_information": {
                "id": 12345,
                "title": "Added Album",
                "year": 2023,
                "resource_url": "https://api.discogs.com/releases/12345"
            }
        }
        """.data(using: .utf8)!
        
        await mockHTTPClient.setMockResponseData(mockResponse)

        // When
        let _ = try await service.addToWantlist(
            username: username,
            releaseId: releaseId,
            notes: notes,
            rating: rating
        )
        
        // Then
        let request = try #require(await mockHTTPClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/wants/\(releaseId)"))
        #expect(request.method == "PUT")

        // Verify request body contains notes and rating
        if let body = request.body, let notesData = body["notes"] as? String, let ratingData = body["rating"] as? Int {
            #expect(notesData == notes)
            #expect(ratingData == rating)
        } else {
            #expect(Bool(false), "Request body does not contain notes and rating or they are not the correct type")
        }
    }

    @Test("Update wantlist item")
    func testUpdateWantlistItem() async throws {
        // Given
        let mockHTTPClient = MockHTTPClient()
        let service = WantlistService(httpClient: mockHTTPClient)
        let username = "testuser"
        let releaseId = 12345
        let notes = "Updated notes"
        let rating = 4
        
        let mockResponse = """
        {
            "id": 12345,
            "resource_url": "https://api.discogs.com/users/testuser/wants/12345",
            "notes": "Updated notes",
            "rating": 4,
            "basic_information": {
                "id": 12345,
                "title": "Updated Album",
                "year": 2023
            }
        }
        """.data(using: .utf8)!
        
        await mockHTTPClient.setMockResponseData(mockResponse)

        // When
        let _ = try await service.updateWantlistItem(
            username: username,
            releaseId: releaseId,
            notes: notes,
            rating: rating
        )
        
        // Then
        let request = try #require(await mockHTTPClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/wants/\(releaseId)"))
        #expect(request.method == "POST")

        // Verify request body contains updated notes and rating
        if let body = request.body, let notesData = body["notes"] as? String, let ratingData = body["rating"] as? Int {
            #expect(notesData == notes)
            #expect(ratingData == rating)
        } else {
            #expect(Bool(false), "Request body does not contain notes and rating or they are not the correct type")
        }
    }

    @Test("Remove release from wantlist")
    func testRemoveReleaseFromWantlist() async throws {
        // Given
        let mockHTTPClient = MockHTTPClient()
        let service = WantlistService(httpClient: mockHTTPClient)
        let username = "testuser"
        let releaseId = 12345

        await mockHTTPClient.setMockResponseData(Data()) // Empty response for DELETE

        // When
        let _ = try await service.removeFromWantlist(username: username, releaseId: releaseId)

        // Then
        let request = try #require(await mockHTTPClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/wants/\(releaseId)"))
        #expect(request.method == "DELETE")
    }

    @Test("Get wantlist with different sort criteria")
    func testGetWantlistSorted() async throws {
        // Given
        let mockHTTPClient = MockHTTPClient()
        let service = WantlistService(httpClient: mockHTTPClient)
        let username = "testuser"
        let page = 2
        let perPage = 25
        
        let mockResponse = """
        {
            "pagination": {
                "page": 2,
                "per_page": 25,
                "items": 150,
                "pages": 6
            },
            "wants": [
                {
                    "id": 22222,
                    "resource_url": "https://api.discogs.com/users/testuser/wants/22222",
                    "date_added": "2023-01-15T10:30:00-08:00",
                    "notes": "Sorted by artist",
                    "rating": 3,
                    "basic_information": {
                        "id": 22222,
                        "title": "Album A",
                        "year": 1980,
                        "resource_url": "https://api.discogs.com/releases/22222",
                        "artists": [
                            {
                                "name": "Artist A",
                                "id": 1001,
                                "resource_url": "https://api.discogs.com/artists/1001"
                            }
                        ],
                        "formats": []
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockHTTPClient.setMockResponseData(mockResponse)

        // When
        let _ = try await service.getWantlist(
            username: username,
            page: page,
            perPage: perPage,
            sort: .artist,
            sortOrder: .ascending
        )
        
        // Then
        let request = try #require(await mockHTTPClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("users/\(username)/wants"))
        #expect(urlString.contains("page=\(page)"))
        #expect(urlString.contains("per_page=\(perPage)"))
        #expect(urlString.contains("sort=artist"))
        #expect(urlString.contains("sort_order=asc"))
        #expect(request.method == "GET")
    }
    
    @Test("Wantlist service error handling")
    func testWantlistServiceErrorHandling() async throws {
        // Given
        let mockHTTPClient = MockHTTPClient()
        let service = WantlistService(httpClient: mockHTTPClient)
        let invalidUsername = "nonexistentuser"

        // Simulate 404 error
        let expectedError = DiscogsError.httpError(404)
        await mockHTTPClient.setErrorToThrow(expectedError)
        await mockHTTPClient.setShouldThrowError(true)

        // When/Then
        do {
            let _ = try await service.getWantlist(username: invalidUsername)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch let error as DiscogsError {
            #expect(error == DiscogsError.httpError(404))
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }

        let request = try #require(await mockHTTPClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(invalidUsername)/wants"))
    }
}
