import Foundation

struct UserData: Codable {
    let inCollection: Bool?
    let inWantlist: Bool?
}

struct SearchResult: Codable {
    let id: Int
    let type: String
    let userData: UserData?
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
    print("userData: \(result.userData)")
    if let userData = result.userData {
        print("inWantlist: \(userData.inWantlist)")
        print("inCollection: \(userData.inCollection)")
    } else {
        print("userData is nil")
    }
} catch {
    print("Error: \(error)")
}
