import Foundation
import Testing
@testable import Discogs

@Suite("Models Tests")
struct ModelsTests {
    
    // Helper function to create a decoder with the same settings as the real implementation
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Don't apply convertFromSnakeCase since models have explicit CodingKeys mappings
        return decoder
    }
    
    // Helper function to create an encoder with the same settings as the real implementation
    private func createEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        // Don't apply convertToSnakeCase since models have explicit CodingKeys mappings
        return encoder
    }
    
    @Test("PaginatedResponse decodes with results key")
    func testPaginatedResponseWithResults() throws {
        // Given
        let json = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 100,
                "pages": 2
            },
            "results": [
                {"id": 1, "name": "Test Item 1"},
                {"id": 2, "name": "Test Item 2"}
            ]
        }
        """.data(using: .utf8)!
        
        struct TestItem: Codable, Sendable {
            let id: Int
            let name: String
        }
        
        // When
        let response = try createDecoder().decode(PaginatedResponse<TestItem>.self, from: json)
        
        // Then
        #expect(response.pagination.page == 1)
        #expect(response.pagination.perPage == 50)
        #expect(response.items.count == 2)
        #expect(response.items[0].id == 1)
        #expect(response.items[0].name == "Test Item 1")
    }
    
    @Test("PaginatedResponse decodes with versions key")
    func testPaginatedResponseWithVersions() throws {
        // Given
        let json = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 100,
                "pages": 2
            },
            "versions": [
                {"id": 1, "name": "Version 1"}
            ]
        }
        """.data(using: .utf8)!
        
        struct TestItem: Codable, Sendable {
            let id: Int
            let name: String
        }
        
        // When
        let response = try createDecoder().decode(PaginatedResponse<TestItem>.self, from: json)
        
        // Then
        #expect(response.items.count == 1)
        #expect(response.items[0].name == "Version 1")
    }
    
    @Test("PaginatedResponse decodes with listings key")
    func testPaginatedResponseWithListings() throws {
        // Given
        let json = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 100,
                "pages": 2
            },
            "listings": [
                {"id": 1, "name": "Listing 1"}
            ]
        }
        """.data(using: .utf8)!
        
        struct TestItem: Codable, Sendable {
            let id: Int
            let name: String
        }
        
        // When
        let response = try createDecoder().decode(PaginatedResponse<TestItem>.self, from: json)
        
        // Then
        #expect(response.items.count == 1)
        #expect(response.items[0].name == "Listing 1")
    }
    
    @Test("ArtistAlias decodes correctly")
    func testArtistAliasDecoding() throws {
        // Given
        let json = """
        {
            "id": 123,
            "name": "Artist Alias Name",
            "resource_url": "https://api.discogs.com/artists/123",
            "active": true
        }
        """.data(using: .utf8)!
        
        // When
        let alias = try createDecoder().decode(ArtistAlias.self, from: json)
        
        // Then
        #expect(alias.id == 123)
        #expect(alias.name == "Artist Alias Name")
        #expect(alias.resourceUrl == "https://api.discogs.com/artists/123")
        #expect(alias.active == true)
    }
    
    @Test("ArtistMember decodes correctly")
    func testArtistMemberDecoding() throws {
        // Given
        let json = """
        {
            "id": 456,
            "name": "Band Member",
            "resource_url": "https://api.discogs.com/artists/456",
            "active": false
        }
        """.data(using: .utf8)!
        
        // When
        let member = try createDecoder().decode(ArtistMember.self, from: json)
        
        // Then
        #expect(member.id == 456)
        #expect(member.name == "Band Member")
        #expect(member.resourceUrl == "https://api.discogs.com/artists/456")
        #expect(member.active == false)
    }
    
    @Test("Models conform to Sendable")
    func testSendableConformance() throws {
        let json = """
        {
            "id": 123,
            "name": "Test",
            "resource_url": "https://example.com",
            "active": true
        }
        """.data(using: .utf8)!
        
        let alias = try createDecoder().decode(ArtistAlias.self, from: json)
        let member = try createDecoder().decode(ArtistMember.self, from: json)
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = alias
            let _ = member
        }
    }
    
    // MARK: - Artist Model Tests
    
    @Test("Artist decodes correctly with all fields")
    func testArtistDecodingComplete() throws {
        let json = """
        {
            "id": 123,
            "name": "The Beatles",
            "real_name": "John Lennon, Paul McCartney, George Harrison, Ringo Starr",
            "urls": ["https://www.thebeatles.com"],
            "namevariations": ["Beatles", "The Fab Four"],
            "profile": "British rock band formed in Liverpool in 1960",
            "data_quality": "Correct",
            "images": [
                {
                    "type": "primary",
                    "uri": "https://i.discogs.com/artist-image.jpg",
                    "uri150": "https://i.discogs.com/artist-image-150.jpg",
                    "width": 600,
                    "height": 600
                }
            ],
            "resource_url": "https://api.discogs.com/artists/123",
            "uri": "https://www.discogs.com/artist/123-The-Beatles",
            "releases_url": "https://api.discogs.com/artists/123/releases",
            "aliases": [
                {
                    "id": 124,
                    "name": "Beatles",
                    "resource_url": "https://api.discogs.com/artists/124",
                    "active": true
                }
            ],
            "members": [
                {
                    "id": 125,
                    "name": "John Lennon",
                    "resource_url": "https://api.discogs.com/artists/125",
                    "active": false
                }
            ]
        }
        """.data(using: .utf8)!
        
        let artist = try createDecoder().decode(Artist.self, from: json)
        
        #expect(artist.id == 123)
        #expect(artist.name == "The Beatles")
        #expect(artist.realName == "John Lennon, Paul McCartney, George Harrison, Ringo Starr")
        #expect(artist.urls?.count == 1)
        #expect(artist.namevariations?.count == 2)
        #expect(artist.profile?.contains("Liverpool") == true)
        #expect(artist.dataQuality == "Correct")
        #expect(artist.images?.count == 1)
        #expect(artist.resourceUrl == "https://api.discogs.com/artists/123")
        #expect(artist.aliases?.count == 1)
        #expect(artist.members?.count == 1)
    }
    
    @Test("Artist decodes with minimal fields")
    func testArtistDecodingMinimal() throws {
        let json = """
        {
            "id": 456,
            "name": "Solo Artist"
        }
        """.data(using: .utf8)!
        
        let artist = try createDecoder().decode(Artist.self, from: json)
        
        #expect(artist.id == 456)
        #expect(artist.name == "Solo Artist")
        #expect(artist.realName == nil)
        #expect(artist.urls == nil)
        #expect(artist.aliases == nil)
        #expect(artist.members == nil)
    }
    
    // MARK: - Release Model Tests
    
    @Test("Release decodes correctly")
    func testReleaseDecoding() throws {
        let json = """
        {
            "id": 789,
            "title": "Abbey Road",
            "status": "Accepted",
            "master_id": 456,
            "year": 1969,
            "format": "Vinyl",
            "label": "Apple Records",
            "artist": "The Beatles",
            "resource_url": "https://api.discogs.com/releases/789",
            "uri": "/releases/789-Abbey-Road",
            "catno": "PCS 7088",
            "stats": {
                "community": {
                    "want": 1500,
                    "have": 2500
                }
            }
        }
        """.data(using: .utf8)!
        
        let release = try createDecoder().decode(Release.self, from: json)
        
        #expect(release.id == 789)
        #expect(release.title == "Abbey Road")
        #expect(release.status == "Accepted")
        #expect(release.masterId == 456)
        #expect(release.year == 1969)
        #expect(release.format == "Vinyl")
        #expect(release.label == "Apple Records")
        #expect(release.artist == "The Beatles")
        #expect(release.catno == "PCS 7088")
        #expect(release.stats?.community?.want == 1500)
    }
    
    @Test("ReleaseDetails decodes with complex structure")
    func testReleaseDetailsDecoding() throws {
        let json = """
        {
            "id": 101,
            "title": "Sgt. Pepper's Lonely Hearts Club Band",
            "country": "UK",
            "year": 1967,
            "released_formatted": "1 Jun 1967",
            "notes": "Recorded at Abbey Road Studios",
            "styles": ["Psychedelic Rock", "Pop Rock"],
            "genres": ["Rock"],
            "estimated_weight": 180,
            "formats": [
                {
                    "name": "Vinyl",
                    "qty": "1",
                    "text": "LP",
                    "descriptions": ["12\\"", "33 ⅓ RPM", "Stereo"]
                }
            ],
            "master_id": 202,
            "artists": [
                {
                    "id": 123,
                    "name": "The Beatles",
                    "role": "",
                    "join": "",
                    "resource_url": "https://api.discogs.com/artists/123",
                    "anv": "",
                    "tracks": ""
                }
            ],
            "data_quality": "Correct",
            "community": {
                "status": "Accepted",
                "rating": {
                    "average": 4.5,
                    "count": 1000
                },
                "want": 500,
                "have": 1000,
                "contributors": [
                    {
                        "username": "collector1",
                        "resource_url": "https://api.discogs.com/users/collector1"
                    }
                ],
                "data_quality": "Correct"
            },
            "companies": [
                {
                    "id": 301,
                    "name": "EMI Records",
                    "entity_type": "Label",
                    "catno": "PCS 7027",
                    "resource_url": "https://api.discogs.com/labels/301"
                }
            ],
            "date_added": "2023-01-01T12:00:00-08:00",
            "date_changed": "2023-01-02T12:00:00-08:00",
            "tracklist": [
                {
                    "position": "A1",
                    "title": "Sgt. Pepper's Lonely Hearts Club Band",
                    "duration": "2:02",
                    "type_": "track",
                    "artists": [
                        {
                            "id": 123,
                            "name": "The Beatles",
                            "resource_url": "https://api.discogs.com/artists/123"
                        }
                    ]
                }
            ],
            "labels": [
                {
                    "id": 301,
                    "name": "Parlophone",
                    "catno": "PCS 7027",
                    "resource_url": "https://api.discogs.com/labels/301"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let release = try createDecoder().decode(ReleaseDetails.self, from: json)
        
        #expect(release.id == 101)
        #expect(release.title == "Sgt. Pepper's Lonely Hearts Club Band")
        #expect(release.country == "UK")
        #expect(release.year == 1967)
        #expect(release.releasedFormatted == "1 Jun 1967")
        #expect(release.styles?.count == 2)
        #expect(release.genres?.contains("Rock") == true)
        #expect(release.estimatedWeight == 180)
        #expect(release.formats?.count == 1)
        #expect(release.formats?[0].name == "Vinyl")
        #expect(release.masterId == 202)
        #expect(release.artists?.count == 1)
        #expect(release.community?.rating?.average == 4.5)
        #expect(release.tracklist?.count == 1)
        #expect(release.labels?.count == 1)
    }
    
    // MARK: - Label Model Tests
    
    @Test("Label decodes correctly")
    func testLabelDecoding() throws {
        let json = """
        {
            "id": 401,
            "name": "Blue Note Records",
            "contact_info": "contact@bluenote.com",
            "profile": "American jazz record label founded in 1939",
            "parent_label": "EMI Music",
            "sublabels": [
                {
                    "id": 402,
                    "name": "Blue Note Classics",
                    "resource_url": "https://api.discogs.com/labels/402"
                }
            ],
            "urls": ["https://www.bluenote.com"],
            "images": [
                {
                    "type": "primary",
                    "uri": "https://i.discogs.com/label-logo.jpg",
                    "width": 300,
                    "height": 300
                }
            ],
            "resource_url": "https://api.discogs.com/labels/401",
            "uri": "/labels/401-Blue-Note-Records",
            "releases_url": "https://api.discogs.com/labels/401/releases",
            "data_quality": "Correct"
        }
        """.data(using: .utf8)!
        
        let label = try createDecoder().decode(Label.self, from: json)
        
        #expect(label.id == 401)
        #expect(label.name == "Blue Note Records")
        #expect(label.contactInfo == "contact@bluenote.com")
        #expect(label.profile?.contains("jazz") == true)
        #expect(label.parentLabel == "EMI Music")
        #expect(label.sublabels?.count == 1)
        #expect(label.urls?.count == 1)
        #expect(label.images?.count == 1)
    }
    
    // MARK: - MasterRelease Model Tests
    
    @Test("MasterRelease decodes correctly")
    func testMasterReleaseDecoding() throws {
        let json = """
        {
            "id": 501,
            "title": "Kind of Blue",
            "year": 1959,
            "main_release": 12345,
            "main_release_url": "https://api.discogs.com/releases/12345",
            "versions_count": 150,
            "versions_url": "https://api.discogs.com/masters/501/versions",
            "artists": [
                {
                    "id": 601,
                    "name": "Miles Davis",
                    "resource_url": "https://api.discogs.com/artists/601"
                }
            ],
            "styles": ["Hard Bop", "Modal"],
            "genres": ["Jazz"],
            "images": [
                {
                    "type": "primary",
                    "uri": "https://i.discogs.com/master-image.jpg",
                    "width": 600,
                    "height": 600
                }
            ],
            "videos": [
                {
                    "uri": "https://www.youtube.com/watch?v=kbxtYqA6ypM",
                    "title": "Kind of Blue - Full Album",
                    "description": "Complete album recording",
                    "duration": 2700,
                    "embed": true
                }
            ],
            "tracklist": [
                {
                    "position": "A1",
                    "title": "So What",
                    "duration": "9:22"
                }
            ],
            "data_quality": "Correct",
            "uri": "/masters/501-Kind-of-Blue",
            "resource_url": "https://api.discogs.com/masters/501",
            "lowest_price": 15.99,
            "num_for_sale": 25
        }
        """.data(using: .utf8)!
        
        let master = try createDecoder().decode(MasterRelease.self, from: json)
        
        #expect(master.id == 501)
        #expect(master.title == "Kind of Blue")
        #expect(master.year == 1959)
        #expect(master.mainRelease == 12345)
        #expect(master.versionsCount == 150)
        #expect(master.artists?.count == 1)
        #expect(master.styles?.contains("Hard Bop") == true)
        #expect(master.genres?.contains("Jazz") == true)
        #expect(master.images?.count == 1)
        #expect(master.videos?.count == 1)
        #expect(master.tracklist?.count == 1)
        #expect(master.lowestPrice == 15.99)
        #expect(master.numForSale == 25)
    }
    
    // MARK: - Collection Model Tests
    
    @Test("CollectionItem decodes correctly")
    func testCollectionItemDecoding() throws {
        let json = """
        {
            "id": 701,
            "instance_id": 12345,
            "folder_id": 1,
            "rating": 5,
            "basic_information": {
                "id": 789,
                "master_id": 456,
                "master_url": "https://api.discogs.com/masters/456",
                "resource_url": "https://api.discogs.com/releases/789",
                "title": "Abbey Road",
                "year": 1969,
                "formats": [
                    {
                        "name": "Vinyl",
                        "qty": "1",
                        "descriptions": ["LP", "Album"]
                    }
                ],
                "labels": [
                    {
                        "name": "Apple Records",
                        "catno": "PCS 7088"
                    }
                ],
                "artists": [
                    {
                        "name": "The Beatles",
                        "anv": "",
                        "join": "",
                        "role": "",
                        "tracks": "",
                        "id": 123,
                        "resource_url": "https://api.discogs.com/artists/123"
                    }
                ],
                "thumb": "https://i.discogs.com/thumb.jpg",
                "cover_image": "https://i.discogs.com/cover.jpg"
            },
            "date_added": "2023-01-01T12:00:00-08:00",
            "notes": [
                {
                    "field_id": 1,
                    "value": "Mint condition"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let item = try createDecoder().decode(CollectionItem.self, from: json)
        
        #expect(item.id == 701)
        #expect(item.instanceId == 12345)
        #expect(item.folderId == 1)
        #expect(item.rating == 5)
        #expect(item.basicInformation.title == "Abbey Road")
        #expect(item.basicInformation.year == 1969)
        #expect(item.notes?.count == 1)
        #expect(item.notes?[0].value == "Mint condition")
    }
    
    @Test("Folder decodes correctly")
    func testFolderDecoding() throws {
        let json = """
        {
            "id": 1,
            "name": "All",
            "count": 150,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1"
        }
        """.data(using: .utf8)!
        
        let folder = try createDecoder().decode(Folder.self, from: json)
        
        #expect(folder.id == 1)
        #expect(folder.name == "All")
        #expect(folder.count == 150)
        #expect(folder.resourceUrl?.contains("folders/1") == true)
    }
    
    @Test("CollectionValue decodes correctly")
    func testCollectionValueDecoding() throws {
        let json = """
        {
            "maximum": "US$1,500.00",
            "median": "US$750.00",
            "minimum": "US$250.00"
        }
        """.data(using: .utf8)!
        
        let value = try createDecoder().decode(CollectionValue.self, from: json)
        
        #expect(value.maximum == "US$1,500.00")
        #expect(value.median == "US$750.00")
        #expect(value.minimum == "US$250.00")
    }
    
    // MARK: - Image and Video Model Tests
    
    @Test("Image decodes correctly")
    func testImageDecoding() throws {
        let json = """
        {
            "type": "primary",
            "uri": "https://i.discogs.com/image.jpg",
            "uri150": "https://i.discogs.com/image-150.jpg",
            "width": 600,
            "height": 600
        }
        """.data(using: .utf8)!
        
        let image = try createDecoder().decode(Image.self, from: json)
        
        #expect(image.type == "primary")
        #expect(image.uri == "https://i.discogs.com/image.jpg")
        #expect(image.uri150 == "https://i.discogs.com/image-150.jpg")
        #expect(image.width == 600)
        #expect(image.height == 600)
    }
    
    @Test("Video decodes correctly")
    func testVideoDecoding() throws {
        let json = """
        {
            "uri": "https://www.youtube.com/watch?v=abc123",
            "title": "Music Video",
            "description": "Official music video",
            "duration": 180,
            "embed": true
        }
        """.data(using: .utf8)!
        
        let video = try createDecoder().decode(Video.self, from: json)
        
        #expect(video.uri == "https://www.youtube.com/watch?v=abc123")
        #expect(video.title == "Music Video")
        #expect(video.description == "Official music video")
        #expect(video.duration == 180)
        #expect(video.embed == true)
    }
    
    // MARK: - Pagination Model Tests
    
    @Test("Pagination decodes correctly")
    func testPaginationDecoding() throws {
        let json = """
        {
            "page": 2,
            "per_page": 50,
            "items": 1000,
            "pages": 20,
            "urls": {
                "first": "https://api.discogs.com/endpoint?page=1",
                "prev": "https://api.discogs.com/endpoint?page=1",
                "next": "https://api.discogs.com/endpoint?page=3",
                "last": "https://api.discogs.com/endpoint?page=20"
            }
        }
        """.data(using: .utf8)!
        
        let pagination = try createDecoder().decode(Pagination.self, from: json)
        
        #expect(pagination.page == 2)
        #expect(pagination.perPage == 50)
        #expect(pagination.items == 1000)
        #expect(pagination.pages == 20)
        #expect(pagination.urls?.first?.contains("page=1") == true)
        #expect(pagination.urls?.next?.contains("page=3") == true)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Models handle missing optional fields gracefully")
    func testMissingOptionalFields() throws {
        let artistJson = """
        {
            "id": 999,
            "name": "Minimal Artist"
        }
        """.data(using: .utf8)!
        
        let artist = try createDecoder().decode(Artist.self, from: artistJson)
        
        #expect(artist.id == 999)
        #expect(artist.name == "Minimal Artist")
        #expect(artist.realName == nil)
        #expect(artist.urls == nil)
        #expect(artist.images == nil)
        #expect(artist.aliases == nil)
    }
    
    @Test("Models handle malformed JSON appropriately")
    func testMalformedJSON() throws {
        let malformedJson = """
        {
            "id": "not_a_number",
            "name": "Test"
        }
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            _ = try createDecoder().decode(Artist.self, from: malformedJson)
        }
    }
    
    @Test("Models handle empty arrays correctly")
    func testEmptyArrays() throws {
        let json = """
        {
            "id": 123,
            "name": "Test Artist",
            "urls": [],
            "images": [],
            "aliases": [],
            "members": []
        }
        """.data(using: .utf8)!
        
        let artist = try createDecoder().decode(Artist.self, from: json)
        
        #expect(artist.id == 123)
        #expect(artist.urls?.isEmpty == true)
        #expect(artist.images?.isEmpty == true)
        #expect(artist.aliases?.isEmpty == true)
        #expect(artist.members?.isEmpty == true)
    }
    
    // MARK: - Encoding Tests
    
    @Test("Models encode to JSON correctly")
    func testModelEncoding() throws {
        let artist = Artist(
            id: 123,
            name: "Test Artist",
            realName: "Real Name",
            urls: ["https://example.com"],
            namevariations: ["Variation"],
            profile: "Profile text",
            dataQuality: "Correct",
            images: nil,
            resourceUrl: "https://api.discogs.com/artists/123",
            uri: "/artists/123",
            releasesUrl: "https://api.discogs.com/artists/123/releases",
            aliases: nil,
            members: nil
        )
        
        let encoder = createEncoder()
        let data = try encoder.encode(artist)
        let decoded = try createDecoder().decode(Artist.self, from: data)
        
        #expect(decoded.id == artist.id)
        #expect(decoded.name == artist.name)
        #expect(decoded.realName == artist.realName)
        #expect(decoded.urls == artist.urls)
        #expect(decoded.profile == artist.profile)
    }
    
    // MARK: - Snake Case Conversion Tests
    
    @Test("Snake case fields decode correctly")
    func testSnakeCaseDecoding() throws {
        let json = """
        {
            "id": 123,
            "name": "Test",
            "resource_url": "https://example.com",
            "real_name": "Real Name",
            "data_quality": "Correct",
            "releases_url": "https://example.com/releases"
        }
        """.data(using: .utf8)!
        
        let artist = try createDecoder().decode(Artist.self, from: json)
        
        #expect(artist.resourceUrl == "https://example.com")
        #expect(artist.realName == "Real Name")
        #expect(artist.dataQuality == "Correct")
        #expect(artist.releasesUrl == "https://example.com/releases")
    }
    
    // MARK: - Marketplace Model Tests
    
    @Test("Listing decodes correctly")
    func testListingDecoding() throws {
        let json = """
        {
            "id": 123456,
            "resource_url": "https://api.discogs.com/marketplace/listings/123456",
            "uri": "https://www.discogs.com/sell/item/123456",
            "status": "For Sale",
            "condition": "Near Mint (NM or M-)",
            "sleeve_condition": "Very Good Plus (VG+)",
            "price": {
                "currency": "USD",
                "value": 25.99
            },
            "original_price": {
                "currency": "USD",
                "value": 30.00
            },
            "shipping_price": {
                "currency": "USD",
                "value": 5.00
            },
            "allow_offers": true,
            "audio": false,
            "seller": {
                "id": 789,
                "username": "seller123",
                "resource_url": "https://api.discogs.com/users/seller123",
                "stats": {
                    "rating": "99.8%",
                    "rating_count": 1250,
                    "average_rating": 4.99,
                    "orders": 1500
                }
            },
            "release": {
                "id": 12345,
                "title": "Test Album",
                "year": 2023,
                "resource_url": "https://api.discogs.com/releases/12345",
                "artists": [
                    {
                        "id": 456,
                        "name": "Test Artist"
                    }
                ]
            },
            "comments": "Excellent condition, barely played"
        }
        """.data(using: .utf8)!
        
        let listing = try createDecoder().decode(Listing.self, from: json)
        
        #expect(listing.id == 123456)
        #expect(listing.status == "For Sale")
        #expect(listing.condition == "Near Mint (NM or M-)")
        #expect(listing.sleeveCondition == "Very Good Plus (VG+)")
        #expect(listing.price.value == 25.99)
        #expect(listing.price.currency == "USD")
        #expect(listing.allowOffers == true)
        #expect(listing.audio == false)
        #expect(listing.seller.username == "seller123")
        #expect(listing.comments == "Excellent condition, barely played")
    }
    
    @Test("Price decodes correctly")
    func testPriceDecoding() throws {
        let json = """
        {
            "currency": "EUR",
            "value": 45.50
        }
        """.data(using: .utf8)!
        
        let price = try createDecoder().decode(Price.self, from: json)
        
        #expect(price.currency == "EUR")
        #expect(price.value == 45.50)
    }
    
    @Test("Order decodes correctly")
    func testOrderDecoding() throws {
        let json = """
        {
            "id": "12345-67890",
            "resource_url": "https://api.discogs.com/marketplace/orders/12345-67890",
            "messages_url": "https://api.discogs.com/marketplace/orders/12345-67890/messages",
            "uri": "https://www.discogs.com/sell/order/12345-67890",
            "status": "Payment Pending",
            "next_status_options": ["Shipped"],
            "fee": {
                "currency": "USD",
                "value": 2.60
            },
            "created": "2023-01-15T10:30:00-08:00",
            "shipping": {
                "currency": "USD",
                "value": 5.00,
                "method": "Standard"
            },
            "total": {
                "currency": "USD",
                "value": 30.99
            },
            "seller": {
                "id": 789,
                "username": "seller123",
                "resource_url": "https://api.discogs.com/users/seller123"
            },
            "buyer": {
                "id": 456,
                "username": "buyer123",
                "resource_url": "https://api.discogs.com/users/buyer123"
            },
            "items": [
                {
                    "id": 987654,
                    "resource_url": "https://api.discogs.com/marketplace/listings/987654",
                    "release": {
                        "id": 12345,
                        "resource_url": "https://api.discogs.com/releases/12345",
                        "description": "Test Artist - Test Album (LP, Album)",
                        "thumbnail": "https://i.discogs.com/thumb.jpg"
                    },
                    "price": {
                        "currency": "USD",
                        "value": 25.99
                    },
                    "media_condition": "Near Mint (NM or M-)",
                    "sleeve_condition": "Very Good Plus (VG+)"
                }
            ],
            "last_message": "Order confirmed",
            "archived": false,
            "needs_response": true
        }
        """.data(using: .utf8)!
        
        let order = try createDecoder().decode(Order.self, from: json)
        
        #expect(order.id == "12345-67890")
        #expect(order.status == "Payment Pending")
        #expect(order.nextStatus?.contains("Shipped") == true)
        #expect(order.fee?.value == 2.60)
        #expect(order.total.value == 30.99)
        #expect(order.seller.username == "seller123")
        #expect(order.buyer?.username == "buyer123")
        #expect(order.items.count == 1)
        #expect(order.lastMessage == "Order confirmed")
        #expect(order.archived == false)
        #expect(order.needsResponse == true)
    }
    
    @Test("Seller decodes correctly")
    func testSellerDecoding() throws {
        let json = """
        {
            "id": 789,
            "username": "vinyl_collector",
            "avatar_url": "https://secure.gravatar.com/avatar/abc123",
            "resource_url": "https://api.discogs.com/users/vinyl_collector",
            "location": "London, UK",
            "name": "Vinyl Collector Store",
            "stats": {
                "rating": "99.5%",
                "rating_count": 850,
                "average_rating": 4.98,
                "orders": 1200
            },
            "rating": {
                "average": 4.98,
                "count": 850,
                "last": {
                    "buyer_username": "customer123",
                    "value": 5,
                    "count": 851
                }
            }
        }
        """.data(using: .utf8)!
        
        let seller = try createDecoder().decode(Seller.self, from: json)
        
        #expect(seller.id == 789)
        #expect(seller.username == "vinyl_collector")
        #expect(seller.location == "London, UK")
        #expect(seller.name == "Vinyl Collector Store")
        #expect(seller.stats?.rating == "99.5%")
        #expect(seller.stats?.orders == 1200)
        #expect(seller.rating?.average == 4.98)
        #expect(seller.rating?.count == 850)
        #expect(seller.rating?.last?.buyerUsername == "customer123")
    }
    
    @Test("PriceSuggestions decodes correctly")
    func testPriceSuggestionsDecoding() throws {
        let json = """
        {
            "median": {
                "currency": "USD",
                "value": 25.00
            },
            "minimum": {
                "currency": "USD",
                "value": 15.00
            },
            "maximum": {
                "currency": "USD",
                "value": 45.00
            }
        }
        """.data(using: .utf8)!
        
        let suggestions = try createDecoder().decode(PriceSuggestions.self, from: json)
        
        #expect(suggestions.median?.value == 25.00)
        #expect(suggestions.minimum?.value == 15.00)
        #expect(suggestions.maximum?.value == 45.00)
        #expect(suggestions.median?.currency == "USD")
    }
    
    // MARK: - Search Model Tests
    
    @Test("SearchResult decodes correctly")
    func testSearchResultDecoding() throws {
        let json = """
        {
            "id": 12345,
            "type": "release",
            "user_data": {
                "in_wantlist": true,
                "in_collection": false
            },
            "master_id": 67890,
            "master_url": "https://api.discogs.com/masters/67890",
            "title": "Abbey Road",
            "thumb": "https://i.discogs.com/thumb.jpg",
            "cover_image": "https://i.discogs.com/cover.jpg",
            "resource_url": "https://api.discogs.com/releases/12345",
            "uri": "/The-Beatles-Abbey-Road/release/12345",
            "country": "UK",
            "year": "1969",
            "format": ["Vinyl", "LP", "Album"],
            "label": ["Apple Records"],
            "genre": ["Rock"],
            "style": ["Pop Rock", "Psychedelic Rock"],
            "barcode": ["5099969944123"],
            "catno": "PCS 7088",
            "community": {
                "want": 500,
                "have": 1000
            }
        }
        """.data(using: .utf8)!
        
        let result = try createDecoder().decode(SearchResult.self, from: json)
        
        #expect(result.id == 12345)
        #expect(result.type == "release")
        #expect(result.userData?.inWantlist == true)
        #expect(result.userData?.inCollection == false)
        #expect(result.masterId == 67890)
        #expect(result.title == "Abbey Road")
        #expect(result.country == "UK")
        #expect(result.year == "1969")
        #expect(result.format?.contains("Vinyl") == true)
        #expect(result.label?.contains("Apple Records") == true)
        #expect(result.genre?.contains("Rock") == true)
        #expect(result.style?.contains("Pop Rock") == true)
        #expect(result.catno == "PCS 7088")
        #expect(result.community?.want == 500)
    }
    
    @Test("UserData decodes correctly")
    func testUserDataDecoding() throws {
        let json = """
        {
            "in_wantlist": true,
            "in_collection": false
        }
        """.data(using: .utf8)!
        
        let userData = try createDecoder().decode(UserData.self, from: json)
        
        #expect(userData.inWantlist == true)
        #expect(userData.inCollection == false)
    }
    
    // MARK: - User Model Tests
    
    @Test("UserIdentity decodes correctly")
    func testUserIdentityDecoding() throws {
        let json = """
        {
            "id": 123,
            "username": "collector123",
            "resource_url": "https://api.discogs.com/users/collector123",
            "consumer_name": "My Discogs App"
        }
        """.data(using: .utf8)!
        
        let identity = try createDecoder().decode(UserIdentity.self, from: json)
        
        #expect(identity.id == 123)
        #expect(identity.username == "collector123")
        #expect(identity.resourceUrl == "https://api.discogs.com/users/collector123")
        #expect(identity.consumerName == "My Discogs App")
    }
    
    @Test("UserProfile decodes correctly")
    func testUserProfileDecoding() throws {
        let json = """
        {
            "id": 456,
            "username": "vinyl_enthusiast",
            "resource_url": "https://api.discogs.com/users/vinyl_enthusiast",
            "name": "John Doe",
            "email": "john@example.com",
            "profile": "Music lover and vinyl collector since 1995",
            "location": "New York, NY",
            "registered": "2010-05-15T10:30:00-04:00",
            "num_collection": 150,
            "num_wantlist": 25,
            "num_for_sale": 10,
            "num_lists": 3,
            "releases_contributed": 50,
            "releases_rated": 200,
            "rating_avg": 4.2,
            "inventory_url": "https://api.discogs.com/users/vinyl_enthusiast/inventory",
            "collection_folders_url": "https://api.discogs.com/users/vinyl_enthusiast/collection/folders",
            "collection_fields_url": "https://api.discogs.com/users/vinyl_enthusiast/collection/fields",
            "wantlist_url": "https://api.discogs.com/users/vinyl_enthusiast/wants"
        }
        """.data(using: .utf8)!
        
        let profile = try createDecoder().decode(UserProfile.self, from: json)
        
        #expect(profile.id == 456)
        #expect(profile.username == "vinyl_enthusiast")
        #expect(profile.name == "John Doe")
        #expect(profile.email == "john@example.com")
        #expect(profile.profile?.contains("vinyl collector") == true)
        #expect(profile.location == "New York, NY")
        #expect(profile.numCollection == 150)
        #expect(profile.numWantlist == 25)
        #expect(profile.numLists == 3)
        #expect(profile.ratingAvg == 4.2)
    }
    
    @Test("Submission decodes correctly")
    func testSubmissionDecoding() throws {
        let json = """
        {
            "id": 789,
            "user": {
                "username": "testuser",
                "resource_url": "https://api.discogs.com/users/testuser"
            },
            "status": "Accepted",
            "title": "Test Album",
            "type": "release",
            "url": "https://api.discogs.com/releases/12345",
            "submission_date": "2023-01-15T10:30:00-08:00"
        }
        """.data(using: .utf8)!
        
        let submission = try createDecoder().decode(Submission.self, from: json)
        
        #expect(submission.id == 789)
        #expect(submission.status == "Accepted")
        #expect(submission.title == "Test Album")
    }
    
    // MARK: - Wantlist Model Tests
    
    @Test("WantlistItem decodes correctly")
    func testWantlistItemDecoding() throws {
        let json = """
        {
            "id": 987,
            "resource_url": "https://api.discogs.com/users/collector/wants/987",
            "rating": 4,
            "notes": "Looking for mint condition",
            "date_added": "2023-01-01T12:00:00-08:00",
            "basic_information": {
                "id": 12345,
                "title": "Wish You Were Here",
                "resource_url": "https://api.discogs.com/releases/12345",
                "year": 1975,
                "artists": [
                    {
                        "id": 456,
                        "name": "Pink Floyd"
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
        """.data(using: .utf8)!
        
        let item = try createDecoder().decode(WantlistItem.self, from: json)
        
        #expect(item.id == 987)
        #expect(item.rating == 4)
        #expect(item.notes == "Looking for mint condition")
        #expect(item.dateAdded?.contains("2023-01-01") == true)
        #expect(item.basicInformation.title == "Wish You Were Here")
        #expect(item.basicInformation.year == 1975)
    }
    
    // MARK: - Complex Nested Structure Tests
    
    @Test("Complex nested structures decode correctly")
    func testComplexNestedDecoding() throws {
        let json = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 1,
                "pages": 1,
                "urls": {
                    "first": "https://api.discogs.com/endpoint?page=1",
                    "last": "https://api.discogs.com/endpoint?page=1"
                }
            },
            "results": [
                {
                    "id": 12345,
                    "title": "Complex Release",
                    "year": 2023,
                    "formats": [
                        {
                            "name": "Vinyl",
                            "qty": "2",
                            "descriptions": ["LP", "Album", "180g", "Gatefold"]
                        }
                    ],
                    "artists": [
                        {
                            "id": 456,
                            "name": "Test Artist",
                            "anv": "T.A.",
                            "role": "Main",
                            "tracks": "A1-B2"
                        }
                    ],
                    "labels": [
                        {
                            "id": 789,
                            "name": "Independent Records",
                            "catno": "IR-001"
                        }
                    ],
                    "community": {
                        "status": "Accepted",
                        "rating": {
                            "average": 4.7,
                            "count": 125
                        },
                        "want": 45,
                        "have": 89,
                        "contributors": [
                            {
                                "username": "contributor1",
                                "resource_url": "https://api.discogs.com/users/contributor1"
                            }
                        ]
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try createDecoder().decode(PaginatedResponse<ReleaseDetails>.self, from: json)
        
        #expect(response.pagination.page == 1)
        #expect(response.items.count == 1)
        
        let release = response.items[0]
        #expect(release.id == 12345)
        #expect(release.title == "Complex Release")
        #expect(release.formats?.count == 1)
        #expect(release.formats?[0].descriptions?.contains("Gatefold") == true)
        #expect(release.artists?.count == 1)
        #expect(release.artists?[0].anv == "T.A.")
        #expect(release.labels?.count == 1)
        #expect(release.community?.rating?.average == 4.7)
        #expect(release.community?.contributors?.count == 1)
    }
    
    // MARK: - Edge Cases and Error Scenarios
    
    @Test("Null values in optional fields handle correctly")
    func testNullValuesInOptionalFields() throws {
        let json = """
        {
            "id": 123,
            "name": "Test Artist",
            "real_name": null,
            "urls": null,
            "images": null,
            "profile": null
        }
        """.data(using: .utf8)!
        
        let artist = try createDecoder().decode(Artist.self, from: json)
        
        #expect(artist.id == 123)
        #expect(artist.name == "Test Artist")
        #expect(artist.realName == nil)
        #expect(artist.urls == nil)
        #expect(artist.images == nil)
        #expect(artist.profile == nil)
    }
    
    @Test("Different pagination response keys decode correctly")
    func testDifferentPaginationKeys() throws {
        // Test with "listings" key
        let listingsJson = """
        {
            "pagination": {"page": 1, "per_page": 50, "items": 1, "pages": 1},
            "listings": [{"id": 123, "name": "Test"}]
        }
        """.data(using: .utf8)!
        
        struct TestItem: Codable, Sendable {
            let id: Int
            let name: String
        }
        
        let listingsResponse = try createDecoder().decode(PaginatedResponse<TestItem>.self, from: listingsJson)
        #expect(listingsResponse.items.count == 1)
        #expect(listingsResponse.items[0].id == 123)
        
        // Test with "orders" key
        let ordersJson = """
        {
            "pagination": {"page": 1, "per_page": 50, "items": 1, "pages": 1},
            "orders": [{"id": 456, "name": "Test Order"}]
        }
        """.data(using: .utf8)!
        
        let ordersResponse = try createDecoder().decode(PaginatedResponse<TestItem>.self, from: ordersJson)
        #expect(ordersResponse.items.count == 1)
        #expect(ordersResponse.items[0].id == 456)
    }
    
    @Test("Date string formats parse correctly")
    func testDateStringFormats() throws {
        let json = """
        {
            "id": 123,
            "instance_id": 456,
            "folder_id": 1,
            "basic_information": {
                "id": 789,
                "title": "Test",
                "year": 2023,
                "resource_url": "https://api.discogs.com/releases/789"
            },
            "date_added": "2023-01-15T10:30:00-08:00"
        }
        """.data(using: .utf8)!
        
        let item = try createDecoder().decode(CollectionItem.self, from: json)
        
        #expect(item.dateAdded?.contains("2023-01-15") == true)
        #expect(item.dateAdded?.contains("10:30:00") == true)
    }
    
    @Test("Missing required fields throw decoding errors")
    func testMissingRequiredFields() throws {
        let jsonMissingId = """
        {
            "name": "Test Artist"
        }
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            _ = try createDecoder().decode(Artist.self, from: jsonMissingId)
        }
        
        let jsonMissingName = """
        {
            "id": 123
        }
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            _ = try createDecoder().decode(Artist.self, from: jsonMissingName)
        }
    }
    
    @Test("Large numeric values handle correctly")
    func testLargeNumericValues() throws {
        let json = """
        {
            "id": 2147483647,
            "title": "Test Release",
            "name": "Test",
            "year": 2023,
            "estimated_weight": 999999
        }
        """.data(using: .utf8)!
        
        let release = try createDecoder().decode(ReleaseDetails.self, from: json)
        
        #expect(release.id == 2147483647)
        #expect(release.estimatedWeight == 999999)
    }
    
    @Test("Special characters in strings handle correctly")
    func testSpecialCharacters() throws {
        let json = """
        {
            "id": 123,
            "name": "Björk & Sigur Rós",
            "profile": "Icelandic artists with special characters: æøå ñü",
            "title": "Album with \\"quotes\\" and 'apostrophes'"
        }
        """.data(using: .utf8)!
        
        let artist = try createDecoder().decode(Artist.self, from: json)
        
        #expect(artist.name == "Björk & Sigur Rós")
        #expect(artist.profile?.contains("æøå ñü") == true)
    }
}
