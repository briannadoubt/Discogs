import Foundation
import Discogs

/// Example demonstrating advanced usage of the Discogs Swift package with dependency injection
@main
struct DiscogsExample {
    static func main() async {
        // Configure your Discogs token and user agent
        let token = "your_discogs_token_here"
        let userAgent = "ExampleApp/1.0 +https://example.com/contact"
        
        do {
            // Example 1: Using the main Discogs client (simplest approach)
            await example1_SimpleUsage(token: token, userAgent: userAgent)
            
            // Example 2: Using dependency injection for better testability
            await example2_DependencyInjection(token: token, userAgent: userAgent)
            
            // Example 3: Using the dependency container
            await example3_DependencyContainer(token: token, userAgent: userAgent)
            
            // Example 4: Custom HTTP client implementation
            await example4_CustomHTTPClient()
            
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Example 1: Simple Usage

extension DiscogsExample {
    static func example1_SimpleUsage(token: String, userAgent: String) async {
        print("\n=== Example 1: Simple Usage ===")
        
        do {
            // Create the main Discogs client
            let discogs = Discogs(token: token, userAgent: userAgent)
            
            // Use services directly from the client
            let release = try await discogs.database.getRelease(id: 1)
            print("Found release: \(release.title)")
            
            // Search for releases
            let searchResults = try await discogs.search.search(query: "Nirvana", type: .release)
            print("Found \(searchResults.results?.count ?? 0) releases")
            
        } catch {
            print("Example 1 error: \(error)")
        }
    }
}

// MARK: - Example 2: Dependency Injection

extension DiscogsExample {
    static func example2_DependencyInjection(token: String, userAgent: String) async {
        print("\n=== Example 2: Dependency Injection ===")
        
        do {
            // Create the HTTP client
            let httpClient = Discogs(token: token, userAgent: userAgent)
            
            // Create services with dependency injection
            let databaseService = DatabaseService(httpClient: httpClient)
            let searchService = SearchService(httpClient: httpClient)
            
            // Use the services
            let artist = try await databaseService.getArtist(id: 1)
            print("Found artist: \(artist.name)")
            
            let searchResults = try await searchService.search(query: "Electronic", type: .release)
            print("Found \(searchResults.results?.count ?? 0) electronic releases")
            
        } catch {
            print("Example 2 error: \(error)")
        }
    }
}

// MARK: - Example 3: Dependency Container

extension DiscogsExample {
    static func example3_DependencyContainer(token: String, userAgent: String) async {
        print("\n=== Example 3: Dependency Container ===")
        
        do {
            // Create and configure the dependency container
            let container = DependencyContainer()
            
            // Register the HTTP client
            let httpClient = Discogs(token: token, userAgent: userAgent)
            await container.register(HTTPClientProtocol.self, instance: httpClient)
            
            // Register services
            let databaseService = DatabaseService(httpClient: httpClient)
            let collectionService = CollectionService(httpClient: httpClient)
            
            await container.register(DatabaseService.self, instance: databaseService)
            await container.register(CollectionService.self, instance: collectionService)
            
            // Use services from container
            if let database = await container.resolve(DatabaseService.self) {
                let label = try await database.getLabel(id: 1)
                print("Found label: \(label.name)")
            }
            
            if let collection = await container.resolve(CollectionService.self) {
                // Note: Replace with actual username
                let folders = try await collection.getFolders(username: "example_user")
                print("User has \(folders.folders?.count ?? 0) collection folders")
            }
            
        } catch {
            print("Example 3 error: \(error)")
        }
    }
}

// MARK: - Example 4: Custom HTTP Client

extension DiscogsExample {
    static func example4_CustomHTTPClient() async {
        print("\n=== Example 4: Custom HTTP Client ===")
        
        // This example shows how you could implement a custom HTTP client
        // For demonstration, we'll use a logging HTTP client wrapper
        
        let baseClient = Discogs(token: "dummy", userAgent: "Example/1.0")
        let loggingClient = LoggingHTTPClient(wrapping: baseClient)
        
        let service = DatabaseService(httpClient: loggingClient)
        
        do {
            // This would log the request details
            let _ = try await service.getRelease(id: 1)
        } catch {
            print("Example 4 error (expected): \(error)")
        }
    }
}

// MARK: - Custom HTTP Client Implementation

/// Example of a custom HTTP client that wraps another client and adds logging
actor LoggingHTTPClient: HTTPClientProtocol {
    private let wrappedClient: HTTPClientProtocol
    
    init(wrapping client: HTTPClientProtocol) {
        self.wrappedClient = client
    }
    
    func performRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: String],
        body: [String: any Sendable]?
    ) async throws -> T {
        print("🌐 Making request to: \(endpoint)")
        print("📝 Method: \(method.rawValue)")
        print("🔍 Parameters: \(parameters)")
        if let body = body {
            print("📦 Body: \(body)")
        }
        
        let startTime = Date()
        
        do {
            let result: T = try await wrappedClient.performRequest(
                endpoint: endpoint,
                method: method,
                parameters: parameters,
                body: body
            )
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Request completed in \(String(format: "%.2f", duration))s")
            
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("❌ Request failed in \(String(format: "%.2f", duration))s: \(error)")
            throw error
        }
    }
    
    var rateLimit: RateLimit? {
        get async {
            return await wrappedClient.rateLimit
        }
    }
    
    nonisolated var baseURL: URL {
        return wrappedClient.baseURL
    }
    
    nonisolated var userAgent: String {
        return wrappedClient.userAgent
    }
}

// MARK: - Testing Examples

#if DEBUG
extension DiscogsExample {
    /// Example of how to write tests with the new dependency injection system
    static func exampleTesting() async throws {
        print("\n=== Testing Example ===")
        
        // Create a mock HTTP client
        let mockClient = MockHTTPClient()
        
        // Set up mock response
        let mockReleaseJSON = """
        {
            "id": 123,
            "title": "Test Album",
            "year": 2023,
            "artists": [{"name": "Test Artist"}]
        }
        """
        
        await mockClient.setMockResponse(json: mockReleaseJSON)
        
        // Create service with mock client
        let service = DatabaseService(httpClient: mockClient)
        
        // Make request
        let release: Release = try await service.getRelease(id: 123)
        
        // Verify results
        assert(release.id == 123)
        assert(release.title == "Test Album")
        
        // Verify request was made correctly
        let request = await mockClient.getLastRequest()
        assert(request?.url.path.contains("releases/123") == true)
        assert(request?.method == "GET")
        
        print("✅ Test passed: Mock client working correctly")
    }
}
#endif
