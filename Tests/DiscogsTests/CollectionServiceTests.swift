import Foundation
import Testing
@testable import Discogs

@Suite("Collection Service Tests")
struct CollectionServiceTests {
    
    // Helper function to create a decoder with the same settings as the real implementation
    private    func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Don't apply convertFromSnakeCase since models have explicit CodingKeys mappings
        return decoder
    }
    
    @Test("CollectionService initializes with httpClient")
    func testInitialization() {
        // Given
        let mockClient = MockHTTPClient()
        
        // When
        let _ = CollectionService(httpClient: mockClient)
        
        // Then
        #expect(true)
    }
    
    @Test("CollectionService initializes with client for backward compatibility")
    func testLegacyInitialization() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When
        let _ = CollectionService(client: discogs)
        
        // Then
        #expect(true)
    }
    
    @Test("CollectionService conforms to Sendable")
    func testSendableConformance() {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = service
        }
    }
    
    @Test("Get collection folders for user")
    func testGetCollectionFolders() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let mockResponse = """
        {
            "folders": [
                {
                    "id": 0,
                    "name": "All",
                    "count": 100,
                    "resource_url": "https://api.discogs.com/users/testuser/collection/folders/0"
                },
                {
                    "id": 1,
                    "name": "Uncategorized",
                    "count": 50,
                    "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1"
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.getFolders(username: username)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders"))
        #expect(request.method == "GET")
    }
    
    @Test("Create new collection folder")
    func testCreateCollectionFolder() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderName = "New Folder"
        
        let mockResponse = """
        {
            "id": 3,
            "name": "New Folder",
            "count": 0,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/3"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.createFolder(username: username, name: folderName)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders"))
        #expect(request.method == "POST")
        
        if let bodyData = request.body?["name"] as? String {
            #expect(bodyData == folderName)
        } else {
            #expect(Bool(false), "Request body does not contain folder name or is not a string")
        }
    }
    
    @Test("Get collection folder by ID")
    func testGetCollectionFolderById() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderId = 1
        
        let mockResponse = """
        {
            "id": 1,
            "name": "Uncategorized",
            "count": 50,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.getFolder(username: username, folderId: folderId)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders/\(folderId)"))
        #expect(request.method == "GET")
    }
    
    @Test("Update collection folder name")
    func testUpdateCollectionFolder() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderId = 1
        let newFolderName = "Updated Folder"
        
        let mockResponse = """
        {
            "id": 1,
            "name": "Updated Folder",
            "count": 50,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.updateFolder(username: username, folderId: folderId, name: newFolderName)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders/\(folderId)"))
        #expect(request.method == "POST")
        
        if let bodyData = request.body?["name"] as? String {
            #expect(bodyData == newFolderName)
        } else {
            #expect(Bool(false), "Request body does not contain new folder name or is not a string")
        }
    }
    
    @Test("Delete collection folder")
    func testDeleteCollectionFolder() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderId = 1
        
        await mockClient.setMockResponseData(Data()) // Empty response for DELETE
        
        // When
        let _ = try await service.deleteFolder(username: username, folderId: folderId)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders/\(folderId)"))
        #expect(request.method == "DELETE")
    }
    
    @Test("Get collection items in folder")
    func testGetCollectionItemsInFolder() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderId = 1
        let page = 2
        let perPage = 25
        
        let mockResponse = """
        {
            "pagination": {
                "page": 2,
                "per_page": 25,
                "items": 100,
                "pages": 4
            },
            "releases": [
                {
                    "id": 12345,
                    "instance_id": 67890,
                    "folder_id": 1,
                    "rating": 5,
                    "basic_information": {
                        "id": 12345,
                        "title": "Test Album",
                        "year": 2023,
                        "resource_url": "https://api.discogs.com/releases/12345"
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.getItemsInFolder(
            username: username,
            folderId: folderId,
            page: page,
            perPage: perPage
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("users/\(username)/collection/folders/\(folderId)/releases"))
        #expect(urlString.contains("page=\(page)"))
        #expect(urlString.contains("per_page=\(perPage)"))
        #expect(request.method == "GET")
    }
    
    @Test("Add release to collection folder")
    func testAddReleaseToFolder() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderId = 1
        let releaseId = 12345
        
        let mockResponse = """
        {
            "instance_id": 67890,
            "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1/releases/12345/instances/67890"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.addReleaseToFolder(
            username: username,
            folderId: folderId,
            releaseId: releaseId
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)"))
        #expect(request.method == "POST")
    }
    
    @Test("Delete release instance from folder")
    func testDeleteReleaseInstanceFromFolder() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderId = 1
        let releaseId = 12345
        let instanceId = 67890
        
        await mockClient.setMockResponseData(Data()) // Empty response for DELETE
        
        // When
        let _ = try await service.removeReleaseFromFolder(
            username: username,
            folderId: folderId,
            releaseId: releaseId,
            instanceId: instanceId
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)/instances/\(instanceId)"))
        #expect(request.method == "DELETE")
    }
    
    @Test("Update release instance field")
    func testUpdateReleaseInstanceField() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        let folderId = 1
        let releaseId = 12345
        let instanceId = 67890
        let fieldId = 1
        let newValue = ["Updated notes"]
        
        let mockResponse = """
        {
            "value": ["Updated notes"]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.editItemFieldValue(
            username: username,
            folderId: folderId,
            releaseId: releaseId,
            instanceId: instanceId,
            fieldId: fieldId,
            value: newValue
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)/instances/\(instanceId)/fields/\(fieldId)"))
        #expect(request.method == "POST")
        
        if let bodyData = request.body?["value"] as? [String] {
            #expect(bodyData == newValue)
        } else {
            #expect(Bool(false), "Request body does not contain new value or is not an array of strings")
        }
    }
    
    @Test("Get collection value")
    func testGetCollectionValue() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "testuser"
        
        let mockResponse = """
        {
            "minimum": "$100.00",
            "median": "$250.00",
            "maximum": "$500.00"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let _ = try await service.getValue(username: username)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/value"))
        #expect(request.method == "GET")
    }
    
    // Test error handling for getCollectionFolders
    @Test("Get collection folders for nonexistent user")
    func testGetCollectionFolders_Error_UserNotFound() async throws {
        let mockClient = MockHTTPClient()
        let service = CollectionService(httpClient: mockClient)
        let username = "nonexistentuser"
        let expectedError = DiscogsError.networkError(NSError(domain: "DiscogsError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
        
        await mockClient.setMockError(expectedError)
        
        do {
            _ = try await service.getFolders(username: username)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch {
            // Expected error thrown
            #expect(true)
        }
        
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.absoluteString.contains("users/\(username)/collection/folders"))
    }
    
    @Test("PaginatedResponse handles folders key properly")
    func testPaginatedResponseWithFoldersKey() throws {
        // Given - simulate a response that might accidentally try to decode folders with PaginatedResponse
        let mockResponseWithFolders = """
        {
            "pagination": {
                "page": 1,
                "per_page": 50,
                "items": 2,
                "pages": 1
            },
            "folders": [
                {
                    "id": 0,
                    "name": "All",
                    "count": 100,
                    "resource_url": "https://api.discogs.com/users/testuser/collection/folders/0"
                },
                {
                    "id": 1,
                    "name": "Uncategorized", 
                    "count": 50,
                    "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1"
                }
            ]
        }
        """.data(using: .utf8)!
        
        // When - decode with PaginatedResponse (this should now work with our fix)
        let paginatedFolders = try createDecoder().decode(PaginatedResponse<Folder>.self, from: mockResponseWithFolders)
        
        // Then
        #expect(paginatedFolders.items.count == 2)
        #expect(paginatedFolders.items[0].id == 0)
        #expect(paginatedFolders.items[0].name == "All")
        #expect(paginatedFolders.items[1].id == 1)
        #expect(paginatedFolders.items[1].name == "Uncategorized")
        #expect(paginatedFolders.pagination.page == 1)
        #expect(paginatedFolders.pagination.items == 2)
    }
}

// Helper function to create mock CollectionFolderResponse data
func mockCollectionFolderResponseData() throws -> Data {
    let json = """
    {
        "folders": [
            {
                "id": 0,
                "name": "All",
                "count": 100,
                "resource_url": "https://api.discogs.com/users/testuser/collection/folders/0"
            },
            {
                "id": 1,
                "name": "Uncategorized",
                "count": 50,
                "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1"
            }
        ]
    }
    """
    return Data(json.utf8)
}

// Helper function to create mock CollectionItemResponse data
func mockCollectionItemResponseData() throws -> Data {
    let json = """
    {
        "pagination": {
            "page": 1,
            "pages": 1,
            "per_page": 50,
            "items": 1,
            "urls": {}
        },
        "releases": [
            {
                "id": 12345,
                "instance_id": 67890,
                "folder_id": 1,
                "rating": 4,
                "basic_information": {
                    "id": 12345,
                    "title": "Test Album",
                    "year": 2023,
                    "resource_url": "https://api.discogs.com/releases/12345",
                    "artists": [
                        {
                            "id": 101,
                            "name": "Test Artist",
                            "resource_url": "https://api.discogs.com/artists/101"
                        }
                    ],
                    "formats": [
                        {
                            "name": "Vinyl",
                            "qty": "1",
                            "descriptions": ["LP", "Album"]
                        }
                    ],
                    "labels": [
                        {
                            "id": 202,
                            "name": "Test Label",
                            "catno": "TL001",
                            "resource_url": "https://api.discogs.com/labels/202"
                        }
                    ],
                    "thumb": "https://img.discogs.com/thumb.jpg",
                    "cover_image": "https://img.discogs.com/cover.jpg"
                }
            }
        ]
    }
    """
    return Data(json.utf8)
}

// Helper function to create mock AddReleaseToCollectionResponse data
func mockAddReleaseToCollectionResponseData() throws -> Data {
    let json = """
    {
        "instance_id": 67890,
        "resource_url": "https://api.discogs.com/users/testuser/collection/folders/1/releases/12345/instances/67890"
    }
    """
    return Data(json.utf8)
}

// Helper function to create mock CollectionValueResponse data
func mockCollectionValueResponseData() throws -> Data {
    let json = """
    {
        "minimum": "$100.00",
        "median": "$250.00",
        "maximum": "$500.00"
    }
    """
    return Data(json.utf8)
}
