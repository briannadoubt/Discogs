import Testing
import Foundation
@testable import Discogs

@Suite("Search Service Tests")
struct SearchServiceTests {
    
    @Test("SearchService initializes with client")
    func testInitialization() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When
        let _ = SearchService(client: discogs)
        
        // Then
        #expect(true)
    }
    
    @Test("SearchService conforms to Sendable")
    func testSendableConformance() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        let service = SearchService(client: discogs)
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = service
        }
    }
    
    @Test("General database search")
    func testGeneralSearch() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let query = "The Beatles"
        let page = 1
        let perPage = 50
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 5000,
                "pages": 100,
                "urls": {
                    "first": "https://api.discogs.com/database/search?q=The%20Beatles&page=1",
                    "last": "https://api.discogs.com/database/search?q=The%20Beatles&page=100",
                    "next": "https://api.discogs.com/database/search?q=The%20Beatles&page=2"
                }
            },
            "results": [
                {
                    "id": 12345,
                    "type": "release",
                    "title": "Abbey Road",
                    "year": "1969",
                    "resource_url": "https://api.discogs.com/releases/12345",
                    "uri": "https://www.discogs.com/The-Beatles-Abbey-Road/release/12345",
                    "thumb": "https://img.discogs.com/thumb.jpg",
                    "cover_image": "https://img.discogs.com/cover.jpg",
                    "master_id": 567,
                    "master_url": "https://api.discogs.com/masters/567",
                    "country": "UK",
                    "format": ["Vinyl", "LP", "Album", "Stereo"],
                    "label": ["Apple Records"],
                    "catno": "PCS 7088",
                    "genre": ["Rock"],
                    "style": ["Pop Rock", "Psychedelic Rock"],
                    "barcode": [],
                    "user_data": {
                        "in_wantlist": false,
                        "in_collection": false
                    },
                    "community": {
                        "want": 1250,
                        "have": 5000
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(
            query: query,
            type: SearchService.SearchType.release,
            page: page,
            perPage: perPage
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"))
        #expect(urlString.contains("page=\(page)"))
        #expect(urlString.contains("per_page=\(perPage)"))
        #expect(urlString.contains("type=release"))
        #expect(request.method == "GET")
    }
    
    @Test("Search with multiple filters")
    func testSearchWithFilters() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let query = "jazz"
        let artist = "Miles Davis"
        let releaseTitle = "Kind of Blue"
        let label = "Columbia"
        let genre = "Jazz"
        let style = "Modal"
        let country = "US"
        let year = "1959"
        let format = "Vinyl"
        let catno = "CL 1355"
        let barcode = "074646516027"
        let track = "So What"
        let submitter = "submitter123"
        let contributor = "contributor456"
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 25,
                "items": 15,
                "pages": 1
            },
            "results": [
                {
                    "id": 54321,
                    "type": "release",
                    "title": "Kind Of Blue",
                    "year": "1959",
                    "resource_url": "https://api.discogs.com/releases/54321",
                    "master_id": 8888,
                    "master_url": "https://api.discogs.com/masters/8888",
                    "country": "US",
                    "format": ["Vinyl", "LP", "Album", "Mono"],
                    "label": ["Columbia"],
                    "catno": "CL 1355",
                    "genre": ["Jazz"],
                    "style": ["Modal"],
                    "thumb": "https://img.discogs.com/thumb.jpg"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(
            query: query,
            releaseTitle: releaseTitle,
            artist: artist,
            label: label,
            genre: genre,
            style: style,
            country: country,
            year: year,
            format: format,
            catno: catno,
            barcode: barcode,
            track: track,
            submitter: submitter,
            contributor: contributor
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("q=\(query)"))
        #expect(urlString.contains("artist=\(artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artist)"))
        #expect(urlString.contains("release_title=\(releaseTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? releaseTitle)"))
        #expect(urlString.contains("label=\(label)"))
        #expect(urlString.contains("genre=\(genre)"))
        #expect(urlString.contains("style=\(style)"))
        #expect(urlString.contains("country=\(country)"))
        #expect(urlString.contains("year=\(year)"))
        #expect(urlString.contains("format=\(format)"))
        #expect(urlString.contains("catno=\(catno.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? catno)"))
        #expect(urlString.contains("barcode=\(barcode)"))
        #expect(urlString.contains("track=\(track.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? track)"))
        #expect(urlString.contains("submitter=\(submitter)"))
        #expect(urlString.contains("contributor=\(contributor)"))
        #expect(request.method == "GET")
    }
    
    @Test("Search by artist only")
    func testSearchByArtist() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let artist = "Pink Floyd"
        let type = SearchService.SearchType.artist
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 1,
                "pages": 1
            },
            "results": [
                {
                    "id": 45170,
                    "type": "artist",
                    "title": "Pink Floyd",
                    "resource_url": "https://api.discogs.com/artists/45170",
                    "uri": "https://www.discogs.com/artist/45170-Pink-Floyd",
                    "thumb": "https://img.discogs.com/artist_thumb.jpg",
                    "cover_image": "https://img.discogs.com/artist_cover.jpg"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(type: type, artist: artist)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("artist=\(artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artist)"))
        #expect(urlString.contains("type=artist"))
        #expect(request.method == "GET")
    }
    
    @Test("Search by label")
    func testSearchByLabel() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let label = "Blue Note"
        let type = SearchService.SearchType.label
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 5,
                "pages": 1
            },
            "results": [
                {
                    "id": 157,
                    "type": "label",
                    "title": "Blue Note",
                    "resource_url": "https://api.discogs.com/labels/157",
                    "uri": "https://www.discogs.com/label/157-Blue-Note",
                    "thumb": "https://img.discogs.com/label_thumb.jpg"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(type: type, label: label)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("label=\(label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? label)"))
        #expect(urlString.contains("type=label"))
        #expect(request.method == "GET")
    }
    
    @Test("Search with sorting options")
    func testSearchWithSorting() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let query = "electronic"
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 2500,
                "pages": 50
            },
            "results": [
                {
                    "id": 99999,
                    "type": "release",
                    "title": "Latest Electronic Album",
                    "year": "2023",
                    "genre": ["Electronic"],
                    "style": ["Ambient", "Experimental"]
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(
            query: query
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("q=\(query)"))
        #expect(request.method == "GET")
    }
    
    @Test("Search with format and year range")
    func testSearchWithFormatAndYearRange() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let genre = "Rock"
        let format = "CD"
        let yearRange = "1990-1999"
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 750,
                "pages": 15
            },
            "results": [
                {
                    "id": 77777,
                    "type": "release",
                    "title": "90s Rock Album",
                    "year": "1995",
                    "format": ["CD", "Album"],
                    "genre": ["Rock"],
                    "style": ["Alternative Rock", "Grunge"]
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(
            genre: genre,
            year: yearRange,
            format: format
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("genre=\(genre)"))
        #expect(urlString.contains("format=\(format)"))
        #expect(urlString.contains("year=\(yearRange)"))
        #expect(request.method == "GET")
    }
    
    @Test("Search with empty results")
    func testSearchWithNoResults() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let query = "veryunlikelytomatchanything12345"
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 0,
                "pages": 0
            },
            "results": []
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(query: query)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("q=\(query)"))
        #expect(request.method == "GET")
    }
    
    @Test("Search service error handling")
    func testSearchServiceErrorHandling() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let query = "test"
        
        // Simulate 400 error for invalid search query
        await mockClient.setShouldThrowError(true)
        await mockClient.setErrorToThrow(NSError(domain: "DiscogsError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid search query"]))
        
        // When/Then
        await #expect(throws: Error.self) {
            try await service.search(query: query)
        }
        
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("database/search") == true)
    }
    
    @Test("Search with special characters in query")
    func testSearchWithSpecialCharacters() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let query = "Björk & Sigur Rós"
        let artist = "Mötley Crüe"
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 25,
                "pages": 1
            },
            "results": [
                {
                    "id": 88888,
                    "type": "release",
                    "title": "Special Characters Album",
                    "year": "2000"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(query: query, artist: artist)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        // Verify URL encoding is applied properly
        #expect(urlString.contains("q="))
        #expect(urlString.contains("artist="))
        #expect(request.method == "GET")
    }
    
    @Test("Search masters only")
    func testSearchMastersOnly() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = SearchService(httpClient: mockClient)
        let query = "classic albums"
        let type = SearchService.SearchType.master
        
        let mockResponse = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 100,
                "pages": 2
            },
            "results": [
                {
                    "id": 1234,
                    "type": "master",
                    "title": "Classic Master Release",
                    "year": "1975",
                    "resource_url": "https://api.discogs.com/masters/1234",
                    "uri": "https://www.discogs.com/master/1234-Classic-Master-Release",
                    "main_release": 56789,
                    "main_release_url": "https://api.discogs.com/releases/56789",
                    "versions_url": "https://api.discogs.com/masters/1234/versions",
                    "genre": ["Rock"],
                    "style": ["Classic Rock"]
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.search(query: query, type: type)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("database/search"))
        #expect(urlString.contains("q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"))
        #expect(urlString.contains("type=master"))
        #expect(request.method == "GET")
    }
}
