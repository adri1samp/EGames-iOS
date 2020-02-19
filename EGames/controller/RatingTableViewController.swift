import UIKit

class RatingTableViewController: UITableViewController {
    //MARK: VARS
    var usuario: Usuario!
    var juego: Juego!
    var valoraciones: [Valoracion] = [Valoracion]()
    weak var gameViewDelegate: GameViewDelegate!
    
    //MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        loadRatings()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return valoraciones.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ratingCell", for: indexPath) as! RatingTableViewCell
            
        cell.lbUsername.text = valoraciones[indexPath.row].alias
    
        Functions.unprintStars(stars: cell.stars)
        Functions.printStars(valoracion: Double(valoraciones[indexPath.row].valoracion), stars: cell.stars)
        
        if usuario.id != valoraciones[indexPath.row].idusuario {
            cell.btDelete.isHidden = true
        }
        else {
            cell.btDelete.isHidden = false
            cell.btDelete.tag = indexPath.row
            cell.btDelete.addTarget(self, action: #selector(deleteRating), for: .touchUpInside)
        }
        return cell
    }
    
    //MARK: FUNCS
    private func loadRatings() {
        Alerts.loadScreenAlert(self, "Cargando...") {
            let _ = HttpClient.get("valoracion/juego/" + String(self.juego.id)) {
                (data, response, error) in
                let response = response as! HTTPURLResponse
                if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            Alerts.errorAlert(self, "No se han podido cargar las valoraciones")
                        })
                    }
                    return
                }
                do {
                    self.valoraciones = try JSONDecoder().decode([Valoracion].self, from: data!)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.dismiss(animated: false, completion: nil) //quita pantalla de carga
                    }
                    
                }
                catch let parsingError {
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: {Alerts.errorAlert(self, "No se han podido cargar las valoraciones: " + parsingError.localizedDescription)}) //quita la pantalla de carga
                    }
                }
            }
        }
    }
    
    @objc func deleteRating(sender: UIButton) {
        let positionRatingList = sender.tag
        let valoracionId = valoraciones[positionRatingList].id
        
        let confirmAlert = UIAlertController(title: "Eliminar", message: "¿Estás seguro de que quieres eliminar tu valoración?", preferredStyle: UIAlertController.Style.alert)
        confirmAlert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: "Eliminar", style: .destructive, handler: { (action: UIAlertAction!) in
            Alerts.loadScreenAlert(self, "Eliminando...") {
                let _ = HttpClient.delete("valoracion/" + String(valoracionId)) {
                    (data, response, error) in
                    let response = response as! HTTPURLResponse
                    if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                        DispatchQueue.main.async {
                            self.dismiss(animated: false, completion: { //quita pantalla de carga
                                Alerts.errorAlert(self, "No se ha podido borrar tu valoración")
                            })
                        }
                        return
                    }
                        
                    DispatchQueue.main.async {
                        self.valoraciones.remove(at: positionRatingList)
                        self.gameViewDelegate.reloadDeletedRating()//recarga de la valoracion en single juego
                        self.tableView.reloadData()
                        self.dismiss(animated: false, completion: nil) //quita pantalla de carga
                    }
                }
            }
        }))
        confirmAlert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        self.present(confirmAlert, animated: true, completion: nil)
    }
}
