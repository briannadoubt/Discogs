import Foundation

// Import the Discogs models
import Discogs

let jsonString = """
{
    "pagination": {
        "page": 1,
        "per_page": 50,
        "items": 100,
        "pages": 2
    },
    "results": [
        {"id": 1, "name": "Test Item 1"},
        {"id": 2, "name": "Test Item 2"}
    ]
}
"""

struct TestItem: Codable, Sendable {
    let id: Int
    let name: String
}

let jsonData = jsonString.data(using: .utf8)!

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

do {
    let response = try decoder.decode(PaginatedResponse<TestItem>.self, from: jsonData)
    print("SUCCESS: Decoded response with \(response.items.count) items")
    print("Pagination: page=\(response.pagination.page), perPage=\(response.pagination.perPage)")
} catch {
    print("ERROR: \(error)")
}
