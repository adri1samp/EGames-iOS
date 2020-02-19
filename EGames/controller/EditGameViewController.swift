import UIKit

class EditGameViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //MARK: OUTLETS
    @IBOutlet weak var navBarRightButton: UIBarButtonItem!
    @IBOutlet weak var tfTitle: UITextField!
    @IBOutlet weak var tfType: UITextField!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var dpReleaseDate: UIDatePicker!
    @IBOutlet weak var tvDescription: UITextView!
    
    //MARK: VARS
    var juego: Juego?
    var imageSelected: Bool = false
    var imagePassed: UIImage?

    //MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //assigns
        if let juego = juego {
            self.title = "Editar juego"
            navBarRightButton.title = "Actualizar"
            tfTitle.text = juego.titulo
            tfType.text = juego.tipo
            if let imagePassed = imagePassed {
                ivImage.image = imagePassed
            }
            dpReleaseDate.date = Functions.stringToDate(juego.fecha_lanzamiento)
            tvDescription.text = juego.descripcion
        }

        //delegates
        tfTitle.delegate = self
        tfType.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == tfTitle {
            tfType.becomeFirstResponder()
        }
        return false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following:\(info)")
        }
        
        imageSelected = true
        ivImage.image = selectedImage
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: ACTIONS
    @IBAction func ivImageOnClick(_ sender: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func navBarRightButtonOnClick(_ sender: UIBarButtonItem) {
        //comprobacion de todos los campos (que no esten vacios)
        guard
            let title: String = tfTitle.text, !title.isEmpty,
            let type: String = tfType.text, !type.isEmpty,
            let description: String = tvDescription.text, !description.isEmpty
        else {
            Alerts.errorAlert(self, "Rellene todos los campos")
            return
        }
        
        if juego == nil { //añadir
            //poner pantalla de carga
            Alerts.loadScreenAlert(self, "Subiendo...") {
                let releaseDate: String = Functions.dateToString(self.dpReleaseDate.date)
                let juego: [String: Any] = [
                    "titulo": title,
                    "tipo": type,
                    "fecha_lanzamiento": releaseDate,
                    "descripcion": description
                ]
                let _ = HttpClient.post("juego", juego) { (data, response, error) in
                    let response = response as! HTTPURLResponse
                    if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                        DispatchQueue.main.async {
                            self.dismiss(animated: false, completion: { //quita pantalla de carga
                                Alerts.errorAlert(self, "Ya hay otro juego con el mismo nombre")
                            })
                        }
                        return
                    }
                    
                    //obtener juego para añadirlo a la lista principal
                    do {
                        let juego = try JSONDecoder().decode(Juego.self, from: data!)
                        if juego.id > 0 {
                            //todo OK: juego con id valida
                            self.juego = juego
                            DispatchQueue.main.async {
                                if self.imageSelected { //subir img si ha seleccionado
                                    let data = self.ivImage.image?.jpegData(compressionQuality: 0.2)
                                    let fileName: String = String(juego.id) + ".jpg"
                                    let _ = HttpClient.upload(route: "juego/upload_image", fileParameter: "file", fileName: fileName, fileData: data!) { (data, response, error) in
                                        DispatchQueue.main.async {
                                            self.dismiss(animated: false, completion: {
                                                self.performSegue(withIdentifier: "unwindToMain", sender: self)
                                            })
                                        }
                                    }
                                }
                                else {
                                    self.dismiss(animated: false, completion: { //quita pantalla de carga
                                        self.performSegue(withIdentifier: "unwindToMain", sender: self)
                                    })
                                }
                            }
                        }
                        else {
                            DispatchQueue.main.async {
                                self.dismiss(animated: false, completion: { //quita pantalla de carga
                                    Alerts.errorAlert(self, "Ha ocurrido un error")
                                })
                            }
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
        else { //actualizar
            //poner pantalla de carga
            Alerts.loadScreenAlert(self, "Actualizando...") {
                let releaseDate: String = Functions.dateToString(self.dpReleaseDate.date)
                //actualizar objeto para pasarlo
                self.juego?.titulo = title
                self.juego?.tipo = type
                self.juego?.fecha_lanzamiento = releaseDate
                self.juego?.descripcion = description
                
                let juego: [String: Any] = [
                    "titulo": title,
                    "tipo": type,
                    "fecha_lanzamiento": releaseDate,
                    "descripcion": description
                ]
                let _ = HttpClient.put("juego/" + String(self.juego!.id), juego) { (data, response, error) in
                    let response = response as! HTTPURLResponse
                    if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                        DispatchQueue.main.async {
                            self.dismiss(animated: false, completion: { //quita pantalla de carga
                                Alerts.errorAlert(self, "No se ha podido actualizar el juego, ¿puede que el nuevo título esté en uso?")
                            })
                        }
                        return
                    }
                    
                    if self.imageSelected { //subir img si ha seleccionado
                        DispatchQueue.main.async {
                            let data = self.ivImage.image?.jpegData(compressionQuality: 0.2)
                            let fileName: String = String(self.juego!.id) + ".jpg"
                            let _ = HttpClient.upload(route: "juego/upload_image", fileParameter: "file", fileName: fileName, fileData: data!) { (data, response, error) in
                                DispatchQueue.main.async {
                                    self.dismiss(animated: false, completion: {
                                        self.performSegue(withIdentifier: "unwindToGame", sender: self)
                                    })
                                }
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            self.dismiss(animated: false, completion: { //quita pantalla de carga
                                self.performSegue(withIdentifier: "unwindToGame", sender: self)
                            })
                        }
                    }
                }
            }
        }
    }
}
