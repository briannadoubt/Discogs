import Foundation

public struct SearchService: DiscogsServiceProtocol { // Changed to struct, added Sendable
    
    // MARK: - Properties
    
    /// The HTTP client used for making requests
    public let httpClient: HTTPClientProtocol
    
    // MARK: - Initialization
    
    /// Initialize with an HTTP client
    /// - Parameter httpClient: The HTTP client to use for API requests
    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
    }
    
    /// Convenience initializer with Discogs client (for backward compatibility)
    /// - Parameter client: The Discogs client to use for API requests
    public init(client: Discogs) {
        self.httpClient = client
    }
    
    /// Search for items in the Discogs database
    /// - Parameters:
    ///   - query: The search query
    ///   - type: The type of item to search for (optional)
    ///   - title: Filter by title (optional)
    ///   - releaseTitle: Filter by release title (optional)
    ///   - credit: Filter by credit (optional)
    ///   - artist: Filter by artist name (optional)
    ///   - anv: Filter by artist ANV (optional)
    ///   - label: Filter by label name (optional)
    ///   - genre: Filter by genre (optional)
    ///   - style: Filter by style (optional)
    ///   - country: Filter by country (optional)
    ///   - year: Filter by year (optional)
    ///   - format: Filter by format (optional)
    ///   - catno: Filter by catalog number (optional)
    ///   - barcode: Filter by barcode (optional)
    ///   - track: Filter by track (optional)
    ///   - submitter: Filter by submitter (optional)
    ///   - contributor: Filter by contributor (optional)
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    /// - Returns: A `PaginatedResponse` containing `SearchResult` objects.
    /// - Throws: A `DiscogsError` if the request fails.
    public func search(
        query: String? = nil,
        type: SearchType? = nil,
        title: String? = nil,
        releaseTitle: String? = nil,
        credit: String? = nil,
        artist: String? = nil,
        anv: String? = nil,
        label: String? = nil,
        genre: String? = nil,
        style: String? = nil,
        country: String? = nil,
        year: String? = nil,
        format: String? = nil,
        catno: String? = nil,
        barcode: String? = nil,
        track: String? = nil,
        submitter: String? = nil,
        contributor: String? = nil,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> PaginatedResponse<SearchResult> {
        var parameters: [String: String] = [
            "page": String(page),
            "per_page": String(perPage)
        ]
        
        // Add search parameters if provided
        if let query = query { parameters["q"] = query }
        if let type = type { parameters["type"] = type.rawValue }
        if let title = title { parameters["title"] = title }
        if let releaseTitle = releaseTitle { parameters["release_title"] = releaseTitle }
        if let credit = credit { parameters["credit"] = credit }
        if let artist = artist { parameters["artist"] = artist }
        if let anv = anv { parameters["anv"] = anv }
        if let label = label { parameters["label"] = label }
        if let genre = genre { parameters["genre"] = genre }
        if let style = style { parameters["style"] = style }
        if let country = country { parameters["country"] = country }
        if let year = year { parameters["year"] = year }
        if let format = format { parameters["format"] = format }
        if let catno = catno { parameters["catno"] = catno }
        if let barcode = barcode { parameters["barcode"] = barcode }
        if let track = track { parameters["track"] = track }
        if let submitter = submitter { parameters["submitter"] = submitter }
        if let contributor = contributor { parameters["contributor"] = contributor }
        
        return try await performRequest(endpoint: "database/search", parameters: parameters)
    }
}

// MARK: - Search Types

extension SearchService {
    /// Types of items that can be searched for
    public enum SearchType: String, Sendable { // Added Sendable
        /// Release
        case release
        /// Master release
        case master
        /// Artist
        case artist
        /// Label
        case label
    }
}

// MARK: - Search Result Model

/// A result from a Discogs database search
public struct SearchResult: Codable, Sendable, Identifiable { // Added Sendable
    /// The ID of the result
    public let id: Int
    
    /// The type of the result (release, master, artist, or label)
    public let type: String
    
    /// The user who submitted this item
    public let userData: UserData?
    
    /// The master ID (for releases)
    public let masterId: Int?
    
    /// The master URL (for releases)
    public let masterUrl: String?
    
    /// The title of the result
    public let title: String?
    
    /// The thumbnail image URL
    public let thumb: String?
    
    /// The cover image URL
    public let cover_image: String?
    
    /// The resource URL
    public let resourceUrl: String?
    
    /// The URI
    public let uri: String?
    
    /// The country (for releases)
    public let country: String?
    
    /// The year (for releases)
    public let year: String?
    
    /// The format (for releases)
    public let format: [String]?
    
    /// The label names (for releases)
    public let label: [String]?
    
    /// The genre (for releases)
    public let genre: [String]?
    
    /// The style (for releases)
    public let style: [String]?
    
    /// The barcode (for releases)
    public let barcode: [String]?
    
    /// The catalog number (for releases)
    public let catno: String?
    
    /// The community statistics
    public let community: ReleaseCommunityStats?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case userData = "user_data"
        case masterId = "master_id"
        case masterUrl = "master_url"
        case title
        case thumb
        case cover_image
        case resourceUrl = "resource_url"
        case uri
        case country
        case year
        case format
        case label
        case genre
        case style
        case barcode
        case catno
        case community
    }
}

/// User data related to a search result
public struct UserData: Codable, Sendable { // Added Sendable
    /// If the user has this item in their collection
    public let inCollection: Bool?
    
    /// If the user has this item in their wantlist
    public let inWantlist: Bool?
    
    enum CodingKeys: String, CodingKey {
        case inCollection = "in_collection"
        case inWantlist = "in_wantlist"
    }
}
