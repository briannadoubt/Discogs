import Testing
import Foundation
@testable import Discogs

@Suite("Marketplace Service Tests")
struct MarketplaceServiceTests {
    // Helper method to create isolated test instances
    func createTestInstances() -> (marketplaceService: MarketplaceService, mockClient: MockHTTPClient) {
        let mockClient = MockHTTPClient()
        let marketplaceService = MarketplaceService(httpClient: mockClient)
        return (marketplaceService, mockClient)
    }

    @Test func testInitialization() {
        // Given
        let (_, mockClient) = createTestInstances()
        
        // When
        let service = MarketplaceService(httpClient: mockClient)
        
        // Then
        #expect(service.httpClient is MockHTTPClient)
    }
    
    @Test func testSendableConformance() {
        // Given
        let (marketplaceService, _) = createTestInstances()
        
        // When/Then - This test passes if the code compiles
        Task {
            // Perform some async operation with service if necessary
            // For now, just ensuring it can be used in a Task
            _ = marketplaceService 
        }
    }
    
    @Test func testGetInventory() async throws {
        // Given
        let (marketplaceService, mockClient) = createTestInstances()
        let username = "seller123"
        let page = 1
        let perPage = 50
        
        let mockData = """
        {
            "pagination": {"page": 1, "pages": 1, "per_page": 50, "items": 0, "urls": {}},
            "items": []
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockData)
        
        // When
        let _ = try await marketplaceService.getInventory(
            username: username,
            sort: .listed, 
            sortOrder: .ascending,
            page: page,
            perPage: perPage
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("users/\(username)/inventory"))
        #expect(urlString.contains("page=\(page)"))
        #expect(urlString.contains("per_page=\(perPage)"))
        #expect(urlString.contains("sort=listed"))
        #expect(urlString.contains("sort_order=asc"))
        #expect(request.method == "GET")
    }
    
    @Test func testGetListing() async throws {
        // Given
        let (marketplaceService, mockClient) = createTestInstances()
        let listingId = 123456
        
        let mockData = """
        {
            "id": \(listingId),
            "status": "For Sale",
            "condition": "Near Mint (NM or M-)",
            "sleeve_condition": "Very Good Plus (VG+)",
            "price": { "value": 22.50, "currency": "EUR" },
            "allow_offers": true,
            "audio": false,
            "seller": { "id": 1, "username": "seller123", "resource_url": "https://api.discogs.com/users/seller123"},
            "release": { "id": 1, "title": "Test Release", "description": "Test Release", "resource_url": "https://api.discogs.com/releases/1"},
            "resource_url": "https://api.discogs.com/marketplace/listings/\(listingId)",
            "uri": "https://www.discogs.com/sell/item/\(listingId)",
            "release_id": 1
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockData)
        
        // When
        let _ = try await marketplaceService.getListing(listingId: listingId)
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("marketplace/listings/\(listingId)"))
        #expect(request.method == "GET")
    }
    
    @Test func testGetInventory_Success() async throws {
        // Given
        let (marketplaceService, mockClient) = createTestInstances()
        let username = "seller123"
        let page = 1
        let perPage = 10
        
        let mockData = """
        {
            "pagination": {"page": 1, "pages": 1, "per_page": 10, "items": 1, "urls": {}},
            "items": [
                {
                    "id": 123456,
                    "status": "For Sale",
                    "condition": "Near Mint (NM or M-)",
                    "sleeve_condition": "Very Good Plus (VG+)",
                    "price": { "value": 22.50, "currency": "EUR" },
                    "allow_offers": true,
                    "audio": false,
                    "seller": { "id": 1, "username": "seller123", "resource_url": "https://api.discogs.com/users/seller123"},
                    "release": { "id": 1, "title": "Test Release", "description": "Test Release", "resource_url": "https://api.discogs.com/releases/1"},
                    "resource_url": "https://api.discogs.com/marketplace/listings/123456",
                    "uri": "https://www.discogs.com/sell/item/123456",
                    "release_id": 1
                }
            ]
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockData)
        
        // When
        let result = try await marketplaceService.getInventory(
            username: username,
            sort: .listed,
            sortOrder: .ascending,
            page: page,
            perPage: perPage
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.method == "GET")
        #expect(result.items.count == 1)
        #expect(result.pagination.page == 1)
        #expect(result.pagination.perPage == 10)
    }
    
    @Test func testGetOrders() async throws {
        // Given
        let (marketplaceService, mockClient) = createTestInstances()
        let page = 1
        let perPage = 50
        
        let mockData = """
        {
            "pagination": {"page": 1, "pages": 1, "per_page": 50, "items": 0, "urls": {}},
            "orders": []
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockData)
        
        // When
        let _ = try await marketplaceService.getOrders(
            status: nil,
            sort: .id,
            sortOrder: .descending,
            page: page,
            perPage: perPage
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        let urlString = request.url.absoluteString
        
        #expect(urlString.contains("marketplace/orders"))
        #expect(urlString.contains("page=\(page)"))
        #expect(urlString.contains("per_page=\(perPage)"))
        #expect(urlString.contains("sort=id"))
        #expect(urlString.contains("sort_order=desc"))
        #expect(request.method == "GET")
    }
    
    @Test func testEditListing() async throws {
        // Given
        let (marketplaceService, mockClient) = createTestInstances()
        let listingId = 123456
        let conditionString = "Near Mint (NM or M-)"
        let priceValue = 25.99
        
        guard let itemCondition = MarketplaceService.ItemCondition(rawValue: conditionString) else {
            Issue.record("Failed to create ItemCondition from raw value")
            return
        }
        
        let mockData = """
        {
            "id": \(listingId),
            "status": "For Sale",
            "condition": "\(conditionString)",
            "sleeve_condition": "Very Good Plus (VG+)",
            "price": { "value": \(priceValue), "currency": "USD" },
            "allow_offers": true,
            "audio": false,
            "seller": { "id": 1, "username": "seller123", "resource_url": "https://api.discogs.com/users/seller123"},
            "release": { "id": 1, "title": "Test Release", "description": "Test Release", "resource_url": "https://api.discogs.com/releases/1"},
            "resource_url": "https://api.discogs.com/marketplace/listings/\(listingId)",
            "uri": "https://www.discogs.com/sell/item/\(listingId)",
            "release_id": 1
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockData)
        
        // When
        let _ = try await marketplaceService.editListing(
            listingId: listingId,
            condition: itemCondition,
            price: String(priceValue)
        )
        
        // Then
        let request = try #require(await mockClient.lastRequest)
        #expect(request.url.path.contains("marketplace/listings/\(listingId)"))
        #expect(request.method == "POST")
        
        if let body = request.body,
           let bodyData = try? JSONSerialization.data(withJSONObject: body),
           let bodyDict = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyDict["condition"] as? String == conditionString)
            #expect(bodyDict["price"] as? String == String(priceValue))
        }
    }
}
