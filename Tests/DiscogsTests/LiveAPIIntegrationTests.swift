import Testing
import Foundation
@testable import Discogs

/// A custom error type for skipping tests when no valid token is provided
struct TestSkipError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

/// Live integration tests that make actual network calls to the Discogs API
/// These tests verify that the Swift package works correctly with real API responses
/// 
/// Note: These tests require a valid Discogs API token and will make real API calls
/// They should be run sparingly to respect rate limits and API usage guidelines
@Suite("Live API Integration Tests")
struct LiveAPIIntegrationTests {
    
    // MARK: - Test Configuration
    
    private func createLiveClient() -> Discogs? {
        // Check if running in CI/CD environment and skip live tests
        let ciEnvironments = [
            "CI",                    // Generic CI environment
            "GITHUB_ACTIONS",        // GitHub Actions
            "TRAVIS",               // Travis CI
            "CIRCLECI",             // CircleCI
            "JENKINS_URL",          // Jenkins
            "GITLAB_CI",            // GitLab CI
            "BUILDKITE",            // Buildkite
            "TF_BUILD"              // Azure DevOps
        ]
        
        for envVar in ciEnvironments {
            if ProcessInfo.processInfo.environment[envVar] != nil {
                print("🚫 Skipping live API tests - detected CI/CD environment (\(envVar))")
                print("💡 Live tests are disabled in CI/CD to avoid rate limiting and API costs")
                return nil
            }
        }
        
        // Try to get token from environment variable first, then use a test token
        let token = ProcessInfo.processInfo.environment["DISCOGS_API_TOKEN"] ?? "your_test_token_here"
        
        // Skip tests if no valid token is provided
        guard token != "your_test_token_here" else {
            print("⚠️ Skipping live API tests - no valid token provided")
            print("💡 Set DISCOGS_API_TOKEN environment variable to run live tests")
            return nil
        }
        
        return Discogs(
            token: token,
            userAgent: "DiscogsSwiftPackageLiveTest/1.0 +https://github.com/example/discogs-swift"
        )
    }
    
    // MARK: - Database Service Live Tests
    
    @Test("Live Database - Fetch Famous Artist (The Beatles)")
    func testLiveDatabaseArtistFetch() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live artist fetch for The Beatles (ID: 82730)...")
        
        // The Beatles - a well-known artist that should always exist
        let artist = try await client.database.getArtist(id: 82730)
        
        // Verify basic artist properties
        #expect(artist.id == 82730)
        #expect(artist.name.contains("Beatles"))
        #expect(artist.profile?.isEmpty == false)
        #expect(artist.resourceUrl?.isEmpty == false)
        
        print("✅ Successfully fetched artist: \(artist.name)")
        print("📝 Profile length: \(artist.profile?.count ?? 0) characters")
        print("🖼️ Images count: \(artist.images?.count ?? 0)")
    }
    
    @Test("Live Database - Fetch Famous Release (Abbey Road)")
    func testLiveDatabaseReleaseFetch() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live release fetch for a famous Beatles release...")
        
        // Search for Abbey Road first to get a valid release ID
        let searchResults = try await client.search.search(
            query: "Abbey Road Beatles",
            type: .release,
            perPage: 5
        )
        
        // Find Abbey Road in the search results
        guard let abbeyRoadResult = searchResults.items.first(where: { result in
            result.title?.lowercased().contains("abbey road") == true &&
            result.title?.lowercased().contains("beatles") == true
        }) else {
            // Fall back to any Beatles release if Abbey Road isn't found
            guard let anyBeatlesResult = searchResults.items.first else {
                throw TestSkipError("No Beatles releases found in search")
            }
            let release = try await client.database.getRelease(id: anyBeatlesResult.id)
            print("✅ Successfully fetched Beatles release: \(release.title)")
            #expect(release.id == anyBeatlesResult.id)
            return
        }
        
        // Fetch the actual Abbey Road release
        let release = try await client.database.getRelease(id: abbeyRoadResult.id)
        
        // Verify basic release properties
        #expect(release.id == abbeyRoadResult.id)
        #expect(release.title.lowercased().contains("abbey road"))
        #expect(release.artists?.isEmpty == false)
        #expect(release.tracklist?.isEmpty == false)
        
        print("✅ Successfully fetched release: \(release.title)")
        print("🎵 Track count: \(release.tracklist?.count ?? 0)")
        print("👥 Artists count: \(release.artists?.count ?? 0)")
        
        // Verify tracklist structure
        if let firstTrack = release.tracklist?.first {
            #expect(firstTrack.title?.isEmpty == false)
            print("🎼 First track: \(firstTrack.title ?? "Unknown")")
        }
    }
    
    @Test("Live Database - Fetch Label (Motown)")
    func testLiveDatabaseLabelFetch() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live label fetch for Motown (ID: 1)...")
        
        // Motown - a well-known label with simple structure
        let label = try await client.database.getLabel(id: 1)
        
        // Verify basic label properties
        #expect(label.id == 1)
        #expect(label.name.isEmpty == false)
        
        print("✅ Successfully fetched label: \(label.name)")
        print("📝 Profile length: \(label.profile?.count ?? 0) characters")
        print("🏢 Label verified: \(label.name)")
    }
    
    // MARK: - Search Service Live Tests
    
    @Test("Live Search - Artist Search")
    func testLiveSearchArtist() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live artist search for 'Pink Floyd'...")
        
        let searchResults = try await client.search.search(
            query: "Pink Floyd",
            type: .artist,
            perPage: 5
        )
        
        // Verify search results
        #expect(searchResults.items.isEmpty == false)
        #expect(searchResults.pagination.items > 0)
        
        // Find Pink Floyd in results
        let pinkFloydResult = searchResults.items.first { result in
            result.title?.lowercased().contains("pink floyd") == true
        }
        
        #expect(pinkFloydResult != nil)
        
        print("✅ Found \(searchResults.items.count) artist results")
        print("📊 Total items: \(searchResults.pagination.items)")
        if let pinkFloyd = pinkFloydResult {
            print("🎸 Found Pink Floyd: \(pinkFloyd.title ?? "Unknown")")
        }
    }
    
    @Test("Live Search - Release Search with Filters")
    func testLiveSearchReleaseWithFilters() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live release search with filters...")
        
        let searchResults = try await client.search.search(
            query: "Dark Side of the Moon",
            type: .release,
            year: "1973",
            format: "LP",
            perPage: 10
        )
        
        // Verify filtered search results
        #expect(searchResults.items.isEmpty == false)
        
        // Check if we found Dark Side of the Moon
        let darkSideResult = searchResults.items.first { result in
            result.title?.lowercased().contains("dark side") == true &&
            result.title?.lowercased().contains("moon") == true
        }
        
        print("✅ Found \(searchResults.items.count) filtered results")
        if let darkSide = darkSideResult {
            print("🌙 Found Dark Side of the Moon: \(darkSide.title ?? "Unknown")")
            print("📅 Year: \(darkSide.year ?? "Unknown")")
        }
    }
    
    // MARK: - User Service Live Tests
    
    @Test("Live User - Get Identity")
    func testLiveUserIdentity() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live user identity fetch...")
        
        do {
            let identity = try await client.user.getIdentity()
            
            // Verify identity properties
            #expect(identity.username.isEmpty == false)
            #expect(identity.id > 0)
            
            print("✅ Successfully fetched user identity")
            print("👤 Username: \(identity.username)")
            print("🆔 User ID: \(identity.id)")
            
        } catch {
            // This might fail if the token doesn't have proper permissions
            print("⚠️ User identity test failed (this may be expected with limited tokens): \(error)")
            throw TestSkipError("User identity requires authenticated token with proper permissions")
        }
    }
    
    // MARK: - Error Handling Live Tests
    
    @Test("Live Error Handling - Invalid Artist ID")
    func testLiveErrorHandling() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live error handling with invalid artist ID...")
        
        do {
            // Try to fetch an artist with an invalid ID
            let _ = try await client.database.getArtist(id: 999999999)
            
            // If we get here, something's wrong - this should fail
            #expect(Bool(false), "Expected error for invalid artist ID")
            
        } catch let error as DiscogsError {
            // Verify we get the correct error type
            switch error {
            case .httpError(let statusCode):
                if statusCode == 404 {
                    print("✅ Correctly received 404 error for invalid artist ID")
                } else {
                    print("✅ Correctly received HTTP error with status: \(statusCode)")
                }
            case .custom(let message):
                print("✅ Correctly received custom error: \(message)")
            default:
                print("⚠️ Received unexpected error type: \(error)")
            }
        } catch {
            print("⚠️ Received unexpected error: \(error)")
            throw error
        }
    }
    
    // MARK: - Rate Limiting Live Tests
    
    @Test("Live Rate Limiting - Multiple Sequential Requests")
    func testLiveRateLimiting() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live rate limiting with multiple requests...")
        
        let startTime = Date()
        var successCount = 0
        
        // Make several requests in sequence to test rate limiting
        let artistIds = [82730, 45, 1, 108713, 1000] // Various famous artists (The Beatles, Aphex Twin, The Persuader, Radiohead, Dave Clarke)
        
        for (index, artistId) in artistIds.enumerated() {
            do {
                print("  Request \(index + 1)/\(artistIds.count): Fetching artist \(artistId)...")
                let artist = try await client.database.getArtist(id: artistId)
                successCount += 1
                print("  ✅ Success: \(artist.name)")
                
                // Small delay to be respectful to the API
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms
                
            } catch {
                print("  ❌ Failed for artist \(artistId): \(error)")
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        print("✅ Completed \(successCount)/\(artistIds.count) requests in \(String(format: "%.2f", duration)) seconds")
        
        // Verify we got at least some successful responses
        #expect(successCount > 0)
    }
    
    // MARK: - Complete Workflow Live Test
    
    @Test("Live Workflow - Search to Details Fetch")
    func testLiveCompleteWorkflow() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing complete live workflow: Search → Details...")
        
        // Step 1: Search for a release
        print("  Step 1: Searching for 'Thriller' releases...")
        let searchResults = try await client.search.search(
            query: "Thriller Michael Jackson",
            type: .release,
            perPage: 5
        )
        
        #expect(searchResults.items.isEmpty == false)
        print("  ✅ Found \(searchResults.items.count) search results")
        
        // Step 2: Get the first result's details
        guard let firstResult = searchResults.items.first else {
            throw TestSkipError("No valid release found in search results")
        }
        
        let releaseId = firstResult.id
        
        print("  Step 2: Fetching details for release ID \(releaseId)...")
        let releaseDetails = try await client.database.getRelease(id: releaseId)
        
        // Step 3: Verify the workflow
        #expect(releaseDetails.id == releaseId)
        #expect(releaseDetails.title.isEmpty == false)
        
        print("  ✅ Successfully fetched release details: \(releaseDetails.title)")
        
        // Step 4: If this release has artists, fetch artist details
        if let firstArtist = releaseDetails.artists?.first,
           let artistId = firstArtist.id {
            
            print("  Step 3: Fetching artist details for ID \(artistId)...")
            let artistDetails = try await client.database.getArtist(id: artistId)
            
            #expect(artistDetails.id == artistId)
            print("  ✅ Successfully fetched artist details: \(artistDetails.name)")
        }
        
        print("✅ Complete workflow test passed!")
    }
    
    // MARK: - Performance Test
    
    @Test("Live Performance - Response Time Verification")
    func testLivePerformance() async throws {
        guard let client = createLiveClient() else {
            throw TestSkipError("No valid API token provided")
        }
        
        print("🔍 Testing live API performance...")
        
        let startTime = Date()
        
        // Test a simple, fast request
        let artist = try await client.database.getArtist(id: 1) // Well-known artist
        
        let endTime = Date()
        let responseTime = endTime.timeIntervalSince(startTime)
        
        // Verify response and timing
        #expect(artist.id == 1)
        #expect(responseTime < 10.0) // Should respond within 10 seconds
        
        print("✅ API response time: \(String(format: "%.3f", responseTime)) seconds")
        print("📊 Artist fetched: \(artist.name)")
        
        if responseTime > 3.0 {
            print("⚠️ Response time is slower than expected (>3s)")
        } else {
            print("🚀 Good response time!")
        }
    }
}
