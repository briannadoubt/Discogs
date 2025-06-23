import Foundation

/// Service for interacting with the Discogs database API
/// This includes artists, releases, masters, and labels
public struct DatabaseService: DiscogsServiceProtocol {
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

    // MARK: - Artist Methods

    /// Get an artist by ID
    /// - Parameter id: Artist ID
    public func getArtist(id: Int) async throws -> Artist {
        try await performRequest(endpoint: "artists/\(id)")
    }

    /// Get an artist's releases
    /// - Parameters:
    ///   - artistId: Artist ID
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    ///   - sort: Sort order
    ///   - sortOrder: Sort direction
    public func getArtistReleases(
        artistId: Int,
        page: Int = 1,
        perPage: Int = 50,
        sort: ArtistReleasesSort = .year,
        sortOrder: SortOrder = .descending
    ) async throws -> PaginatedResponse<Release> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage),
            "sort": sort.rawValue,
            "sort_order": sortOrder.rawValue
        ]
        return try await performRequest(endpoint: "artists/\(artistId)/releases", parameters: parameters)
    }

    // MARK: - Release Methods

    /// Get a release by ID
    /// - Parameters:
    ///   - id: Release ID
    ///   - currency: Currency for marketplace data (optional, must be a valid ISO currency code)
    public func getRelease(id: Int, currency: String? = nil) async throws -> ReleaseDetails {
        var parameters: [String: String] = [:]
        if let currency = currency {
            guard SupportedCurrency.isValid(currency) else {
                throw DiscogsError.invalidInput("Currency '\(currency)' is not supported. Supported currencies: \(SupportedCurrency.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            parameters["curr_abbr"] = currency
        }
        return try await performRequest(endpoint: "releases/\(id)", parameters: parameters)
    }

    /// Get a release's rating by a specific user
    /// - Parameters:
    ///   - releaseId: Release ID
    ///   - username: Username
    public func getReleaseRating(releaseId: Int, username: String) async throws -> ReleaseRating {
        try await performRequest(endpoint: "releases/\(releaseId)/rating/\(username)")
    }

    /// Update a release's rating
    /// - Parameters:
    ///   - releaseId: Release ID
    ///   - username: Username
    ///   - rating: Rating value (1-5)
    public func updateReleaseRating(releaseId: Int, username: String, rating: Int) async throws -> ReleaseRating {
        guard (1...5).contains(rating) else {
            throw DiscogsError.invalidInput("Rating must be between 1 and 5")
        }
        return try await performRequest(
            endpoint: "releases/\(releaseId)/rating/\(username)",
            method: .put,
            body: ["rating": rating] as [String: any Sendable]
        )
    }

    /// Delete a release's rating
    /// - Parameters:
    ///   - releaseId: Release ID
    ///   - username: Username
    public func deleteReleaseRating(releaseId: Int, username: String) async throws -> SuccessResponse {
        try await performRequest(
            endpoint: "releases/\(releaseId)/rating/\(username)",
            method: .delete
        )
    }

    /// Get the community release rating
    /// - Parameter releaseId: Release ID
    public func getCommunityReleaseRating(releaseId: Int) async throws -> CommunityReleaseRating {
        try await performRequest(endpoint: "releases/\(releaseId)/rating")
    }

    // MARK: - Master Release Methods

    /// Get a master release by ID
    /// - Parameter id: Master release ID
    public func getMasterRelease(id: Int) async throws -> MasterRelease {
        try await performRequest(endpoint: "masters/\(id)")
    }

    /// Get a master release's versions
    /// - Parameters:
    ///   - masterId: Master release ID
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    public func getMasterReleaseVersions(
        masterId: Int,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> PaginatedResponse<ReleaseVersion> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage)
        ]
        return try await performRequest(endpoint: "masters/\(masterId)/versions", parameters: parameters)
    }

    // MARK: - Label Methods

    /// Get a label by ID
    /// - Parameter id: Label ID
    public func getLabel(id: Int) async throws -> RecordLabel {
        try await performRequest(endpoint: "labels/\(id)")
    }

    /// Get a label's releases
    /// - Parameters:
    ///   - labelId: Label ID
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    public func getLabelReleases(
        labelId: Int,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> PaginatedResponse<Release> {
        let parameters = [
            "page": String(page),
            "per_page": String(perPage)
        ]
        return try await performRequest(endpoint: "labels/\(labelId)/releases", parameters: parameters)
    }
}

// MARK: - Currency Support

extension DatabaseService {
    /// Supported currencies for marketplace data
    /// 
    /// These are the currencies supported by the Discogs API for marketplace
    /// listings and pricing information.
    public enum SupportedCurrency: String, CaseIterable, Sendable {
        /// US Dollar
        case usd = "USD"
        /// Euro
        case eur = "EUR"
        /// British Pound
        case gbp = "GBP"
        /// Japanese Yen
        case jpy = "JPY"
        /// Canadian Dollar
        case cad = "CAD"
        /// Australian Dollar
        case aud = "AUD"
        /// Swedish Krona
        case sek = "SEK"
        /// New Zealand Dollar
        case nzd = "NZD"
        /// Mexican Peso
        case mxn = "MXN"
        /// Brazilian Real
        case brl = "BRL"
        /// South African Rand
        case zar = "ZAR"
        
        /// Check if a currency code is valid
        /// - Parameter code: The currency code to validate
        /// - Returns: `true` if the currency is supported, `false` otherwise
        public static func isValid(_ code: String) -> Bool {
            return allCases.contains { $0.rawValue.caseInsensitiveCompare(code) == .orderedSame }
        }
    }
}

// MARK: - Sort Options

extension DatabaseService {
    /// Sort options for artist releases
    public enum ArtistReleasesSort: String, Sendable {
        /// Sort by year
        case year
        /// Sort by title
        case title
        /// Sort by format
        case format
    }

    /// Sort direction for database queries
    public enum SortOrder: String, Sendable {
        /// Ascending order (A-Z, oldest to newest)
        case ascending = "asc"
        /// Descending order (Z-A, newest to oldest)
        case descending = "desc"
    }
}
