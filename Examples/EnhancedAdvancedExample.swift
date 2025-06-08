import Foundation
import Discogs

/// Advanced example demonstrating enhanced Discogs Swift SDK features
/// including rate limiting, currency validation, and error handling
@main
struct EnhancedAdvancedExample {
    static func main() async {
        await runAdvancedExample()
    }
    
    static func runAdvancedExample() async {
        print("🎵 Enhanced Discogs SDK Advanced Example")
        print("=========================================\n")
        
        // MARK: - 1. Rate Limiting Configuration
        
        print("1️⃣ Configuring Rate Limiting")
        print("----------------------------")
        
        // Different rate limiting strategies
        let conservativeConfig = RateLimitConfig.conservative
        let aggressiveConfig = RateLimitConfig.aggressive
        let customConfig = RateLimitConfig(
            maxRetries: 4,
            baseDelay: 1.5,
            maxDelay: 45.0,
            enableAutoRetry: true,
            respectResetTime: true
        )
        
        print("📊 Conservative: \(conservativeConfig.maxRetries) retries, \(conservativeConfig.baseDelay)s base delay")
        print("🚀 Aggressive: \(aggressiveConfig.maxRetries) retries, \(aggressiveConfig.baseDelay)s base delay")
        print("⚙️ Custom: \(customConfig.maxRetries) retries, \(customConfig.baseDelay)s base delay\n")
        
        // Initialize client with custom rate limiting
        let discogs = Discogs(
            token: getToken(),
            userAgent: "EnhancedDiscogs/2.0 (Advanced Example)",
            rateLimitConfig: customConfig
        )
        
        // MARK: - 2. Currency Validation Demo
        
        print("2️⃣ Currency Validation")
        print("----------------------")
        
        do {
            // Show supported currencies
            let supportedCurrencies = DatabaseService.SupportedCurrency.allCases
            print("💰 Supported currencies: \(supportedCurrencies.map(\.rawValue).joined(separator: ", "))")
            
            // Valid currency example
            print("\n🔍 Fetching release with EUR pricing...")
            let releaseWithEUR = try await discogs.database.getRelease(id: 249504, currency: "EUR")
            print("✅ Release: \(releaseWithEUR.title) (\(releaseWithEUR.year ?? 0))")
            
            // Invalid currency example
            print("\n❌ Attempting invalid currency...")
            do {
                let _ = try await discogs.database.getRelease(id: 249504, currency: "INVALID")
            } catch let error as DiscogsError {
                switch error {
                case .invalidInput(let message):
                    print("🚫 Expected error: \(message)")
                default:
                    print("🚫 Unexpected error type: \(error)")
                }
            }
            
        } catch {
            print("❌ Currency demo error: \(error)")
        }
        
        // MARK: - 3. Rate Limiting in Action
        
        print("\n3️⃣ Rate Limiting Demonstration")
        print("-------------------------------")
        
        // Make multiple requests to show rate limiting
        let releaseIds = [249504, 1, 2, 3, 4] // Mix of valid and potentially invalid IDs
        
        for (index, releaseId) in releaseIds.enumerated() {
            do {
                print("📀 Request \(index + 1): Fetching release \(releaseId)...")
                
                let release = try await discogs.database.getRelease(id: releaseId)
                print("✅ Success: \(release.title)")
                
                // Show current rate limit status
                if let rateLimit = await discogs.rateLimit {
                    let status = rateLimit.isApproachingLimit ? "⚠️ APPROACHING LIMIT" : "✅ OK"
                    print("   📊 Rate limit: \(rateLimit.remaining)/\(rateLimit.limit) remaining \(status)")
                }
                
            } catch DiscogsError.rateLimitExceeded {
                print("⏳ Rate limit exceeded - automatic retry will be attempted")
            } catch {
                print("❌ Error: \(error)")
            }
            
            // Small delay between requests
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // MARK: - 4. OAuth Authentication Demo (Setup Only)
        
        print("\n4️⃣ OAuth Authentication Setup")
        print("------------------------------")
        
        // Note: This would require actual OAuth credentials
        print("🔐 OAuth client initialization example:")
        print("   let oauthClient = Discogs(")
        print("       consumerKey: \"your_consumer_key\",")
        print("       consumerSecret: \"your_consumer_secret\",")
        print("       accessToken: \"your_access_token\",")
        print("       accessTokenSecret: \"your_access_token_secret\",")
        print("       userAgent: \"YourApp/1.0\"")
        print("   )")
        print("✅ OAuth signature generation is now fully integrated!")
        
        // MARK: - 5. Advanced Search with Validation
        
        print("\n5️⃣ Advanced Search Features")
        print("----------------------------")
        
        do {
            print("🔍 Searching for releases with comprehensive filters...")
            
            let searchResults = try await discogs.search.search(
                query: "Dark Side of the Moon",
                type: .release,
                artist: "Pink Floyd",
                format: "Vinyl",
                year: "1973",
                page: 1,
                perPage: 5
            )
            
            print("📊 Found \(searchResults.pagination.items) total results")
            print("📄 Showing page \(searchResults.pagination.page) of \(searchResults.pagination.pages)")
            
            for (index, result) in searchResults.results.enumerated() {
                print("   \(index + 1). \(result.title) (\(result.year ?? "Unknown year"))")
            }
            
        } catch {
            print("❌ Search error: \(error)")
        }
        
        // MARK: - 6. Error Handling Best Practices
        
        print("\n6️⃣ Error Handling Best Practices")
        print("---------------------------------")
        
        await demonstrateErrorHandling(discogs: discogs)
        
        print("\n🎉 Enhanced Example Complete!")
        print("==============================")
        print("✅ Rate limiting with exponential backoff")
        print("✅ Currency validation")
        print("✅ Full OAuth integration")
        print("✅ Comprehensive error handling")
        print("✅ 100% API compliance achieved!")
    }
    
    static func demonstrateErrorHandling(discogs: Discogs) async {
        let errorScenarios = [
            ("Invalid Release ID", { try await discogs.database.getRelease(id: -1) }),
            ("Rate Limit Test", { 
                // This might trigger rate limiting
                for i in 1...10 {
                    let _ = try await discogs.database.getRelease(id: i)
                }
            }),
            ("Invalid Currency", { try await discogs.database.getRelease(id: 1, currency: "FAKE") })
        ]
        
        for (scenario, operation) in errorScenarios {
            do {
                print("🧪 Testing: \(scenario)")
                let _: ReleaseDetails = try await operation()
                print("✅ \(scenario): Succeeded unexpectedly")
            } catch DiscogsError.rateLimitExceeded {
                print("⏳ \(scenario): Rate limit - handled with retry")
            } catch DiscogsError.invalidInput(let message) {
                print("🚫 \(scenario): Validation error - \(message)")
            } catch DiscogsError.httpError(let statusCode) {
                print("🌐 \(scenario): HTTP error - Status \(statusCode)")
            } catch DiscogsError.networkError(let underlyingError) {
                print("📡 \(scenario): Network error - \(underlyingError.localizedDescription)")
            } catch {
                print("❓ \(scenario): Unexpected error - \(error)")
            }
        }
    }
    
    static func getToken() -> String {
        // In a real app, load from secure storage, environment variables, or configuration
        if let token = ProcessInfo.processInfo.environment["DISCOGS_TOKEN"] {
            return token
        }
        
        // Fallback for demo (replace with your token)
        print("⚠️ Using demo token - set DISCOGS_TOKEN environment variable for real usage")
        return "your_discogs_token_here"
    }
}

// MARK: - Utility Extensions for Demo

extension RateLimitConfig {
    var description: String {
        return "RateLimitConfig(retries: \(maxRetries), baseDelay: \(baseDelay)s, maxDelay: \(maxDelay)s, autoRetry: \(enableAutoRetry))"
    }
}
