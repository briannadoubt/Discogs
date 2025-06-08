import Foundation

/// Main interface for the Discogs API
/// Documentation: https://www.discogs.com/developers
public actor Discogs: HTTPClientProtocol {
    
    // MARK: - Constants
    
    /// The base URL for the Discogs API
    public let baseURL = URL(string: "https://api.discogs.com")!
    
    /// User-Agent header value required by Discogs API
    public let userAgent: String
    
    // MARK: - Authentication Properties
    
    /// Authentication method to use with the API
    internal let authMethod: AuthMethod
    
    /// Rate limiting information from the most recent API response
    internal var _rateLimit: RateLimit?
    
    /// Rate limiting configuration
    public let rateLimitConfig: RateLimitConfig
    
    /// Get the current rate limit information
    public var rateLimit: RateLimit? {
        return _rateLimit
    }
    
    // MARK: - Initialization
    
    /// Initialize a Discogs API client with personal access token
    /// - Parameters:
    ///   - token: Your personal access token from Discogs
    ///   - userAgent: User agent string that identifies your application (required by Discogs)
    ///   - rateLimitConfig: Configuration for rate limiting behavior (optional)
    public init(token: String, userAgent: String, rateLimitConfig: RateLimitConfig = .default) {
        self.authMethod = .token(token)
        self.userAgent = userAgent
        self.rateLimitConfig = rateLimitConfig
    }
    
    /// Initialize a Discogs API client with OAuth credentials
    /// - Parameters:
    ///   - consumerKey: OAuth consumer key
    ///   - consumerSecret: OAuth consumer secret
    ///   - accessToken: OAuth access token
    ///   - accessTokenSecret: OAuth access token secret
    ///   - userAgent: User agent string that identifies your application (required by Discogs)
    ///   - rateLimitConfig: Configuration for rate limiting behavior (optional)
    public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String, userAgent: String, rateLimitConfig: RateLimitConfig = .default) {
        self.authMethod = .oauth(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret
        )
        self.userAgent = userAgent
        self.rateLimitConfig = rateLimitConfig
    }
    
    // MARK: - API Services
    /// Service for interacting with the Discogs database (artists, releases, masters, labels)
    public lazy var database: DatabaseService = DatabaseService(httpClient: self)
    
    /// Service for managing user collections
    public lazy var collection: CollectionService = CollectionService(httpClient: self)
    
    /// Service for marketplace operations (buying and selling)
    public lazy var marketplace: MarketplaceService = MarketplaceService(httpClient: self)
    
    /// Service for user identity and profile management
    public lazy var user: UserService = UserService(httpClient: self)
    
    /// Service for managing user wantlists
    public lazy var wantlist: WantlistService = WantlistService(httpClient: self)
    
    /// Service for searching the Discogs database
    public lazy var search: SearchService = SearchService(httpClient: self)
}




