import Foundation

/// Service for interacting with user identity and profile
public struct UserService: DiscogsServiceProtocol { // Changed to struct, added Sendable
    
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
    
    // MARK: - Identity Methods
    
    /// Get the identity of the authenticated user
    /// - Returns: A `UserIdentity` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getIdentity() async throws -> UserIdentity {
        try await performRequest(endpoint: "oauth/identity")
    }
    
    // MARK: - Profile Methods
    
    /// Get a user's profile
    /// - Parameters:
    ///   - username: The username of the user
    /// - Returns: A `UserProfile` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getProfile(username: String) async throws -> UserProfile {
        try await performRequest(endpoint: "users/\(username)")
    }
    
    /// Edit the authenticated user's profile
    /// - Parameters:
    ///   - username: The username of the authenticated user
    ///   - name: The user's full name
    ///   - homePage: The user's home page
    ///   - location: The user's location
    ///   - profile: The user's profile text
    /// - Returns: A `UserProfile` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func editProfile(
        username: String,
        name: String? = nil,
        homePage: String? = nil,
        location: String? = nil,
        profile: String? = nil
    ) async throws -> UserProfile {
        var body: [String: any Sendable] = [:]
        
        if let name = name { body["name"] = name }
        if let homePage = homePage { body["home_page"] = homePage }
        if let location = location { body["location"] = location }
        if let profile = profile { body["profile"] = profile }
        
        return try await performRequest(
            endpoint: "users/\(username)",
            method: .post,
            body: body
        )
    }
    
    // MARK: - Submissions
    
    /// Get a list of user submissions
    /// - Parameters:
    ///   - username: The username of the user
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    /// - Returns: A `PaginatedResponse` containing `Submission` objects.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getSubmissions(
        username: String,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> PaginatedResponse<Submission> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage)
        ]
        
        return try await performRequest(
            endpoint: "users/\(username)/submissions",
            parameters: parameters
        )
    }
    
    // MARK: - Contributions
    
    /// Get a list of user contributions
    /// - Parameters:
    ///   - username: The username of the user
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    ///   - sort: Sort field
    ///   - sortOrder: Sort direction
    /// - Returns: A `PaginatedResponse` containing `Contribution` objects.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getContributions(
        username: String,
        page: Int = 1,
        perPage: Int = 50,
        sort: ContributionsSort = .label,
        sortOrder: SortOrder = .ascending
    ) async throws -> PaginatedResponse<Contribution> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage),
            "sort": sort.rawValue,
            "sort_order": sortOrder.rawValue
        ]
        
        return try await performRequest(
            endpoint: "users/\(username)/contributions",
            parameters: parameters
        )
    }
    
    // MARK: - Lists
    
    /// Get a user's lists
    /// - Parameters:
    ///   - username: The username of the user
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    /// - Returns: A `PaginatedResponse` containing `UserList` objects.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getLists(
        username: String,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> PaginatedResponse<UserList> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage)
        ]
        
        return try await performRequest(
            endpoint: "users/\(username)/lists",
            parameters: parameters
        )
    }
    
    /// Get a specific user list
    /// - Parameters:
    ///   - listId: The ID of the list
    /// - Returns: A `UserListDetails` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getList(
        listId: Int
    ) async throws -> UserListDetails {
        try await performRequest(
            endpoint: "lists/\(listId)"
        )
    }
}

// MARK: - Enums

extension UserService {
    /// Fields to sort contributions by
    public enum ContributionsSort: String, Sendable { // Added Sendable
        /// Sort by label
        case label
        /// Sort by artist
        case artist
        /// Sort by title
        case title
        /// Sort by catno (catalog number)
        case catno
        /// Sort by format
        case format
        /// Sort by rating
        case rating
        /// Sort by released
        case released
        /// Sort by year
        case year
        /// Sort by date added
        case added
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

/// The identity of the authenticated user
public struct UserIdentity: Codable, Sendable { // Added Sendable
    /// The user's ID
    public let id: Int
    
    /// The user's username
    public let username: String
    
    /// The user's resource URL
    public let resourceUrl: String
    
    /// The user's consumer name (for OAuth)
    public let consumerName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case resourceUrl = "resource_url"
        case consumerName = "consumer_name"
    }
}

/// A user profile
public struct UserProfile: Codable, Sendable { // Added Sendable
    /// The profile's ID
    public let id: Int
    
    /// The profile's username
    public let username: String
    
    /// The user's resource URL
    public let resourceUrl: String
    
    /// The user's full name
    public let name: String?
    
    /// The user's email (only returned for the authenticated user)
    public let email: String?
    
    /// The user's profile text
    public let profile: String?
    
    /// The user's registered date
    public let registerDate: String?
    
    /// The user's number of ratings
    public let numCollection: Int?
    
    /// The user's number of items in collection
    public let numWantlist: Int?
    
    /// The user's number of pending items
    public let numPending: Int?
    
    /// The user's number of lists
    public let numLists: Int?
    
    /// The user's location
    public let location: String?
    
    /// The user's home page
    public let homePage: String?
    
    /// The user's inventory URL
    public let inventoryUrl: String?
    
    /// The user's collection URL
    public let collectionUrl: String?
    
    /// The user's wantlist URL
    public let wantlistUrl: String?
    
    /// The user's marketplace URL
    public let marketplaceUrl: String?
    
    /// The user's URI
    public let uri: String?
    
    /// The user's rank
    public let rank: Double?
    
    /// The user's releases URL
    public let releasesUrl: String?
    
    /// The user's rating average
    public let ratingAvg: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case resourceUrl = "resource_url"
        case name
        case email
        case profile
        case registerDate = "register_date"
        case numCollection = "num_collection"
        case numWantlist = "num_wantlist"
        case numPending = "num_pending"
        case numLists = "num_lists"
        case location
        case homePage = "home_page"
        case inventoryUrl = "inventory_url"
        case collectionUrl = "collection_url"
        case wantlistUrl = "wantlist_url"
        case marketplaceUrl = "marketplace_url"
        case uri
        case rank
        case releasesUrl = "releases_url"
        case ratingAvg = "rating_avg"
    }
}

/// A user submission to the Discogs database
public struct Submission: Codable, Sendable { // Added Sendable
    /// The submission ID
    public let id: Int
    
    /// The submission user
    public let user: UserReference
    
    /// The submission status
    public let status: String
    
    /// The submission title
    public let title: String
    
    /// The submission type
    public let type: String
    
    /// The submission URL
    public let url: String
    
    /// The submission date
    public let submissionDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case status
        case title
        case type
        case url
        case submissionDate = "submission_date"
    }
}

/// A user contribution to the Discogs database
public struct Contribution: Codable, Sendable { // Added Sendable
    /// The contribution ID
    public let id: Int
    
    /// The contribution title
    public let title: String
    
    /// The contribution type
    public let type: String
    
    /// The contribution URL
    public let url: String
    
    /// The contribution artist
    public let artist: String?
    
    /// The contribution label
    public let label: String?
    
    /// The contribution year
    public let year: Int?
    
    /// The contribution resource URL
    public let resourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case url
        case artist
        case label
        case year
        case resourceUrl = "resource_url"
    }
}

/// A reference to a user
public struct UserReference: Codable, Sendable { // Added Sendable
    /// The user's resource URL
    public let resourceUrl: String
    
    /// The user's username
    public let username: String
    
    enum CodingKeys: String, CodingKey {
        case resourceUrl = "resource_url"
        case username
    }
}

/// A user list
public struct UserList: Codable, Sendable { // Added Sendable
    /// The list ID
    public let id: Int
    
    /// The list date created
    public let dateCreated: String
    
    /// The list date updated
    public let dateUpdated: String
    
    /// The list name
    public let name: String
    
    /// The list description
    public let description: String?
    
    /// The list image URL
    public let imageUrl: String?
    
    /// The list resource URL
    public let resourceUrl: String
    
    /// The list URI
    public let uri: String
    
    /// The list item count
    public let itemCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case dateCreated = "date_created"
        case dateUpdated = "date_updated"
        case name
        case description
        case imageUrl = "image_url"
        case resourceUrl = "resource_url"
        case uri
        case itemCount = "item_count"
    }
}

/// Detailed information about a user list
public struct UserListDetails: Codable, Sendable { // Added Sendable
    /// The list ID
    public let id: Int
    
    /// The list date created
    public let dateCreated: String
    
    /// The list date updated
    public let dateUpdated: String
    
    /// The list name
    public let name: String
    
    /// The list description
    public let description: String?
    
    /// The list image URL
    public let imageUrl: String?
    
    /// The list resource URL
    public let resourceUrl: String
    
    /// The list URI
    public let uri: String
    
    /// The list items
    public let items: [ListItem]
    
    /// The list owner
    public let owner: UserReference
    
    enum CodingKeys: String, CodingKey {
        case id
        case dateCreated = "date_created"
        case dateUpdated = "date_updated"
        case name
        case description
        case imageUrl = "image_url"
        case resourceUrl = "resource_url"
        case uri
        case items
        case owner
    }
}

/// An item in a user list
public struct ListItem: Codable, Sendable { // Added Sendable
    /// The item ID
    public let id: Int
    
    /// The item type
    public let type: String
    
    /// The item title
    public let title: String
    
    /// The item comment
    public let comment: String?
    
    /// The item display title
    public let displayTitle: String?
    
    /// The item URI
    public let uri: String
    
    /// The item artist
    public let artist: String?
    
    /// The item catno (catalog number)
    public let catno: String?
    
    /// The item format
    public let format: String?
    
    /// The item resource URL
    public let resourceUrl: String
    
    /// The item year
    public let year: Int?
    
    /// The item thumbnail URL
    public let thumb: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case comment
        case displayTitle = "display_title"
        case uri
        case artist
        case catno
        case format
        case resourceUrl = "resource_url"
        case year
        case thumb
    }
}
