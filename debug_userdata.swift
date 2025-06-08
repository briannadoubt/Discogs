import Foundation

struct UserData: Codable {
    let inCollection: Bool?
    let inWantlist: Bool?
    
    enum CodingKeys: String, CodingKey {
        case inCollection = "in_collection"
        case inWantlist = "in_wantlist"
    }
}

let json = """
{
    "in_wantlist": true,
    "in_collection": false
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
do {
    let userData = try decoder.decode(UserData.self, from: json)
    print("inWantlist: \(userData.inWantlist)")
    print("inCollection: \(userData.inCollection)")
} catch {
    print("Error: \(error)")
}
