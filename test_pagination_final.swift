import Foundation

// Copy of the fixed Pagination structs (without explicit CodingKeys)
struct Pagination: Codable, Sendable {
    public let page: Int
    public let perPage: Int
    public let items: Int
    public let pages: Int
    public let urls: PaginationURLs?
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
    "pages": 2,
    "urls": {
        "first": "https://api.discogs.com/database/search?page=1",
        "last": "https://api.discogs.com/database/search?page=2",
        "next": "https://api.discogs.com/database/search?page=2"
    }
}
"""

let jsonData = jsonString.data(using: .utf8)!
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

do {
    let pagination = try decoder.decode(Pagination.self, from: jsonData)
    print("✅ SUCCESS: Pagination decoded correctly!")
    print("  page: \(pagination.page)")
    print("  perPage: \(pagination.perPage)")
    print("  items: \(pagination.items)")
    print("  pages: \(pagination.pages)")
    if let urls = pagination.urls {
        print("  URLs: first=\(urls.first ?? "nil"), last=\(urls.last ?? "nil"), next=\(urls.next ?? "nil")")
    }
} catch {
    print("❌ ERROR: \(error)")
}
