import Testing
import Foundation
@testable import Discogs

@Suite("Database Service Functional Tests")
struct DatabaseServiceFunctionalTests {
    
    @Test("getArtist endpoint validation")
    func testGetArtistEndpoint() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
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
        let artist = try await service.getArtist(id: 123)
        
        // Then
        #expect(artist.id == 123)
        #expect(artist.name == "Test Artist")
        #expect(artist.realName == "Real Artist Name")
        #expect(artist.profile == "Artist biography")
        #expect(artist.dataQuality == "Correct")
        
        // Verify request was made correctly
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("artists/123"))
        #expect(request.method == "GET")
    }
    
    @Test("getArtistReleases with pagination")
    func testGetArtistReleasesWithPagination() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
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
        let response = try await service.getArtistReleases(
            artistId: 123,
            page: 2,
            perPage: 10,
            sort: .year,
            sortOrder: .descending
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
        
        // Verify request was made correctly
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("artists/123/releases"))
        #expect(request.url.query?.contains("page=2") == true)
        #expect(request.url.query?.contains("per_page=10") == true)
    }
    
    @Test("getRelease with currency parameter")
    func testGetReleaseWithCurrency() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
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
        let release = try await service.getRelease(id: 789, currency: "USD")
        
        // Then
        #expect(release.id == 789)
        #expect(release.title == "Test Release Details")
        #expect(release.year == 2022)
        #expect(release.country == "US")
        #expect(release.genres?.contains("Electronic") == true)
        #expect(release.styles?.contains("Techno") == true)
        
        // Verify request parameters
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("releases/789"))
        #expect(request.url.query?.contains("curr_abbr=USD") == true)
    }
    
    @Test("getMasterRelease endpoint validation")
    func testGetMasterRelease() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
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
        let master = try await service.getMasterRelease(id: 999)
        
        // Then
        #expect(master.id == 999)
        #expect(master.title == "Master Release Title")
        #expect(master.year == 2020)
        #expect(master.mainRelease == 1001)
        #expect(master.versionsCount == 15)
        
        // Verify URL structure
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("masters/999"))
    }
    
    @Test("getLabel endpoint validation")
    func testGetLabel() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
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
        let label = try await service.getLabel(id: 555)
        
        // Then
        #expect(label.id == 555)
        #expect(label.name == "Test Label")
        #expect(label.profile == "Independent record label")
        #expect(label.contactInfo == "contact@testlabel.com")
        #expect(label.dataQuality == "Correct")
        
        // Verify request was made correctly
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("labels/555"))
    }
    
    @Test("Release rating endpoints")
    func testReleaseRatingOperations() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        
        // Test PUT rating
        let ratingResponse = """
        {
            "rating": 5,
            "username": "testuser",
            "release_id": 123
        }
        """
        await mockClient.setMockResponse(json: ratingResponse)
        
        let rating = try await service.updateReleaseRating(releaseId: 123, username: "testuser", rating: 5)
        
        #expect(rating.rating == 5)
        #expect(rating.username == "testuser")
        
        // Test DELETE rating
        let deleteResponse = """
        {
            "message": "Rating deleted successfully"
        }
        """
        await mockClient.setMockResponse(json: deleteResponse)
        
        let success = try await service.deleteReleaseRating(releaseId: 123, username: "testuser")
        
        #expect(success.message == "Rating deleted successfully")
        
        // Test GET community rating
        let communityRatingResponse = """
        {
            "rating": {
                "count": 100,
                "average": 4.2
            }
        }
        """
        await mockClient.setMockResponse(json: communityRatingResponse)
        
        let communityRating = try await service.getCommunityReleaseRating(releaseId: 123)
        
        #expect(communityRating.rating.count == 100)
        #expect(communityRating.rating.average == 4.2)
    }
    
    @Test("Database service error handling")
    func testDatabaseServiceErrorHandling() async {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        struct APIError: Error {
            let message: String
        }
        await mockClient.setErrorToThrow(APIError(message: "Artist not found"))
        
        // When/Then
        do {
            let _ = try await service.getArtist(id: 999999)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as APIError {
            #expect(error.message == "Artist not found")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Get release details")
    func testGetReleaseDetails() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        let mockResponse = """
        {
            "id": 123,
            "title": "Test Release",
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
        await mockClient.setMockResponse(json: mockResponse)
        
        // When
        let _ = try await service.getRelease(id: 123)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("releases/123"))
        #expect(request.method == "GET")
    }
    
    @Test("Get release with currency")
    func testGetReleaseWithCurrencyParameter() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        let mockResponse = """
        {
            "id": 123,
            "title": "Test Release",
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
        await mockClient.setMockResponse(json: mockResponse)
        
        // When
        let _ = try await service.getRelease(id: 123, currency: "USD")
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        #expect(urlString.contains("releases/123"))
        #expect(urlString.contains("curr_abbr=USD"))
        #expect(request.method == "GET")
    }
    
    @Test("Get master release details")
    func testGetMasterReleaseDetails() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        let mockResponse = """
        {
            "id": 456,
            "title": "Master Release Title",
            "year": 2020,
            "mainRelease": 1001,
            "mainReleaseUrl": "https://api.discogs.com/releases/1001",
            "versionsCount": 15,
            "versionsUrl": "https://api.discogs.com/masters/456/versions",
            "artists": [{"id": 123, "name": "Test Artist"}],
            "genres": ["Rock"],
            "styles": ["Alternative"],
            "dataQuality": "Correct"
        }
        """
        await mockClient.setMockResponse(json: mockResponse)
        
        // When
        let _ = try await service.getMasterRelease(id: 456)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("masters/456"))
        #expect(request.method == "GET")
    }
    
    @Test("Get master release versions")
    func testGetMasterReleaseVersions() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "pages": 3,
                "per_page": 50,
                "items": 125
            },
            "versions": [
                {
                    "id": 1001,
                    "catno": "TEST-001",
                    "country": "US",
                    "year": 2020,
                    "title": "Master Release - US Edition",
                    "format": "Vinyl",
                    "label": "Test Label"
                },
                {
                    "id": 1002,
                    "catno": "TEST-002",
                    "country": "UK",
                    "year": 2021,
                    "title": "Master Release - UK Edition",
                    "format": "CD",
                    "label": "Test Label UK"
                }
            ]
        }
        """
        await mockClient.setMockResponse(json: mockResponse)
        
        // When
        let _ = try await service.getMasterReleaseVersions(masterId: 456, page: 1, perPage: 20)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        #expect(urlString.contains("masters/456/versions"))
        #expect(urlString.contains("page=1"))
        #expect(urlString.contains("per_page=20"))
        #expect(request.method == "GET")
    }
    
    @Test("Label releases endpoint")
    func testGetLabelReleases() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        let releasesJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 10,
                "per_page": 50,
                "items": 500
            },
            "releases": [
                {
                    "id": 2001,
                    "title": "Label Release 1",
                    "year": 2022,
                    "artist": "Various Artists",
                    "format": "Compilation",
                    "catno": "LABEL-001"
                }
            ]
        }
        """
        await mockClient.setMockResponse(json: releasesJson)
        
        // When
        let response = try await service.getLabelReleases(
            labelId: 555,
            page: 1,
            perPage: 50
        )
        
        // Then
        #expect(response.pagination.page == 1)
        #expect(response.pagination.pages == 10)
        #expect(response.items.count == 1)
        #expect(response.items[0].id == 2001)
        #expect(response.items[0].title == "Label Release 1")
        #expect(response.items[0].year == 2022)
        
        // Verify URL structure
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("labels/555/releases"))
    }
}
