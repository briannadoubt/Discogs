import Foundation

public struct WantlistService: DiscogsServiceProtocol { // Changed to struct, added Sendable
    
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
    
    // MARK: - Wantlist Methods
    
    /// Get a user's wantlist
    /// - Parameters:
    ///   - username: The username
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    ///   - sort: Sort field
    ///   - sortOrder: Sort direction
    /// - Returns: A `PaginatedResponse` containing `WantlistItem` objects.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getWantlist(
        username: String,
        page: Int = 1,
        perPage: Int = 50,
        sort: WantlistSort = .added,
        sortOrder: SortOrder = .descending
    ) async throws -> PaginatedResponse<WantlistItem> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage),
            "sort": sort.rawValue,
            "sort_order": sortOrder.rawValue
        ]
        
        return try await performRequest(
            endpoint: "users/\(username)/wants",
            parameters: parameters
        )
    }
    
    /// Add a release to a user's wantlist
    /// - Parameters:
    ///   - username: The username
    ///   - releaseId: The release ID
    ///   - notes: Optional notes about this want
    ///   - rating: Optional rating from 1-5
    /// - Returns: A `WantlistItem` object.
    /// - Throws: A `DiscogsError` if the request fails or input is invalid.
    public func addToWantlist(
        username: String,
        releaseId: Int,
        notes: String? = nil,
        rating: Int? = nil
    ) async throws -> WantlistItem {
        var body: [String: any Sendable] = [:]
        
        if let notes = notes {
            body["notes"] = notes
        }
        
        if let rating = rating {
            guard (1...5).contains(rating) else {
                throw DiscogsError.invalidInput("Rating must be between 1 and 5")
            }
            body["rating"] = rating
        }
        
        return try await performRequest(
            endpoint: "users/\(username)/wants/\(releaseId)",
            method: .put,
            body: body
        )
    }
    
    /// Remove a release from a user's wantlist
    /// - Parameters:
    ///   - username: The username
    ///   - releaseId: The release ID
    /// - Returns: A `SuccessResponse` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func removeFromWantlist(
        username: String,
        releaseId: Int
    ) async throws -> SuccessResponse {
        try await performRequest(
            endpoint: "users/\(username)/wants/\(releaseId)",
            method: .delete
        )
    }
    
    /// Update the notes or rating for a release in a user's wantlist
    /// - Parameters:
    ///   - username: The username
    ///   - releaseId: The release ID
    ///   - notes: New notes about this want
    ///   - rating: New rating from 1-5
    /// - Returns: A `WantlistItem` object.
    /// - Throws: A `DiscogsError` if the request fails or input is invalid.
    public func updateWantlistItem(
        username: String,
        releaseId: Int,
        notes: String? = nil,
        rating: Int? = nil
    ) async throws -> WantlistItem {
        var body: [String: any Sendable] = [:]
        
        if let notes = notes {
            body["notes"] = notes
        }
        
        if let rating = rating {
            guard (1...5).contains(rating) else {
                throw DiscogsError.invalidInput("Rating must be between 1 and 5")
            }
            body["rating"] = rating
        }
        
        return try await performRequest(
            endpoint: "users/\(username)/wants/\(releaseId)",
            method: .post,
            body: body
        )
    }
}

// MARK: - Enums

extension WantlistService {
    /// Sort fields for wantlists
    public enum WantlistSort: String, Sendable { // Added Sendable
        /// Sort by artist name
        case artist
        /// Sort by title
        case title
        /// Sort by catalog number
        case catno
        /// Sort by date added
        case added
        /// Sort by year
        case year
    }
    
    /// Sort direction
    public enum SortOrder: String, Sendable { // Added Sendable
        /// Ascending order (A-Z, oldest to newest)
        case ascending = "asc"
        /// Descending order (Z-A, newest to oldest)
        case descending = "desc"
    }
}

// MARK: - Models

/// An item in a user's wantlist
public struct WantlistItem: Codable, Sendable { // Added Sendable
    /// The ID of the item
    public let id: Int
    
    /// The rating given to this want
    public let rating: Int?
    
    /// Notes about this want
    public let notes: String?
    
    /// Resource URL for this want
    public let resourceUrl: String
    
    /// Date this item was added to the wantlist
    public let dateAdded: String?
    
    /// Basic information about the release
    public let basicInformation: ReleaseBasicInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case rating
        case notes
        case resourceUrl = "resource_url"
        case dateAdded = "date_added"
        case basicInformation = "basic_information"
    }
}
