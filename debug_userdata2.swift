import Foundation

struct UserData: Codable {
    let inCollection: Bool?
    let inWantlist: Bool?
}

let json = """
{
    "in_wantlist": true,
    "in_collection": false
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
do {
    let userData = try decoder.decode(UserData.self, from: json)
    print("inWantlist: \(userData.inWantlist)")
    print("inCollection: \(userData.inCollection)")
} catch {
    print("Error: \(error)")
}
