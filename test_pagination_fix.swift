import Foundation

// Simple test for Pagination decoding
struct Pagination: Codable, Sendable {
    public let page: Int
    public let perPage: Int
    public let items: Int
    public let pages: Int
    public let urls: PaginationURLs?
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case items
        case pages
        case urls
    }
}

struct PaginationURLs: Codable, Sendable {
    public let first: String?
    public let last: String?
    public let prev: String?
    public let next: String?
}

let jsonString = """
{
    "page": 1,
    "per_page": 50,
    "items": 100,
    "pages": 2
}
"""

let jsonData = jsonString.data(using: .utf8)!
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

do {
    let pagination = try decoder.decode(Pagination.self, from: jsonData)
    print("SUCCESS: page=\(pagination.page), perPage=\(pagination.perPage), items=\(pagination.items)")
} catch {
    print("ERROR: \(error)")
}
