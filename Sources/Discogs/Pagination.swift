import Foundation

/// Standard pagination parameters used by the Discogs API
public struct Pagination: Codable, Sendable {
    /// Page number
    public let page: Int
    
    /// Items per page
    public let perPage: Int
    
    /// Total number of items
    public let items: Int
    
    /// Total number of pages
    public let pages: Int
    
    /// URLs for navigating between pages
    public let urls: PaginationURLs?
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case items
        case pages
        case urls
    }
}

/// URLs for navigating between paginated results
public struct PaginationURLs: Codable, Sendable {
    /// URL for the first page
    public let first: String?
    
    /// URL for the last page
    public let last: String?
    
    /// URL for the previous page
    public let prev: String?
    
    /// URL for the next page
    public let next: String?
}