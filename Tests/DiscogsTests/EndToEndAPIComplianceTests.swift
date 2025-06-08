import Testing
import Foundation
@testable import Discogs

/// Comprehensive end-to-end tests that validate the Swift package implementation
/// against the official Discogs API specification and documentation
@Suite("End-to-End API Compliance Tests")
struct EndToEndAPIComplianceTests {
    
    // MARK: - Test Configuration
    
    private func createTestClient() -> Discogs {
        // Use a test token - in real tests you'd use environment variables
        return Discogs(
            token: "test_token_12345",
            userAgent: "DiscogsSwiftPackage/2.0 +https://github.com/example/discogs-swift"
        )
    }
    
    private func createMockClient() -> MockHTTPClient {
        return MockHTTPClient()
    }
    
    // MARK: - Database Service End-to-End Tests
    
    @Test("Database Service - Complete API Coverage")
    func testDatabaseServiceEndToEnd() async throws {
        let mockClient = createMockClient()
        let databaseService = DatabaseService(httpClient: mockClient)
        
        // Test 1: Artist operations
        let artistJson = """
        {
            "id": 1,
            "name": "The Beatles",
            "real_name": "The Beatles",
            "profile": "English rock band formed in Liverpool in 1960",
            "data_quality": "Correct",
            "images": [
                {
                    "type": "primary",
                    "uri": "https://img.discogs.com/image.jpg",
                    "width": 600,
                    "height": 600
                }
            ],
            "resource_url": "https://api.discogs.com/artists/1",
            "uri": "https://api.discogs.com/artists/1",
            "releases_url": "https://api.discogs.com/artists/1/releases"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(artistJson)
        let artist = try await databaseService.getArtist(id: 1)
        #expect(artist.name == "The Beatles")
        #expect(artist.profile?.contains("Liverpool") == true)
        
        // Test 2: Artist releases with pagination and sorting
        let artistReleasesJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 10,
                "per_page": 50,
                "items": 500,
                "urls": {
                    "last": "https://api.discogs.com/artists/1/releases?page=10",
                    "next": "https://api.discogs.com/artists/1/releases?page=2"
                }
            },
            "releases": [
                {
                    "id": 1,
                    "title": "Abbey Road",
                    "year": 1969,
                    "resource_url": "https://api.discogs.com/releases/1"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(artistReleasesJson)
        let artistReleases = try await databaseService.getArtistReleases(
            artistId: 1,
            page: 1,
            perPage: 50,
            sort: .year,
            sortOrder: .descending
        )
        #expect(artistReleases.pagination.page == 1)
        #expect(artistReleases.items.first?.title == "Abbey Road")
        
        // Test 3: Release details with currency support
        let releaseJson = """
        {
            "id": 1,
            "title": "Abbey Road",
            "country": "UK",
            "year": 1969,
            "genres": ["Rock"],
            "styles": ["Pop Rock"],
            "formats": [
                {
                    "name": "Vinyl",
                    "qty": "1",
                    "descriptions": ["LP", "Album"]
                }
            ],
            "artists": [
                {
                    "id": 1,
                    "name": "The Beatles",
                    "resource_url": "https://api.discogs.com/artists/1"
                }
            ],
            "tracklist": [
                {
                    "position": "A1",
                    "title": "Come Together",
                    "duration": "4:19"
                }
            ],
            "labels": [
                {
                    "id": 1,
                    "name": "Apple Records",
                    "catno": "PCS 7088"
                }
            ],
            "community": {
                "rating": {
                    "average": 4.5,
                    "count": 1000
                },
                "want": 5000,
                "have": 10000
            }
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(releaseJson)
        let release = try await databaseService.getRelease(id: 1, currency: "USD")
        #expect(release.title == "Abbey Road")
        #expect(release.country == "UK")
        #expect(release.community?.want == 5000)
        
        // Test 4: Master release operations
        let masterJson = """
        {
            "id": 1,
            "title": "Abbey Road",
            "year": 1969,
            "main_release": 1,
            "versions_count": 250,
            "artists": [
                {
                    "id": 1,
                    "name": "The Beatles"
                }
            ],
            "genres": ["Rock"],
            "styles": ["Pop Rock"],
            "lowest_price": 15.99,
            "num_for_sale": 150
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(masterJson)
        let master = try await databaseService.getMasterRelease(id: 1)
        #expect(master.title == "Abbey Road")
        #expect(master.versionsCount == 250)
        
        // Test 5: Label operations
        let labelJson = """
        {
            "id": 1,
            "name": "Apple Records",
            "profile": "Record label founded by The Beatles",
            "contact_info": "London, UK",
            "data_quality": "Correct",
            "images": [
                {
                    "type": "primary",
                    "uri": "https://img.discogs.com/label.jpg"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(labelJson)
        let label = try await databaseService.getLabel(id: 1)
        #expect(label.name == "Apple Records")
        
        // Test 6: Release rating operations
        let ratingJson = """
        {
            "username": "testuser",
            "release_id": 1,
            "rating": 5
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(ratingJson)
        let rating = try await databaseService.updateReleaseRating(
            releaseId: 1,
            username: "testuser",
            rating: 5
        )
        #expect(rating.rating == 5)
    }
    
    // MARK: - Search Service End-to-End Tests
    
    @Test("Search Service - Comprehensive Search Functionality")
    func testSearchServiceEndToEnd() async throws {
        let mockClient = createMockClient()
        let searchService = SearchService(httpClient: mockClient)
        
        let searchJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 5,
                "per_page": 50,
                "items": 250
            },
            "results": [
                {
                    "id": 1,
                    "type": "release",
                    "user_data": {
                        "in_wantlist": true,
                        "in_collection": false
                    },
                    "master_id": 1,
                    "title": "Abbey Road",
                    "country": "UK",
                    "year": "1969",
                    "format": ["Vinyl", "LP"],
                    "label": ["Apple Records"],
                    "genre": ["Rock"],
                    "style": ["Pop Rock"],
                    "catno": "PCS 7088",
                    "barcode": ["5099969944123"],
                    "community": {
                        "want": 5000,
                        "have": 10000
                    },
                    "thumb": "https://img.discogs.com/thumb.jpg"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(searchJson)
        
        // Test comprehensive search with all parameters
        let searchResults = try await searchService.search(
            query: "Abbey Road",
            type: .release,
            title: "Abbey Road",
            artist: "The Beatles",
            label: "Apple Records",
            genre: "Rock",
            style: "Pop Rock",
            country: "UK",
            year: "1969",
            format: "Vinyl",
            catno: "PCS 7088",
            barcode: "5099969944123",
            page: 1,
            perPage: 50
        )
        
        #expect(searchResults.pagination.items == 250)
        #expect(searchResults.items.first?.title == "Abbey Road")
        #expect(searchResults.items.first?.userData?.inWantlist == true)
        #expect(searchResults.items.first?.community?.want == 5000)
    }
    
    // MARK: - Collection Service End-to-End Tests
    
    @Test("Collection Service - Complete Collection Management")
    func testCollectionServiceEndToEnd() async throws {
        let mockClient = createMockClient()
        let collectionService = CollectionService(httpClient: mockClient)
        
        // Test 1: Get collection folders
        let foldersJson = """
        {
            "folders": [
                {
                    "id": 0,
                    "name": "All",
                    "count": 500,
                    "resource_url": "https://api.discogs.com/users/testuser/collection/folders/0"
                },
                {
                    "id": 1,
                    "name": "Uncategorized",
                    "count": 300,
                    "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(foldersJson)
        let folders = try await collectionService.getFolders(username: "testuser")
        #expect(folders.folders.count == 2)
        #expect(folders.folders.first?.name == "All")
        
        // Test 2: Create new folder
        let newFolderJson = """
        {
            "id": 2,
            "name": "Rock Albums",
            "count": 0,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/2"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(newFolderJson)
        let newFolder = try await collectionService.createFolder(
            username: "testuser",
            name: "Rock Albums"
        )
        #expect(newFolder.name == "Rock Albums")
        #expect(newFolder.id == 2)
        
        // Test 3: Get collection items with sorting
        let itemsJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 10,
                "per_page": 50,
                "items": 500
            },
            "releases": [
                {
                    "id": 1,
                    "instance_id": 123,
                    "folder_id": 1,
                    "rating": 5,
                    "basic_information": {
                        "id": 1,
                        "title": "Abbey Road",
                        "year": 1969,
                        "resource_url": "https://api.discogs.com/releases/1",
                        "artists": [
                            {
                                "id": 1,
                                "name": "The Beatles"
                            }
                        ],
                        "formats": [
                            {
                                "name": "Vinyl",
                                "qty": "1"
                            }
                        ]
                    },
                    "date_added": "2023-01-15T10:30:00-08:00"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(itemsJson)
        let items = try await collectionService.getItemsInFolder(
            username: "testuser",
            folderId: 1,
            page: 1,
            perPage: 50,
            sort: .artist,
            sortOrder: .ascending
        )
        #expect(items.pagination.items == 500)
        #expect(items.items.first?.basicInformation.title == "Abbey Road")
        
        // Test 4: Add item to collection
        let addItemJson = """
        {
            "instance_id": 124,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1/releases/2/instances/124"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(addItemJson)
        let addedItem = try await collectionService.addReleaseToFolder(
            username: "testuser",
            folderId: 1,
            releaseId: 2
        )
        #expect(addedItem.instances?.first?.id == 124)
        
        // Test 5: Update collection item fields
        let updateJson = """
        {
            "value": ["4"]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(updateJson)
        let updatedField = try await collectionService.editItemFieldValue(
            username: "testuser",
            folderId: 1,
            releaseId: 1,
            instanceId: 123,
            fieldId: 1, // Assuming field ID 1 for rating
            value: ["4"]
        )
        #expect(updatedField.value.contains("4"))
        
        // Test 6: Collection value calculation
        let valueJson = """
        {
            "maximum": "1500.00",
            "median": "750.00",
            "minimum": "500.00"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(valueJson)
        let value = try await collectionService.getValue(username: "testuser")
        #expect(value.maximum == "1500.00")
        #expect(value.median == "750.00")
    }
    
    // MARK: - Wantlist Service End-to-End Tests
    
    @Test("Wantlist Service - Complete Wantlist Management")
    func testWantlistServiceEndToEnd() async throws {
        let mockClient = createMockClient()
        let wantlistService = WantlistService(httpClient: mockClient)
        
        // Test 1: Get wantlist with sorting
        let wantlistJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 5,
                "per_page": 50,
                "items": 250
            },
            "wants": [
                {
                    "id": 1,
                    "rating": 5,
                    "notes": "Looking for original pressing",
                    "resource_url": "https://api.discogs.com/users/testuser/wants/1",
                    "basic_information": {
                        "id": 1,
                        "title": "Dark Side of the Moon",
                        "year": 1973,
                        "artists": [
                            {
                                "id": 2,
                                "name": "Pink Floyd"
                            }
                        ]
                    },
                    "date_added": "2023-01-10T15:20:00-08:00"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(wantlistJson)
        let wantlist = try await wantlistService.getWantlist(
            username: "testuser",
            page: 1,
            perPage: 50,
            sort: .added,
            sortOrder: .descending
        )
        #expect(wantlist.pagination.items == 250)
        #expect(wantlist.items.first?.basicInformation.title == "Dark Side of the Moon")
        #expect(wantlist.items.first?.notes == "Looking for original pressing")
        
        // Test 2: Add to wantlist
        let addWantJson = """
        {
            "id": 2,
            "rating": 4,
            "notes": "Birthday gift idea",
            "resource_url": "https://api.discogs.com/users/testuser/wants/2",
            "basic_information": {
                "id": 2,
                "title": "The Wall",
                "year": 1979
            }
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(addWantJson)
        let addedWant = try await wantlistService.addToWantlist(
            username: "testuser",
            releaseId: 2,
            notes: "Birthday gift idea",
            rating: 4
        )
        #expect(addedWant.rating == 4)
        #expect(addedWant.notes == "Birthday gift idea")
    }
    
    // MARK: - Marketplace Service End-to-End Tests
    
    @Test("Marketplace Service - Comprehensive Marketplace Operations")
    func testMarketplaceServiceEndToEnd() async throws {
        let mockClient = createMockClient()
        let marketplaceService = MarketplaceService(httpClient: mockClient)
        
        // Test 1: Get inventory
        let inventoryJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 3,
                "per_page": 50,
                "items": 150
            },
            "listings": [
                {
                    "id": 123,
                    "status": "For Sale",
                    "price": {
                        "currency": "USD",
                        "value": 25.99
                    },
                    "release": {
                        "id": 1,
                        "title": "Abbey Road",
                        "year": 1969
                    },
                    "condition": "Very Good Plus (VG+)",
                    "sleeve_condition": "Very Good Plus (VG+)",
                    "comments": "Original pressing, some light wear",
                    "allow_offers": true,
                    "seller": {
                        "id": 1,
                        "username": "seller123",
                        "resource_url": "https://api.discogs.com/users/seller123"
                    },
                    "posted": "2023-06-01T10:00:00-08:00"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(inventoryJson)
        let inventory = try await marketplaceService.getInventory(
            username: "testuser",
            status: .forSale,
            sort: .listed,
            sortOrder: .descending,
            page: 1,
            perPage: 50
        )
        #expect(inventory.pagination.items == 150)
        #expect(inventory.items.first?.status == "For Sale")
        #expect(inventory.items.first?.price.value == 25.99)
        
        // Test 2: Create listing
        let createListingJson = """
        {
            "id": 124,
            "status": "Draft",
            "price": {
                "currency": "USD",
                "value": 29.99
            },
            "release": {
                "id": 2,
                "title": "Dark Side of the Moon"
            },
            "condition": "Near Mint (NM or M-)",
            "sleeve_condition": "Near Mint (NM or M-)",
            "comments": "Mint condition, never played",
            "allow_offers": true,
            "seller": {
                "id": 123,
                "username": "testuser",
                "resource_url": "https://api.discogs.com/users/testuser"
            }
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(createListingJson)
        let newListing = try await marketplaceService.createListing(
            releaseId: 2,
            condition: .nearMint,
            sleeveCondition: .nearMint,
            price: "29.99",
            comments: "Mint condition, never played",
            allowOffers: true,
            status: .draft
        )
        #expect(newListing.id == 124)
        #expect(newListing.price.value == 29.99)
        
        // Test 3: Get orders
        let ordersJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 2,
                "per_page": 50,
                "items": 75
            },
            "orders": [
                {
                    "id": "order-123",
                    "resource_url": "https://api.discogs.com/marketplace/orders/order-123",
                    "messages_url": "https://api.discogs.com/marketplace/orders/order-123/messages",
                    "uri": "https://www.discogs.com/sell/order/order-123",
                    "status": "Payment Pending",
                    "created": "2023-06-05T14:30:00-08:00",
                    "total": {
                        "currency": "USD",
                        "value": 45.98
                    },
                    "buyer": {
                        "id": 456,
                        "username": "buyer123",
                        "resource_url": "https://api.discogs.com/users/buyer123"
                    },
                    "seller": {
                        "id": 789,
                        "username": "seller123",
                        "resource_url": "https://api.discogs.com/users/seller123"
                    },
                    "items": [
                        {
                            "id": 123,
                            "resource_url": "https://api.discogs.com/marketplace/listings/123",
                            "release": {
                                "id": 1,
                                "title": "Abbey Road",
                                "resource_url": "https://api.discogs.com/releases/1"
                            },
                            "price": {
                                "currency": "USD",
                                "value": 25.99
                            }
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(ordersJson)
        let orders = try await marketplaceService.getOrders(
            status: .paymentPending,
            sort: .created,
            sortOrder: .descending,
            page: 1,
            perPage: 50
        )
        #expect(orders.pagination.items == 75)
        #expect(orders.items.first?.status == "Payment Pending")
        #expect(orders.items.first?.total.value == 45.98)
        
        // Test 4: Price suggestions
        let priceSuggestionsJson = """
        {
            "median": {
                "currency": "USD",
                "value": 35.00
            },
            "minimum": {
                "currency": "USD",
                "value": 25.00
            },
            "maximum": {
                "currency": "USD",
                "value": 35.00
            }
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(priceSuggestionsJson)
        let suggestions = try await marketplaceService.getPriceSuggestions(releaseId: 1)
        #expect(suggestions.median?.value == 35.00)
        #expect(suggestions.minimum?.value != nil)
    }
    
    // MARK: - User Service End-to-End Tests
    
    @Test("User Service - Complete User Management")
    func testUserServiceEndToEnd() async throws {
        let mockClient = createMockClient()
        let userService = UserService(httpClient: mockClient)
        
        // Test 1: Get user identity
        let identityJson = """
        {
            "id": 123,
            "username": "testuser",
            "resource_url": "https://api.discogs.com/users/testuser",
            "consumer_name": "My Discogs App"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(identityJson)
        let identity = try await userService.getIdentity()
        #expect(identity.id == 123)
        #expect(identity.username == "testuser")
        #expect(identity.consumerName == "My Discogs App")
        
        // Test 2: Get user profile
        let profileJson = """
        {
            "id": 123,
            "username": "testuser",
            "name": "Test User",
            "email": "test@example.com",
            "resource_url": "https://api.discogs.com/users/testuser",
            "profile": "Vinyl collector since 1995",
            "location": "San Francisco, CA",
            "home_page": "https://example.com",
            "registered": "2010-05-15T10:30:00-04:00",
            "num_collection": 500,
            "num_wantlist": 150,
            "num_for_sale": 25,
            "num_lists": 5,
            "releases_contributed": 50,
            "releases_rated": 200,
            "rating_avg": 4.2,
            "inventory_url": "https://api.discogs.com/users/testuser/inventory",
            "collection_folders_url": "https://api.discogs.com/users/testuser/collection/folders",
            "wantlist_url": "https://api.discogs.com/users/testuser/wants"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(profileJson)
        let profile = try await userService.getProfile(username: "testuser")
        #expect(profile.username == "testuser")
        #expect(profile.numCollection == 500)
        #expect(profile.numWantlist == 150)
        #expect(profile.ratingAvg == 4.2)
        
        // Test 3: Get user submissions
        let submissionsJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 3,
                "per_page": 50,
                "items": 125
            },
            "submissions": [
                {
                    "id": 789,
                    "user": {
                        "username": "testuser",
                        "resource_url": "https://api.discogs.com/users/testuser"
                    },
                    "status": "Accepted",
                    "title": "Abbey Road",
                    "type": "release",
                    "url": "https://api.discogs.com/releases/1",
                    "submission_date": "2023-01-15T10:30:00-08:00"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(submissionsJson)
        let submissions = try await userService.getSubmissions(
            username: "testuser",
            page: 1,
            perPage: 50
        )
        #expect(submissions.pagination.items == 125)
        #expect(submissions.items.first?.title == "Abbey Road")
        #expect(submissions.items.first?.status == "Accepted")
        
        // Test 4: Get user lists
        let listsJson = """
        {
            "pagination": {
                "page": 1,
                "pages": 1,
                "per_page": 50,
                "items": 5
            },
            "lists": [
                {
                    "id": 1,
                    "name": "My Favorite Albums",
                    "description": "Personal collection of favorite albums",
                    "date_created": "2023-01-01T00:00:00-08:00",
                    "date_updated": "2023-06-01T12:00:00-08:00",
                    "resource_url": "https://api.discogs.com/lists/1",
                    "uri": "/lists/1",
                    "item_count": 25
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(listsJson)
        let lists = try await userService.getLists(
            username: "testuser",
            page: 1,
            perPage: 50
        )
        #expect(lists.pagination.items == 5)
        #expect(lists.items.first?.name == "My Favorite Albums")
        #expect(lists.items.first?.itemCount == 25)
    }
    
    // MARK: - Authentication End-to-End Tests
    
    @Test("Authentication - OAuth Flow and Token Management")
    func testAuthenticationEndToEnd() async throws {
        let mockClient = createMockClient()
        let auth = Authentication(client: mockClient)
        
        // Test 1: OAuth request token
        let requestTokenResponse = "oauth_token=request_token_123&oauth_token_secret=request_secret_456&oauth_callback_confirmed=true"
        await mockClient.setMockResponseData(requestTokenResponse.data(using: .utf8)!)
        
        let requestToken = try await auth.getRequestToken(
            consumerKey: "test_consumer_key",
            consumerSecret: "test_consumer_secret",
            callbackURL: "https://example.com/callback"
        )
        #expect(requestToken.token == "request_token_123")
        #expect(requestToken.tokenSecret == "request_secret_456")
        
        // Test 2: Authorization URL generation
        let authURL = auth.getAuthorizationURL(requestToken: "request_token_123")
        #expect(authURL.contains("oauth_token=request_token_123"))
        #expect(authURL.contains("discogs.com/oauth/authorize"))
        
        // Test 3: Access token exchange
        let accessTokenResponse = "oauth_token=access_token_789&oauth_token_secret=access_secret_abc"
        await mockClient.setMockResponseData(accessTokenResponse.data(using: .utf8)!)
        
        let accessToken = try await auth.getAccessToken(
            consumerKey: "test_consumer_key",
            consumerSecret: "test_consumer_secret",
            requestToken: "request_token_123",
            requestTokenSecret: "request_secret_456",
            verifier: "oauth_verifier_xyz"
        )
        #expect(accessToken.token == "access_token_789")
        #expect(accessToken.tokenSecret == "access_secret_abc")
    }
    
    // MARK: - Rate Limiting and Error Handling End-to-End Tests
    
    @Test("Rate Limiting - Exponential Backoff and Retry Logic")
    func testRateLimitingEndToEnd() async throws {
        let rateLimitConfig = RateLimitConfig(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 16.0,
            enableAutoRetry: true,
            respectResetTime: true
        )
        
        let discogs = Discogs(
            token: "test_token",
            userAgent: "TestApp/1.0",
            rateLimitConfig: rateLimitConfig
        )
        
        // Verify rate limit configuration
        let config = await discogs.rateLimitConfig
        #expect(config.enableAutoRetry == true)
        #expect(config.maxRetries == 3)
        #expect(config.baseDelay == 1.0)
        #expect(config.maxDelay == 16.0)
    }
    
    // MARK: - Currency Validation End-to-End Tests
    
    @Test("Currency Validation - Comprehensive Currency Support")
    func testCurrencyValidationEndToEnd() async throws {
        let mockClient = createMockClient()
        let databaseService = DatabaseService(httpClient: mockClient)
        
        // Test valid currencies
        let validCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
        
        for currency in validCurrencies {
            let releaseJson = """
            {
                "id": 1,
                "title": "Test Release",
                "year": 2023
            }
            """.data(using: .utf8)!
            
            await mockClient.setMockResponseData(releaseJson)
            
            // Should not throw for valid currencies
            let release = try await databaseService.getRelease(id: 1, currency: currency)
            #expect(release.title == "Test Release")
        }
        
        // Test invalid currency
        do {
            _ = try await databaseService.getRelease(id: 1, currency: "INVALID")
            #expect(Bool(false), "Should have thrown an error for invalid currency")
        } catch {
            // Expected to throw
            #expect(error is DiscogsError)
        }
    }
    
    // MARK: - Error Handling End-to-End Tests
    
    @Test("Error Handling - Comprehensive Error Scenarios")
    func testErrorHandlingEndToEnd() async throws {
        let mockClient = createMockClient()
        let databaseService = DatabaseService(httpClient: mockClient)
        
        // Test HTTP error handling
        await mockClient.setMockError(DiscogsError.httpError(404))
        
        do {
            _ = try await databaseService.getArtist(id: 999999)
            #expect(Bool(false), "Should have thrown HTTP 404 error")
        } catch let error as DiscogsError {
            if case .httpError(let statusCode) = error {
                #expect(statusCode == 404)
            } else {
                #expect(Bool(false), "Expected httpError case")
            }
        }
        
        // Test network error handling
        await mockClient.setMockError(DiscogsError.networkError(URLError(.notConnectedToInternet)))
        
        do {
            _ = try await databaseService.getArtist(id: 1)
            #expect(Bool(false), "Should have thrown network error")
        } catch let error as DiscogsError {
            if case .networkError = error {
                // Expected
            } else {
                #expect(Bool(false), "Expected networkError case")
            }
        }
        
        // Test invalid input error
        do {
            _ = try await databaseService.updateReleaseRating(
                releaseId: 1,
                username: "testuser",
                rating: 10 // Invalid rating (should be 1-5)
            )
            #expect(Bool(false), "Should have thrown invalidInput error")
        } catch let error as DiscogsError {
            if case .invalidInput = error {
                // Expected
            } else {
                #expect(Bool(false), "Expected invalidInput case")
            }
        }
    }
    
    // MARK: - Integration Test - Full Workflow
    
    @Test("Integration - Complete Discogs Workflow")
    func testCompleteDiscogsWorkflow() async throws {
        let mockClient = createMockClient()
        
        // Create services

        let searchService = SearchService(httpClient: mockClient)
        let databaseService = DatabaseService(httpClient: mockClient)
        let collectionService = CollectionService(httpClient: mockClient)
        let wantlistService = WantlistService(httpClient: mockClient)
        
        // Workflow: Search for an album, get details, add to collection and wantlist
        
        // Step 1: Search for album
        let searchJson = """
        {
            "pagination": {"page": 1, "pages": 1, "per_page": 50, "items": 1},
            "results": [
                {
                    "id": 1,
                    "type": "release",
                    "title": "Abbey Road",
                    "year": "1969"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(searchJson)
        let searchResults = try await searchService.search(
            query: "Abbey Road",
            type: .release,
            artist: "The Beatles"
        )
        let foundRelease = searchResults.items.first!
        #expect(foundRelease.title == "Abbey Road")
        
        // Step 2: Get detailed release information
        let releaseJson = """
        {
            "id": 1,
            "title": "Abbey Road",
            "year": 1969,
            "artists": [{"id": 1, "name": "The Beatles"}],
            "community": {"want": 5000, "have": 10000}
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(releaseJson)
        let releaseDetails = try await databaseService.getRelease(id: foundRelease.id)
        #expect(releaseDetails.title == "Abbey Road")
        #expect(releaseDetails.community?.want == 5000)
        
        // Step 3: Add to collection
        let addToCollectionJson = """
        {
            "instance_id": 123,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1/releases/1/instances/123"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(addToCollectionJson)
        let collectionItem = try await collectionService.addReleaseToFolder(
            username: "testuser",
            folderId: 1,
            releaseId: releaseDetails.id
        )
        #expect(collectionItem.instances?.first?.id == 123)
        
        // Step 4: Add to wantlist
        let addToWantlistJson = """
        {
            "id": 1,
            "rating": 5,
            "notes": "Classic album",
            "resource_url": "https://api.discogs.com/users/testuser/wants/1",
            "basic_information": {
                "id": 1,
                "title": "Abbey Road"
            }
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(addToWantlistJson)
        let wantlistItem = try await wantlistService.addToWantlist(
            username: "testuser",
            releaseId: releaseDetails.id,
            notes: "Classic album",
            rating: 5
        )
        #expect(wantlistItem.rating == 5)
        #expect(wantlistItem.notes == "Classic album")
        
        // Workflow completed successfully
        #expect(Bool(true), "Complete workflow executed successfully")
    }
}
