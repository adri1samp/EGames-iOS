import Foundation

struct Valoracion: Codable {
    var id: Int
    var idusuario: Int
    var idjuego: Int
    var valoracion: Int
    var alias: String?
    
    enum CodingKeys: String, CodingKey
    {
        case id = "id"
        case idusuario = "idusuario"
        case idjuego = "idjuego"
        case valoracion = "valoracion"
        case alias = "alias"
    }
}
