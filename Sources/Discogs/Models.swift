import Foundation

// MARK: - Common Response Models

/// A paginated response containing a list of results
public struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    /// The pagination information
    public let pagination: Pagination
    
    /// The items in this page
    public let items: [T]
    
    private enum CodingKeys: String, CodingKey {
        case pagination
        case results
        case versions
        case listings
        case items
        case releases
        case folders
        case orders
        case wants
        case submissions
        case lists
    }
    
    /// Initialize a paginated response from a decoder
    /// 
    /// This initializer handles the variety of response formats used by different
    /// Discogs API endpoints, which may use different JSON keys for the results array.
    /// - Parameter decoder: The decoder to read from
    /// - Throws: A decoding error if the response cannot be parsed
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pagination = try container.decode(Pagination.self, forKey: .pagination)
        
        // Different endpoints use different keys for the results array
        // Attempt to decode items using a variety of common keys
        if let itemsArray = try? container.decode([T].self, forKey: .items) { // Try generic 'items' first
            items = itemsArray
        } else if let releases = try? container.decode([T].self, forKey: .results) { // Then specific 'results'
            items = releases
        } else if let versions = try? container.decode([T].self, forKey: .versions) {
            items = versions
        } else if let listings = try? container.decode([T].self, forKey: .listings) {
            items = listings
        } else if let releases = try? container.decode([T].self, forKey: .releases) {
            items = releases
        } else if let folders = try? container.decode([T].self, forKey: .folders) {
            items = folders
        } else if let orders = try? container.decode([T].self, forKey: .orders) {
            items = orders
        } else if let wants = try? container.decode([T].self, forKey: .wants) {
            items = wants
        } else if let submissions = try? container.decode([T].self, forKey: .submissions) {
            items = submissions
        } else if let lists = try? container.decode([T].self, forKey: .lists) {
            items = lists
        } else {
            // If none of the known keys match, try to decode as an array directly from the container
            // This handles cases where the array is the top-level element in the JSON (e.g. wantlist)
            do {
                var unkeyedContainer = try decoder.unkeyedContainer()
                var tempItems = [T]()
                while !unkeyedContainer.isAtEnd {
                    tempItems.append(try unkeyedContainer.decode(T.self))
                }
                items = tempItems
            } catch {
                // If we can't decode as an unkeyed container (i.e., JSON is not an array)
                // then we default to an empty array
                items = []
            }
        }
    }
    
    /// Encode the paginated response to an encoder
    /// - Parameter encoder: The encoder to write to
    /// - Throws: An encoding error if the response cannot be encoded
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pagination, forKey: .pagination)
        try container.encode(items, forKey: .results)
    }
}

/// A simple success response
public struct SuccessResponse: Codable, Sendable {
    /// The success message
    public let message: String
}

// MARK: - Artist

/// An artist in the Discogs database
public struct Artist: Codable, Sendable {
    /// The unique identifier for this artist
    public let id: Int
    
    /// The name of the artist
    public let name: String
    
    /// The real name of the artist (if available)
    public let realName: String?
    
    /// URLs for this artist
    public let urls: [String]?
    
    /// A list of name variations for this artist
    public let namevariations: [String]?
    
    /// A biography of the artist
    public let profile: String?
    
    /// The year the artist was born/formed
    public let dataQuality: String?
    
    /// Images associated with this artist
    public let images: [Image]?

    /// URLs to the artist's resources
    public let resourceUrl: String?
    
    /// When this entity was created in the database
    public let uri: String?
    
    /// URLs to the artist's releases
    public let releasesUrl: String?
    
    /// Aliases of the artist
    public let aliases: [ArtistAlias]?
    
    /// Members of the artist group
    public let members: [ArtistMember]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case realName = "real_name"
        case urls
        case namevariations
        case profile
        case dataQuality = "data_quality"
        case images
        case resourceUrl = "resource_url"
        case uri
        case releasesUrl = "releases_url"
        case aliases
        case members
    }
}

/// An alias for an artist
public struct ArtistAlias: Codable, Sendable {
    /// The unique identifier for this alias
    public let id: Int
    
    /// The name of this alias
    public let name: String
    
    /// The resource URL for this alias
    public let resourceUrl: String
    
    /// Whether this is an active alias
    public let active: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case resourceUrl = "resource_url"
        case active
    }
}

/// A member of an artist group
public struct ArtistMember: Codable, Sendable {
    /// The unique identifier for this member
    public let id: Int
    
    /// The name of this member
    public let name: String
    
    /// The resource URL for this member
    public let resourceUrl: String
    
    /// Whether this is an active member
    public let active: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case resourceUrl = "resource_url"
        case active
    }
}

// MARK: - Release

/// A simplified release in the Discogs database (used in lists)
public struct Release: Codable, Sendable {
    /// The unique identifier for this release
    public let id: Int
    
    /// The title of the release
    public let title: String
    
    /// Status of the release
    public let status: String?
    
    /// The unique identifier for the release's master
    public let masterId: Int?
    
    /// The year the release was issued
    public let year: Int?
    
    /// The format of the release (e.g., Vinyl, CD, etc.)
    public let format: String?
    
    /// The label that issued the release
    public let label: String?
    
    /// The artist who created the release
    public let artist: String?
    
    /// URL to the resource
    public let resourceUrl: String?
    
    /// URL to the release
    public let uri: String?
    
    /// The catalog number of the release
    public let catno: String?
    
    /// Statistics for this release
    public let stats: ReleaseStats?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case masterId = "master_id"
        case year
        case format
        case label
        case artist
        case resourceUrl = "resource_url"
        case uri
        case catno
        case stats
    }
}

/// A detailed release in the Discogs database
public struct ReleaseDetails: Codable, Sendable {
    /// The unique identifier for this release
    public let id: Int
    
    /// The title of the release
    public let title: String
    
    /// The country where the release was issued
    public let country: String?
    
    /// The year the release was issued
    public let year: Int?
    
    /// The date the release was issued (as string)
    public let releasedFormatted: String?
    
    /// Notes about this release
    public let notes: String?
    
    /// Styles of music on this release
    public let styles: [String]?
    
    /// Genres of music on this release
    public let genres: [String]?
    
    /// The estimated value of this release
    public let estimatedWeight: Int?
    
    /// The formats this release is available in
    public let formats: [ReleaseFormat]?
    
    /// The unique identifier for the release's master
    public let masterId: Int?
    
    /// The artists who created this release
    public let artists: [ReleaseArtist]?
    
    /// Data quality indicator
    public let dataQuality: String?
    
    /// The community statistics for this release
    public let community: ReleaseCommunityInfo?
    
    /// The companies involved in this release
    public let companies: [ReleaseCompany]?
    
    /// The date this was added to the database
    public let dateAdded: String?
    
    /// The date this was last modified in the database
    public let dateChanged: String?
    
    /// The release's tracks
    public let tracklist: [ReleaseTrack]?
    
    /// The labels that issued this release
    public let labels: [ReleaseLabel]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case country
        case year
        case releasedFormatted = "released_formatted"
        case notes
        case styles
        case genres
        case estimatedWeight = "estimated_weight"
        case formats
        case masterId = "master_id"
        case artists
        case dataQuality = "data_quality"
        case community
        case companies
        case dateAdded = "date_added"
        case dateChanged = "date_changed"
        case tracklist
        case labels
    }
}

/// Statistics for a release
public struct ReleaseStats: Codable, Sendable {
    /// Community statistics for this release
    public let community: ReleaseCommunityStats?
}

/// Community statistics for a release
public struct ReleaseCommunityStats: Codable, Sendable {
    /// Number of users who want this release
    public let want: Int?
    
    /// Number of users who have this release
    public let have: Int?
}

/// Community information for a release
public struct ReleaseCommunityInfo: Codable, Sendable {
    /// Community status
    public let status: String?
    
    /// Rating information
    public let rating: ReleaseRatingInfo?
    
    /// Number of users who want this release
    public let want: Int?
    
    /// Number of users who have this release
    public let have: Int?
    
    /// User submissions
    public let contributors: [ReleaseContributor]?
    
    /// User data quality votes
    public let dataQuality: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case rating
        case want
        case have
        case contributors
        case dataQuality = "data_quality"
    }
}

/// Rating information for a release
public struct ReleaseRatingInfo: Codable, Sendable {
    /// The average rating
    public let average: Double?
    
    /// Number of ratings
    public let count: Int?
}

/// A contributor to a release in the database
public struct ReleaseContributor: Codable, Sendable {
    /// The username of the contributor
    public let username: String?
    
    /// The resource URL of the contributor
    public let resourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case resourceUrl = "resource_url"
    }
}

/// A user's rating of a release
public struct ReleaseRating: Codable, Sendable {
    /// The username
    public let username: String
    
    /// The release ID
    public let releaseId: Int
    
    /// The rating (1-5)
    public let rating: Int
    
    enum CodingKeys: String, CodingKey {
        case username
        case releaseId = "release_id"
        case rating
    }
}

/// The community rating of a release
public struct CommunityReleaseRating: Codable, Sendable {
    /// The rating information
    public let rating: ReleaseRatingInfo
}

/// The format of a release
public struct ReleaseFormat: Codable, Sendable {
    /// The name of the format (e.g., CD, Vinyl)
    public let name: String?
    
    /// Quantity of this format
    public let qty: String?
    
    /// Text describing the format
    public let text: String?
    
    /// Descriptions of the format
    public let descriptions: [String]?
}

/// An artist on a release
public struct ReleaseArtist: Codable, Sendable {
    /// The unique identifier for this artist
    public let id: Int?
    
    /// The name of this artist
    public let name: String?
    
    /// The artist's role on this release
    public let role: String?
    
    /// How the artist is joined with other artists in the list
    public let join: String?
    
    /// Resource URL for this artist
    public let resourceUrl: String?
    
    /// How the artist's name is shown
    public let anv: String?
    
    /// Whether this artist is the main artist
    public let tracks: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case role
        case join
        case resourceUrl = "resource_url"
        case anv
        case tracks
    }
}

/// A company involved with a release
public struct ReleaseCompany: Codable, Sendable {
    /// The unique identifier for this company
    public let id: Int?
    
    /// The name of this company
    public let name: String?
    
    /// The company's role on this release
    public let entityType: String?
    
    /// The catalog number assigned by this company
    public let catno: String?
    
    /// Resource URL for this company
    public let resourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case entityType = "entity_type"
        case catno
        case resourceUrl = "resource_url"
    }
}

/// A track on a release
public struct ReleaseTrack: Codable, Sendable {
    /// The position of this track on the release
    public let position: String?
    
    /// The title of this track
    public let title: String?
    
    /// The duration of this track
    public let duration: String?
    
    /// The type of track (e.g., "track", "heading", "index")
    public let type_: String?
    
    /// Artists who performed on this track
    public let artists: [ReleaseArtist]?
    
    /// Extra artists who contributed to this track
    public let extraartists: [ReleaseArtist]?
}

/// A label on a release
public struct ReleaseLabel: Codable, Sendable {
    /// The unique identifier for this label
    public let id: Int?
    
    /// The name of this label
    public let name: String?
    
    /// The catalog number assigned by this label
    public let catno: String?
    
    /// Resource URL for this label
    public let resourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case catno
        case resourceUrl = "resource_url"
    }
}

// MARK: - Master Release

/// A master release in the Discogs database
public struct MasterRelease: Codable, Sendable {
    /// The unique identifier for this master release
    public let id: Int
    
    /// The title of the master release
    public let title: String
    
    /// The year the master release was issued
    public let year: Int?
    
    /// The main release ID
    public let mainRelease: Int?
    
    /// URL to the main release
    public let mainReleaseUrl: String?
    
    /// The number of releases under this master
    public let versionsCount: Int?
    
    /// URL to the master release's versions
    public let versionsUrl: String?
    
    /// The artists who created this master release
    public let artists: [ReleaseArtist]?
    
    /// Styles of music on this master release
    public let styles: [String]?
    
    /// Genres of music on this master release
    public let genres: [String]?
    
    /// Images associated with this master release
    public let images: [Image]?
    
    /// Videos associated with this master release
    public let videos: [Video]?
    
    /// The tracklist for this master release
    public let tracklist: [ReleaseTrack]?
    
    /// Data quality indicator
    public let dataQuality: String?
    
    /// URLs to this master release
    public let uri: String?
    
    /// Resource URL for this master release
    public let resourceUrl: String?
    
    /// The lowest price this master was sold for
    public let lowestPrice: Double?
    
    /// The number of items for sale
    public let numForSale: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case year
        case mainRelease = "main_release"
        case mainReleaseUrl = "main_release_url"
        case versionsCount = "versions_count"
        case versionsUrl = "versions_url"
        case artists
        case styles
        case genres
        case images
        case videos
        case tracklist
        case dataQuality = "data_quality"
        case uri
        case resourceUrl = "resource_url"
        case lowestPrice = "lowest_price"
        case numForSale = "num_for_sale"
    }
}

/// A version of a master release
public struct ReleaseVersion: Codable, Sendable {
    /// The unique identifier for this release
    public let id: Int?
    
    /// The catalog number assigned to this release
    public let catno: String?
    
    /// The country where this release was issued
    public let country: String?
    
    /// The year this release was issued
    public let year: Int?
    
    /// The title of this release
    public let title: String?
    
    /// The label that issued this release
    public let label: String?
    
    /// The format of this release
    public let format: String?
    
    /// The resource URL for this release
    public let resourceUrl: String?
    
    /// The major format of this release
    public let majorFormats: [String]?
    
    /// The minor format of this release
    public let minorFormats: [String]?
    
    /// Status of this release
    public let status: String?
    
    /// Statistics for this release
    public let stats: ReleaseStats?
    
    /// The thumbnail image URL
    public let thumb: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case catno
        case country
        case year
        case title
        case label
        case format
        case resourceUrl = "resource_url"
        case majorFormats = "major_formats"
        case minorFormats = "minor_formats"
        case status
        case stats
        case thumb
    }
}

// MARK: - Label

/// A label in the Discogs database
public struct Label: Codable, Sendable {
    /// The unique identifier for this label
    public let id: Int
    
    /// The name of this label
    public let name: String
    
    /// The contact information for this label
    public let contactInfo: String?
    
    /// The profile of this label
    public let profile: String?
    
    /// The parent label name
    public let parentLabel: String?
    
    /// The data quality indicator
    public let dataQuality: String?
    
    /// URLs associated with this label
    public let urls: [String]?
    
    /// Images for this label
    public let images: [Image]?
    
    /// Resource URL for this label
    public let resourceUrl: String?
    
    /// URI for this label
    public let uri: String?
    
    /// Releases URL for this label
    public let releasesUrl: String?
    
    /// Sublabels belonging to this label
    public let sublabels: [Sublabel]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contactInfo = "contact_info"
        case profile
        case parentLabel = "parent_label"
        case dataQuality = "data_quality"
        case urls
        case images
        case resourceUrl = "resource_url"
        case uri
        case releasesUrl = "releases_url"
        case sublabels
    }
}

/// A sublabel belonging to a parent label
public struct Sublabel: Codable, Sendable {
    /// The unique identifier for this sublabel
    public let id: Int
    
    /// The name of this sublabel
    public let name: String
    
    /// Resource URL for this sublabel
    public let resourceUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case resourceUrl = "resource_url"
    }
}

// MARK: - Common

/// An image in the Discogs database
public struct Image: Codable, Sendable {
    /// The type of image
    public let type: String?
    
    /// The URL of the image
    public let uri: String?
    
    /// The URL of the image (with authentication)
    public let resourceUrl: String?
    
    /// The URL of the image's thumbnail
    public let uri150: String?
    
    /// The width of the image
    public let width: Int?
    
    /// The height of the image
    public let height: Int?
    
    enum CodingKeys: String, CodingKey {
        case type
        case uri
        case resourceUrl = "resource_url"
        case uri150
        case width
        case height
    }
}

/// A video in the Discogs database
public struct Video: Codable, Sendable {
    /// The URL of the video
    public let uri: String
    
    /// The title of the video
    public let title: String?
    
    /// The description of the video
    public let description: String?
    
    /// The duration of the video
    public let duration: Int?
    
    /// Whether the video is embeddable
    public let embed: Bool?
}
