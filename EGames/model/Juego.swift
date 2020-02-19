import Foundation

struct Juego: Codable, Comparable {
    var id: Int
    var titulo: String
    var tipo: String
    var fecha_lanzamiento: String
    var descripcion: String
    var valoracion: String?
    
    enum CodingKeys: String, CodingKey
    {
        case id = "id"
        case titulo = "titulo"
        case tipo = "tipo"
        case fecha_lanzamiento = "fecha_lanzamiento"
        case descripcion = "descripcion"
        case valoracion = "valoracion"
    }
    
    static func < (juego1: Juego, juego2: Juego) -> Bool {
        return juego1.titulo < juego2.titulo
    }
    
    
    static func == (juego1: Juego, juego2: Juego) -> Bool {
        return juego1.titulo == juego2.titulo
    }
}

//MARK: TEST
struct JuegoSection {
    let firstLetter: String
    let juegos: [Juego]
}
