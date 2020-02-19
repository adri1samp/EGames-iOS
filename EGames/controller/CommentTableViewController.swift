import UIKit

class CommentTableViewController: UITableViewController {
    //MARK: VARS
    var juegoActual: Juego!
    var usuarioActual: Usuario!
    var comentarios: [Comentario] = [Comentario]()
    
    //MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        loadComments()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comentarios.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentTableViewCell
        
        cell.lbUsername.text = comentarios[indexPath.row].alias
        cell.tvComment.text = comentarios[indexPath.row].comentario
        if usuarioActual.id != comentarios[indexPath.row].idusuario {
            cell.btDelete.isHidden = true
        }
        else {
            cell.btDelete.isHidden = false
            cell.btDelete.tag = indexPath.row
            cell.btDelete.addTarget(self, action: #selector(deleteComment), for: .touchUpInside)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: ACTIONS
    @IBAction func addNewComment(_ sender: UIBarButtonItem) {
        let alertAdd = UIAlertController(title: "Añadir comentario", message: nil, preferredStyle: .alert)
        alertAdd.addTextField { (textField) in
            textField.text = ""
        }
        alertAdd.addAction(UIAlertAction(title: "Cancelar", style: UIAlertAction.Style.destructive, handler: nil))
        alertAdd.addAction(UIAlertAction(title: "Añadir", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction) in
            let textfieldComment = alertAdd.textFields![0]
            if(textfieldComment.text!.isEmpty){
                Alerts.errorAlert(self, "El comentario no puede estar vacio")
            } else {
                Alerts.loadScreenAlert(self, "Añadiendo...") {
                    let finalDate = Functions.dateTimeToString(Date())
                    let comentario: [String: Any] = [
                        "idusuario": self.usuarioActual.id,
                        "idjuego": self.juegoActual.id,
                        "fecha": finalDate,
                        "comentario": textfieldComment.text!,
                    ]
                    let _ = HttpClient.post("comentario", comentario) { (data, response, error) in
                        let response = response as! HTTPURLResponse
                        if response.statusCode != 200{
                            DispatchQueue.main.async {
                                self.dismiss(animated: false, completion: { //quita pantalla de carga
                                    Alerts.errorAlert(self, "No se ha podido guardar el comentario")
                                })
                            }
                            return
                        }
                        do {
                            var comentario: Comentario = try JSONDecoder().decode(Comentario.self, from: data!)
                            comentario.alias = self.usuarioActual.alias
                            self.comentarios.append(comentario)
                            DispatchQueue.main.async {
                                self.dismiss(animated: false, completion: { //quita pantalla de carga
                                    self.tableView.reloadData()
                                })
                            }
                        }
                        catch let parsingError {
                            DispatchQueue.main.async {
                                self.dismiss(animated: false, completion: { //quita pantalla de carga
                                    Alerts.errorAlert(self, "Ha ocurrido un error: " + parsingError.localizedDescription)
                                })
                            }
                        }
                    }
                }
            }

        }))
        present(alertAdd, animated: true, completion: nil)
    }
    
    
    //MARK: FUNCS
    private func loadComments() {
        Alerts.loadScreenAlert(self, "Cargando...") {
            //Realizo Peticion
            let _ = HttpClient.get("comentario/juego/\(self.juegoActual.id)") { (data, response, error) in
                let response = response as! HTTPURLResponse
                if response.statusCode != 200 {
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            Alerts.errorAlert(self, "No se han podido cargar los comentarios")
                        })
                    }
                    return
                }
                
                do {
                    self.comentarios = try JSONDecoder().decode([Comentario].self, from: data!)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.dismiss(animated: false, completion: nil)
                    }
                }
                catch let parsingError {
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            Alerts.errorAlert(self, "Ha ocurrido un error: " + parsingError.localizedDescription)
                        })
                    }
                }
            }
        }
    }
    
    @objc func deleteComment(sender: UIButton) {
        let posicion = sender.tag
        let idcomment = self.comentarios[posicion].id
        
        let alert = UIAlertController(title: "Eliminar", message: "¿Estás seguro de que quieres eliminar tu comentario?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Eliminar", style: UIAlertAction.Style.destructive, handler: {(_: UIAlertAction!) in
            Alerts.loadScreenAlert(self, "Eliminando...") {
                let _ = HttpClient.delete("comentario/\(idcomment)") { (data, response, error) in
                    let response = response as! HTTPURLResponse
                    if response.statusCode != 200 {
                        self.dismiss(animated: true) {
                            Alerts.errorAlert(self, "No se ha podido borrar tu comentario")
                        }
                        return
                    }
                    
                    self.comentarios.remove(at: posicion)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}
