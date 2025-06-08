import Foundation
import Testing
@testable import Discogs

@Suite("User Service Tests")
struct UserServiceTests {
    
    // Helper function to create a decoder with the same settings as the real implementation
    private    func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Don't apply convertFromSnakeCase since models have explicit CodingKeys mappings
        return decoder
    }
    
    @Test("UserService initializes with httpClient")
    func testInitialization() {
        // Given
        let mockClient = MockHTTPClient()
        
        // When
        let _ = UserService(httpClient: mockClient)
        
        // Then
        #expect(true)
    }
    
    @Test("UserService initializes with client for backward compatibility")
    func testLegacyInitialization() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        
        // When
        let _ = UserService(client: discogs)
        
        // Then
        #expect(true)
    }
    
    @Test("UserService conforms to Sendable")
    func testSendableConformance() {
        // Given
        let discogs = Discogs(token: "test", userAgent: "test")
        let service = UserService(client: discogs)
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = service
        }
    }
    
    @Test("Get user identity")
    func testGetUserIdentity() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = UserService(httpClient: mockClient)
        
        let mockResponse = """
        {
            "id": 123456,
            "username": "testuser",
            "resource_url": "https://api.discogs.com/users/testuser",
            "consumer_name": "Test Consumer"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let userIdentity = try await service.getIdentity()
        
        // Then
        #expect(userIdentity.id == 123456)
        #expect(userIdentity.username == "testuser")
        #expect(userIdentity.resourceUrl == "https://api.discogs.com/users/testuser")
    }
    
    @Test("Get user profile")
    func testGetUserProfile() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = UserService(httpClient: mockClient)
        let username = "testuser"
        
        let mockResponse = """
        {
            "id": 123456,
            "username": "testuser",
            "name": "Test User",
            "email": "test@example.com",
            "resource_url": "https://api.discogs.com/users/testuser",
            "location": "San Francisco, CA",
            "profile": "Music lover and collector",
            "home_page": "https://example.com",
            "num_for_sale": 50,
            "num_in_wantlist": 150,
            "num_in_collection": 300
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let userProfile = try await service.getProfile(username: username)
        
        // Then
        #expect(userProfile.id == 123456)
        #expect(userProfile.username == "testuser")
        #expect(userProfile.name == "Test User")
        #expect(userProfile.location == "San Francisco, CA")
    }
    
    @Test("Update user profile")
    func testUpdateUserProfile() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = UserService(httpClient: mockClient)
        let username = "testuser"
        let name = "Updated Name"
        let homePage = "https://example.com"
        let location = "New York, NY"
        let profile = "Updated profile description"
        
        let mockResponse = """
        {
            "id": 123456,
            "username": "testuser",
            "name": "Updated Name",
            "email": "test@example.com",
            "resource_url": "https://api.discogs.com/users/testuser",
            "location": "New York, NY",
            "profile": "Updated profile description",
            "home_page": "https://example.com"
        }
        """.data(using: .utf8)!
        
        await mockClient.setMockResponseData(mockResponse)
        
        // When
        let updatedProfile = try await service.editProfile(
            username: username,
            name: name,
            homePage: homePage,
            location: location,
            profile: profile
        )
        
        // Then
        #expect(updatedProfile.name == "Updated Name")
        #expect(updatedProfile.homePage == "https://example.com")
        #expect(updatedProfile.location == "New York, NY")
        #expect(updatedProfile.profile == "Updated profile description")
        
        // Verify the request was made correctly
        let request = try #require(await mockClient.lastRequest)
        #expect(request.method == "POST")
        #expect(request.url.absoluteString == "https://api.discogs.com/users/\(username)")
    }
}
