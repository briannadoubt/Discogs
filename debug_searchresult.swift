import Foundation

struct UserData: Codable {
    let inCollection: Bool?
    let inWantlist: Bool?
}

struct SearchResult: Codable {
    let id: Int
    let type: String
    let user_data: UserData?
    let title: String?
}

let json = """
{
    "id": 12345,
    "type": "release",
    "user_data": {
        "in_wantlist": true,
        "in_collection": false
    },
    "title": "Abbey Road"
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
do {
    let result = try decoder.decode(SearchResult.self, from: json)
    print("id: \(result.id)")
    print("user_data: \(result.user_data)")
    if let userData = result.user_data {
        print("inWantlist: \(userData.inWantlist)")
        print("inCollection: \(userData.inCollection)")
    } else {
        print("user_data is nil")
    }
} catch {
    print("Error: \(error)")
}
