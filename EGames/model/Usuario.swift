import Foundation

struct Usuario: Codable {
    var id: Int
    var alias: String
    var correo: String
    var password: String
    
    enum CodingKeys: String, CodingKey
    {
        case id = "id"
        case alias = "alias"
        case correo = "correo"
        case password = "password"
    }
}
