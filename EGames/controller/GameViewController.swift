import UIKit

class GameViewController: UIViewController, UINavigationControllerDelegate, GameViewDelegate {
    //MARK: OUTLETS
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var tvDescription: UITextView!
    @IBOutlet weak var lbTypeValue: UILabel!
    @IBOutlet weak var lbReleaseDateValue: UILabel!
    @IBOutlet var avgStars: [UIImageView]!
    @IBOutlet weak var svUserStars: UIStackView!
    @IBOutlet var userStars: [UIButton]!
    
    //MARK: VARS
    weak var mainViewDelegate: MainViewDelegate!
    var juego: Juego!
    var usuario: Usuario!
    var valoracion: Valoracion?
    
    //MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //assigns
        assignGameInfo()
        
        //cargar valoracion del usuario actual
        svUserStars.isUserInteractionEnabled = false
        let _ = HttpClient.get("valoracion/usuario/" + String(usuario.id) + "/juego/" + String(juego.id)) { (data, response, error) in
            DispatchQueue.main.async {
                self.svUserStars.isUserInteractionEnabled = true
            }
            do {
                let valoracion = try JSONDecoder().decode(Valoracion.self, from: data!)
                if valoracion.id > 0 {
                    self.valoracion = valoracion
                    DispatchQueue.main.async {
                        Functions.unprintStars(stars: self.userStars)
                        Functions.printStars(valoracion: Double(valoracion.valoracion), stars: self.userStars)
                    }
                }
            }
            catch {
            }
        }
    }
    
    //MARK: ACTIONS
    @IBAction func unwindToGame(unwindSegue: UIStoryboardSegue) {
        if let editGameViewController = unwindSegue.source as? EditGameViewController {
            //juego actualizado
            mainViewDelegate.updateGame(oldJuego: juego, newJuego: editGameViewController.juego!)
            juego = editGameViewController.juego
            assignGameInfo()
        }
    }
    
    @IBAction func userStarClicked(_ sender: UIButton) {
        setUserRating(sender.tag)
    }
    
    @IBAction func optionsOnClick(_ sender: UIBarButtonItem) {
        let addGame = UIAlertAction(title: "Modificar", style: .default, handler:
        {
            (alert: UIAlertAction!) -> Void in
            self.performSegue(withIdentifier: "editGame", sender: self)
        })
        let logout = UIAlertAction(title: "Eliminar", style: .destructive, handler:
        {
            (alert: UIAlertAction!) -> Void in
            let confirmAlert = UIAlertController(title: "Eliminar", message: "¿Estás seguro de que quieres eliminar este juego?", preferredStyle: UIAlertController.Style.alert)
            confirmAlert.addAction(UIAlertAction(title: "Eliminar", style: .destructive, handler: { (action: UIAlertAction!) in
                self.deleteGame()
            }))
            confirmAlert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
            self.present(confirmAlert, animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(addGame)
        alert.addAction(logout)
        alert.addAction(cancel)
        alert.popoverPresentationController?.barButtonItem = sender //para el iPad
        present(alert, animated: true)
    }
    
    //MARK: FUNCTIONS
    private func setUserRating(_ nuevaValoracion: Int) {
        Functions.unprintStars(stars: userStars)
        Functions.printStars(valoracion: Double(nuevaValoracion), stars: userStars)

        //insertar o actualizar valoracion
        svUserStars.isUserInteractionEnabled = false
        if valoracion == nil { //no hay valoracion, añadir
            let valoracion: [String: Any] = [
                "idusuario": usuario.id,
                "idjuego": juego.id,
                "valoracion": nuevaValoracion
            ]
            let _ = HttpClient.post("valoracion", valoracion) { (data, response, error) in
                do {
                    let valoracion = try JSONDecoder().decode(Valoracion.self, from: data!)
                    if valoracion.id > 0 {
                        self.valoracion = valoracion
                        self.reloadGameRating()
                    }
                }
                catch {
                }
            }
        }
        else { //hay valoracion, actualizar
            self.valoracion?.valoracion = nuevaValoracion
            let httpValoracion: [String: Any] = [
                "valoracion": self.valoracion!.valoracion
            ]
            let _ = HttpClient.put("valoracion/" + String(self.valoracion!.id), httpValoracion) { (data, response, error) in
                self.reloadGameRating()
            }
        }
    }
    
    private func reloadGameRating() {
        let _ = HttpClient.get("juego2/" + String(juego.id)) { (data, response, error) in
            DispatchQueue.main.async {
                self.svUserStars.isUserInteractionEnabled = true
            }
            do {
                let juego = try JSONDecoder().decode(Juego.self, from: data!)
                if juego.id > 0 {
                    DispatchQueue.main.async {
                        self.mainViewDelegate.updateGame(oldJuego: self.juego, newJuego: juego)
                        Functions.unprintStars(stars: self.avgStars)
                        if juego.valoracion != nil {
                            Functions.printStars(valoracion: Double(juego.valoracion!)!, stars: self.avgStars)
                        }
                    }
                }
            }
            catch {
            }
        }
    }
    
    private func assignGameInfo() {
        lbTitle.text = juego.titulo
        let imageUrl: String = "https://informatica.ieszaidinvergeles.org:9061/egames/images/juegos/" + String(juego.id) + ".jpg"
        Functions.setImageFromUrl(url: imageUrl, image: ivImage)
        tvDescription.text = juego.descripcion
        lbTypeValue.text = juego.tipo
        lbReleaseDateValue.text = juego.fecha_lanzamiento
        
        if let valoracion = juego.valoracion {
            if let valoracion = Double(valoracion) {
                Functions.printStars(valoracion: valoracion, stars: avgStars)
            }
        }
    }
    
    private func deleteGame() {
        //poner pantalla de carga
        Alerts.loadScreenAlert(self, "Espere...") {
            //realizar peticion de borrado
            let _ = HttpClient.delete("juego/" + String(self.juego.id)) { (data, response, error) in
                let response = response as! HTTPURLResponse
                if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            Alerts.errorAlert(self, "No se ha podido borrar el juego")
                        })
                    }
                    return
                }
                
                //juego borrado
                DispatchQueue.main.async {
                    self.dismiss(animated: false, completion: { //quita pantalla de carga
                        self.performSegue(withIdentifier: "unwindToMain", sender: self)
                    })
                }
            }
        }
    }
    
    func reloadDeletedRating(){
        valoracion = nil
        Functions.unprintStars(stars: userStars)
        self.reloadGameRating()
    }
    
    //MARK: NAVIGATION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editGame" {
            let editGameViewController = segue.destination as! EditGameViewController
            editGameViewController.juego = juego
            editGameViewController.imagePassed = ivImage.image
        }
        else if segue.identifier == "ratingsList" {
            let ratingTableViewController = segue.destination as! RatingTableViewController
            ratingTableViewController.usuario = usuario
            ratingTableViewController.juego = juego
            ratingTableViewController.gameViewDelegate = self
        }
        else if segue.identifier == "commentsList" {
            let commentTableViewController = segue.destination as! CommentTableViewController 
            commentTableViewController.juegoActual = juego
            commentTableViewController.usuarioActual = usuario
        }
    }
}

protocol GameViewDelegate: class {
    func reloadDeletedRating()
}
