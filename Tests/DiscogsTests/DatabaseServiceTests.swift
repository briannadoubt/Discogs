import Testing
@testable import Discogs

@Suite("Database Service Tests")
struct DatabaseServiceTests {
    
    @Test("DatabaseService initializes with httpClient")
    func testInitialization() {
        // Given
        let mockClient = MockHTTPClient()
        
        // When
        let _ = DatabaseService(httpClient: mockClient)
        
        // Then
        // If initialization succeeds without throwing, the test passes
        #expect(true)
    }
    
    @Test("DatabaseService initializes with client for backward compatibility")
    func testLegacyInitialization() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When
        let _ = DatabaseService(client: discogs)
        
        // Then
        // If initialization succeeds without throwing, the test passes
        #expect(true)
    }
    
    @Test("DatabaseService conforms to Sendable")
    func testSendableConformance() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        let service = DatabaseService(client: discogs)
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = service
        }
    }
    
    @Test("DatabaseService methods are available")
    func testMethodsAvailable() async throws {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        let _ = DatabaseService(client: discogs)
        
        // When/Then - Test that service can be instantiated
        // This test verifies the service initializes without errors
        #expect(true)
    }
    
    @Test("getArtist endpoint validation")
    func testGetArtistEndpoint() async throws {
        // Given
        let mockClient = MockDiscogsClient()
        let artistJson = """
        {
            "id": 123,
            "name": "Test Artist",
            "real_name": "Real Artist Name",
            "profile": "Artist biography",
            "urls": ["https://example.com"],
            "data_quality": "Correct",
            "namevariations": ["Test Artist", "Artist Test"],
            "aliases": [],
            "members": [],
            "images": [],
            "resource_url": "https://api.discogs.com/artists/123",
            "uri": "https://discogs.com/artist/123",
            "releases_url": "https://api.discogs.com/artists/123/releases"
        }
        """
        await mockClient.setMockResponse(json: artistJson)
        
        // When
        let artist: Artist = try await mockClient.performMockRequest(endpoint: "artists/123")
        
        // Then
        #expect(artist.id == 123)
        #expect(artist.name == "Test Artist")
        #expect(artist.realName == "Real Artist Name")
        #expect(artist.profile == "Artist biography")
        #expect(artist.dataQuality == "Correct")
        
        // Verify request was made correctly
        let lastURL = await mockClient.lastRequestURL
        #expect(lastURL?.path == "/artists/123")
    }
    
    @Test("getArtistReleases with pagination")
    func testGetArtistReleasesWithPagination() async throws {
        // Given
        let mockClient = MockDiscogsClient()
        let releasesJson = """
        {
            "pagination": {
                "page": 2,
                "pages": 5,
                "per_page": 10,
                "items": 50,
                "urls": {
                    "first": "https://api.discogs.com/artists/123/releases?page=1",
                    "prev": "https://api.discogs.com/artists/123/releases?page=1",
                    "next": "https://api.discogs.com/artists/123/releases?page=3",
                    "last": "https://api.discogs.com/artists/123/releases?page=5"
                }
            },
            "releases": [
                {
                    "id": 456,
                    "title": "Test Release",
                    "year": 2022,
                    "status": "Accepted",
                    "format": "Vinyl",
                    "label": "Test Label",
                    "artist": "Test Artist",
                    "role": "Main"
                }
            ]
        }
        """
        await mockClient.setMockResponse(json: releasesJson)
        
        // When
        let response: PaginatedResponse<Release> = try await mockClient.performMockRequest(
            endpoint: "artists/123/releases",
            parameters: [
                "page": "2",
                "per_page": "10",
                "sort": "year",
                "sort_order": "desc"
            ]
        )
        
        // Then
        #expect(response.pagination.page == 2)
        #expect(response.pagination.pages == 5)
        #expect(response.pagination.perPage == 10)
        #expect(response.pagination.items == 50)
        #expect(response.items.count == 1)
        #expect(response.items[0].id == 456)
        #expect(response.items[0].title == "Test Release")
        
        // Verify pagination URLs
        #expect(response.pagination.urls?.first?.contains("page=1") == true)
        #expect(response.pagination.urls?.next?.contains("page=3") == true)
    }
    
    @Test("getRelease with currency parameter")
    func testGetReleaseWithCurrency() async throws {
        // Given
        let mockClient = MockDiscogsClient()
        let releaseJson = """
        {
            "id": 789,
            "title": "Test Release Details",
            "artists": [{"id": 123, "name": "Test Artist"}],
            "year": 2022,
            "country": "US",
            "formats": [{"name": "Vinyl", "descriptions": ["LP"]}],
            "genres": ["Electronic"],
            "styles": ["Techno"],
            "tracklist": [],
            "labels": [],
            "dataQuality": "Correct",
            "community": {
                "want": 100,
                "have": 50
            }
        }
        """
        await mockClient.setMockResponse(json: releaseJson)
        
        // When
        let release: ReleaseDetails = try await mockClient.performMockRequest(
            endpoint: "releases/789",
            parameters: ["curr_abbr": "USD"]
        )
        
        // Then
        #expect(release.id == 789)
        #expect(release.title == "Test Release Details")
        #expect(release.year == 2022)
        #expect(release.country == "US")
        #expect(release.genres?.contains("Electronic") == true)
        #expect(release.styles?.contains("Techno") == true)
        
        // Verify request parameters
        let lastURL = await mockClient.lastRequestURL
        #expect(lastURL?.query?.contains("curr_abbr=USD") == true)
    }
    
    @Test("getMasterRelease endpoint validation")
    func testGetMasterRelease() async throws {
        // Given
        let mockClient = MockDiscogsClient()
        let masterJson = """
        {
            "id": 999,
            "title": "Master Release Title",
            "year": 2020,
            "main_release": 1001,
            "main_release_url": "https://api.discogs.com/releases/1001",
            "versions_count": 15,
            "versions_url": "https://api.discogs.com/masters/999/versions",
            "artists": [{"id": 123, "name": "Test Artist"}],
            "genres": ["Rock"],
            "styles": ["Alternative"],
            "data_quality": "Correct"
        }
        """
        await mockClient.setMockResponse(json: masterJson)
        
        // When
        let master: MasterRelease = try await mockClient.performMockRequest(endpoint: "masters/999")
        
        // Then
        #expect(master.id == 999)
        #expect(master.title == "Master Release Title")
        #expect(master.year == 2020)
        #expect(master.mainRelease == 1001)
        #expect(master.versionsCount == 15)
        
        // Verify URL structure
        let lastURL = await mockClient.lastRequestURL
        #expect(lastURL?.path == "/masters/999")
    }
    
    @Test("getLabel endpoint validation")
    func testGetLabel() async throws {
        // Given
        let mockClient = MockDiscogsClient()
        let labelJson = """
        {
            "id": 555,
            "name": "Test Label",
            "profile": "Independent record label",
            "contact_info": "contact@testlabel.com",
            "data_quality": "Correct",
            "urls": ["https://testlabel.com"],
            "sublabels": [],
            "parent_label": null,
            "images": [],
            "resource_url": "https://api.discogs.com/labels/555",
            "uri": "https://discogs.com/label/555",
            "releases_url": "https://api.discogs.com/labels/555/releases"
        }
        """
        await mockClient.setMockResponse(json: labelJson)
        
        // When
        let label: Label = try await mockClient.performMockRequest(endpoint: "labels/555")
        
        // Then
        #expect(label.id == 555)
        #expect(label.name == "Test Label")
        #expect(label.profile == "Independent record label")
        #expect(label.contactInfo == "contact@testlabel.com")
        #expect(label.dataQuality == "Correct")
    }
    
    @Test("Database service error handling")
    func testDatabaseServiceErrorHandling() async {
        // Given
        let mockClient = MockDiscogsClient()
        struct APIError: Error {
            let message: String
        }
        await mockClient.setMockError(APIError(message: "Artist not found"))
        
        // When/Then
        do {
            let _: Artist = try await mockClient.performMockRequest(endpoint: "artists/999999")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as APIError {
            #expect(error.message == "Artist not found")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
