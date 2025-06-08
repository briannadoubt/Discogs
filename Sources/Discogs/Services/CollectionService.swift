import Foundation

/// Service for interacting with user collections
public struct CollectionService: DiscogsServiceProtocol {
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

    // MARK: - Collection Folders

    /// Get a user's collection folders
    /// - Parameter username: The username
    public func getFolders(username: String) async throws -> FoldersList {
        try await performRequest(endpoint: "users/\(username)/collection/folders")
    }

    /// Get a specific collection folder
    /// - Parameters:
    ///   - username: The username
    ///   - folderId: The folder ID
    public func getFolder(username: String, folderId: Int) async throws -> Folder {
        try await performRequest(endpoint: "users/\(username)/collection/folders/\(folderId)")
    }

    /// Create a new collection folder
    /// - Parameters:
    ///   - username: The username
    ///   - name: The folder name
    public func createFolder(username: String, name: String) async throws -> Folder {
        let body = ["name": name]
        return try await performRequest(
            endpoint: "users/\(username)/collection/folders",
            method: .post,
            body: body
        )
    }

    /// Update a collection folder
    /// - Parameters:
    ///   - username: The username
    ///   - folderId: The folder ID
    ///   - name: The new folder name
    public func updateFolder(username: String, folderId: Int, name: String) async throws -> Folder {
        let body = ["name": name]
        return try await performRequest(
            endpoint: "users/\(username)/collection/folders/\(folderId)",
            method: .post,
            body: body
        )
    }

    /// Delete a collection folder
    /// - Parameters:
    ///   - username: The username
    ///   - folderId: The folder ID
    public func deleteFolder(username: String, folderId: Int) async throws -> SuccessResponse {
        try await performRequest(
            endpoint: "users/\(username)/collection/folders/\(folderId)",
            method: .delete
        )
    }

    // MARK: - Collection Items

    /// Get items in a collection folder
    /// - Parameters:
    ///   - username: The username
    ///   - folderId: The folder ID
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    ///   - sort: Sort field (default: .artist)
    ///   - sortOrder: Sort direction (default: .ascending)
    public func getItemsInFolder(
        username: String,
        folderId: Int,
        page: Int = 1,
        perPage: Int = 50,
        sort: CollectionSort = .artist,
        sortOrder: SortOrder = .ascending
    ) async throws -> PaginatedResponse<CollectionItem> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage),
            "sort": sort.rawValue,
            "sort_order": sortOrder.rawValue
        ]
        return try await performRequest(
            endpoint: "users/\(username)/collection/folders/\(folderId)/releases",
            parameters: parameters
        )
    }

    /// Add a release to a collection folder
    /// - Parameters:
    ///   - username: The username
    ///   - folderId: The folder ID
    ///   - releaseId: The release ID
    public func addReleaseToFolder(
        username: String,
        folderId: Int,
        releaseId: Int
    ) async throws -> CollectionItemResponse {
        try await performRequest(
            endpoint: "users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)",
            method: .post
        )
    }

    /// Remove a release from a collection folder
    /// - Parameters:
    ///   - username: The username
    ///   - folderId: The folder ID
    ///   - releaseId: The release ID
    ///   - instanceId: The instance ID
    public func removeReleaseFromFolder(
        username: String,
        folderId: Int,
        releaseId: Int,
        instanceId: Int
    ) async throws -> SuccessResponse {
        try await performRequest(
            endpoint: "users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)/instances/\(instanceId)",
            method: .delete
        )
    }

    /// Get a specific collection item
    /// - Parameters:
    ///   - username: The username
    ///   - releaseId: The release ID
    public func getCollectionItemByRelease(username: String, releaseId: Int) async throws -> CollectionItemResponse {
        try await performRequest(endpoint: "users/\(username)/collection/releases/\(releaseId)")
    }

    // MARK: - Collection Field Values

    /// Get the user's custom collection fields
    /// - Parameter username: The username
    public func getCustomFields(username: String) async throws -> CollectionFields {
        try await performRequest(endpoint: "users/\(username)/collection/fields")
    }

    /// Edit the field values for an item
    /// - Parameters:
    ///   - username: The username
    ///   - folderId: The folder ID
    ///   - releaseId: The release ID
    ///   - instanceId: The instance ID
    ///   - fieldId: The field ID
    ///   - value: The field value
    public func editItemFieldValue(
        username: String,
        folderId: Int,
        releaseId: Int,
        instanceId: Int,
        fieldId: Int,
        value: [String]
    ) async throws -> FieldValue {
        let body: [String: any Sendable] = ["value": value]
        return try await performRequest(
            endpoint: "users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)/instances/\(instanceId)/fields/\(fieldId)",
            method: .post,
            body: body
        )
    }

    // MARK: - Collection Value

    /// Get the minimum, median, and maximum value of a user's collection
    /// - Parameter username: The username
    public func getValue(username: String) async throws -> CollectionValue {
        try await performRequest(endpoint: "users/\(username)/collection/value")
    }
}

// MARK: - Enums

extension CollectionService {
    /// Collection sort fields
    public enum CollectionSort: String {
        /// Sort by artist name
        case artist
        /// Sort by title
        case title
        /// Sort by catalog number
        case catno
        /// Sort by format
        case format
        /// Sort by rating
        case rating
        /// Sort by date added
        case added
        /// Sort by year
        case year
    }

    /// Sort direction
    public enum SortOrder: String {
        /// Ascending order (A-Z, oldest to newest)
        case ascending = "asc"
        /// Descending order (Z-A, newest to oldest)
        case descending = "desc"
    }
}

// MARK: - Models

/// A list of collection folders
public struct FoldersList: Codable, Sendable {
    /// The list of folders
    public let folders: [Folder]
}

/// A collection folder
public struct Folder: Codable, Sendable {
    /// The folder ID
    public let id: Int
    
    /// The folder name
    public let name: String
    
    /// The number of releases in this folder
    public let count: Int
    
    /// The resource URL for this folder
    public let resourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case count
        case resourceUrl = "resource_url"
    }
}

/// A collection item response
public struct CollectionItemResponse: Codable, Sendable {
    /// The instance ID
    public let instanceId: Int?
    
    /// The resource URL
    public let resourceUrl: String?
    
    /// The instances of this release in the collection (for compatibility)
    public var instances: [CollectionItemInstance]? {
        if let instanceId = instanceId {
            return [CollectionItemInstance(id: instanceId, folderId: 0, dateAdded: "", notes: nil)]
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case instanceId = "instance_id"
        case resourceUrl = "resource_url"
    }
}

/// Basic information about a release
public struct ReleaseBasicInfo: Codable, Sendable {
    /// The ID of the release
    public let id: Int
    
    /// The master ID of the release
    public let masterId: Int?
    
    /// The master URL of the release
    public let masterUrl: String?
    
    /// The resource URL of the release
    public let resourceUrl: String?
    
    /// The title of the release
    public let title: String
    
    /// The year of the release
    public let year: Int?
    
    /// The formats of the release
    public let formats: [ReleaseFormat]?
    
    /// The labels of the release
    public let labels: [ReleaseLabel]?
    
    /// The artists of the release
    public let artists: [ReleaseArtist]?
    
    /// The thumbnail URL
    public let thumb: String?
    
    /// The cover image URL
    public let coverImage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case masterId = "master_id"
        case masterUrl = "master_url"
        case resourceUrl = "resource_url"
        case title
        case year
        case formats
        case labels
        case artists
        case thumb
        case coverImage = "cover_image"
    }
}

/// A collection item
public struct CollectionItem: Codable, Sendable {
    /// The ID of the item
    public let id: Int
    
    /// The ID of the instance
    public let instanceId: Int
    
    /// The ID of the folder
    public let folderId: Int
    
    /// The rating of the item
    public let rating: Int?
    
    /// The basic information about the release
    public let basicInformation: ReleaseBasicInfo
    
    /// The date the item was added
    public let dateAdded: String?
    
    /// The notes about this item
    public let notes: [CollectionNote]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case instanceId = "instance_id"
        case folderId = "folder_id"
        case rating
        case basicInformation = "basic_information"
        case dateAdded = "date_added"
        case notes
    }
}

/// An instance of a release in a collection
public struct CollectionItemInstance: Codable, Sendable {
    /// The ID of the instance
    public let id: Int
    
    /// The ID of the folder
    public let folderId: Int
    
    /// The date the instance was added
    public let dateAdded: String
    
    /// The notes about this instance
    public let notes: [CollectionNote]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case folderId = "folder_id"
        case dateAdded = "date_added"
        case notes
    }
}

/// A note about a collection item
public struct CollectionNote: Codable, Sendable {
    /// The ID of the field
    public let fieldId: Int
    
    /// The value of the field
    public let value: String
    
    enum CodingKeys: String, CodingKey {
        case fieldId = "field_id"
        case value
    }
}

/// Custom fields for a collection
public struct CollectionFields: Codable, Sendable {
    /// The list of fields
    public let fields: [CollectionField]
}

/// A custom field for a collection
public struct CollectionField: Codable, Sendable {
    /// The ID of the field
    public let id: Int
    
    /// The name of the field
    public let name: String
    
    /// The type of the field
    public let type: String
    
    /// The options for the field
    public let options: [String]?
    
    /// The position of the field
    public let position: Int?
    
    /// Whether the field is public
    public let `public`: Bool?
}

/// A field value for a collection item
public struct FieldValue: Codable, Sendable {
    /// The value of the field
    public let value: [String]
}

/// The value of a collection
public struct CollectionValue: Codable, Sendable {
    /// The minimum value of the collection
    public let minimum: String
    
    /// The median value of the collection
    public let median: String
    
    /// The maximum value of the collection
    public let maximum: String
    
    /// The currency used for the values
    public let currency: String?
}
