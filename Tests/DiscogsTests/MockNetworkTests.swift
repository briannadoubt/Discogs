import Testing
import Foundation
@testable import Discogs

// MARK: - Database Service Mock Tests

@Test
func testGetArtistWithMockResponse() async throws {
    // Given
    let mockClient = MockHTTPClient()
    let service = DatabaseService(httpClient: mockClient)
    let artistJson = """
    {
        "id": 123,
        "name": "Test Artist",
        "real_name": "Real Name",
        "profile": "Artist profile",
        "urls": ["https://example.com"],
        "data_quality": "Correct"
    }
    """
    await mockClient.setMockResponse(json: artistJson)
    
    // When
    let artist = try await service.getArtist(id: 123)
    
    // Then
    #expect(artist.id == 123)
    #expect(artist.name == "Test Artist")
    #expect(artist.realName == "Real Name")
    #expect(artist.profile == "Artist profile")
}

@Test
func testGetReleaseWithMockResponse() async throws {
    // Given
    let mockClient = MockHTTPClient()
    let service = DatabaseService(httpClient: mockClient)
    let releaseJson = """
    {
        "id": 456,
        "title": "Test Release",
        "artists": [
            {
                "id": 123,
                "name": "Test Artist"
            }
        ],
        "year": 2022,
        "country": "US",
        "formats": [{"name": "Vinyl"}],
        "genres": ["Electronic"],
        "styles": ["Techno"]
    }
    """
    await mockClient.setMockResponse(json: releaseJson)
    
    // When
    let release = try await service.getRelease(id: 456)
    
    // Then
    #expect(release.id == 456)
    #expect(release.title == "Test Release")
    #expect(release.year == 2022)
    #expect(release.country == "US")
}

// MARK: - Collection Service Mock Tests

@Test
func testGetCollectionFoldersWithMockResponse() async throws {
    // Given
    let mockClient = MockHTTPClient()
    let service = CollectionService(httpClient: mockClient)
    let foldersJson = """
    {
        "folders": [
            {
                "id": 0,
                "name": "All",
                "count": 100
            },
            {
                "id": 1,
                "name": "Uncategorized",
                "count": 50
            }
        ]
    }
    """
    await mockClient.setMockResponse(json: foldersJson)
    
    // When
    let foldersList = try await service.getFolders(username: "testuser")
    
    // Then
    #expect(foldersList.folders.count == 2)
    #expect(foldersList.folders[0].id == 0)
    #expect(foldersList.folders[0].name == "All")
    #expect(foldersList.folders[0].count == 100)
}

// MARK: - Search Service Mock Tests

@Test
func testSearchWithMockResponse() async throws {
    // Given
    let mockClient = MockHTTPClient()
    let service = SearchService(httpClient: mockClient)
    let searchJson = """
    {
        "pagination": {
            "page": 1,
            "pages": 10,
            "per_page": 50,
            "items": 486
        },
        "results": [
            {
                "id": 123,
                "title": "Test Result",
                "type": "release"
            }
        ]
    }
    """
    await mockClient.setMockResponse(json: searchJson)
    
    // When
    let searchResponse = try await service.search(query: "test", type: .release, page: 1, perPage: 50)
    
    // Then
    #expect(searchResponse.pagination.page == 1)
    #expect(searchResponse.pagination.pages == 10)
    #expect(searchResponse.items.count == 1)
    #expect(searchResponse.items[0].id == 123)
    #expect(searchResponse.items[0].title == "Test Result")
    #expect(searchResponse.items[0].type == "release")
}

// MARK: - Error Handling Tests

@Test
func testErrorHandlingWithMockResponse() async {
    // Given
    let mockClient = MockHTTPClient()
    let service = DatabaseService(httpClient: mockClient)
    struct TestError: Error { let message: String }
    let testError = TestError(message: "API request failed")
    await mockClient.setMockError(testError)
    
    // When/Then
    do {
        let _ = try await service.getArtist(id: 123)
        #expect(Bool(false), "Expected error to be thrown")
    } catch {
        if let error = error as? TestError {
            #expect(error.message == "API request failed")
        } else {
            #expect(Bool(false), "Unexpected error type")
        }
    }
}
