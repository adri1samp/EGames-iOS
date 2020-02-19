import Foundation

struct Comentario: Codable {
    var id: Int
    var idusuario: Int
    var idjuego: Int
    var fecha: String
    var comentario: String
    var alias: String?
    
    enum CodingKeys: String, CodingKey
    {
        case id = "id"
        case idusuario = "idusuario"
        case idjuego = "idjuego"
        case fecha = "fecha"
        case comentario = "comentario"
        case alias = "alias"
    }
}
