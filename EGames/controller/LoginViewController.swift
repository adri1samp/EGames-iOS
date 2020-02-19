import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    //MARK: OUTLETS
    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var swRemember: UISwitch!
    
    //MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //delegates
        tfEmail.delegate = self
        tfPassword.delegate = self
        
        //comprobar si tiene login anterior recordado
        let (remember, email, password) = Functions.getRememberLogin()
        if remember {
            //intentar logear directamente
            if let email = email, let password = password { //esto es para asegurarse de email y password no son nulos
                loginUser(email, password)
            }
        }
        else {
            Functions.removeCurrentUser()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //pasar un textfield al otro con el intro (comodidad experiencia del usuario)
        textField.resignFirstResponder() //quita el foco del actual tf
        if textField == tfEmail {
            tfPassword.becomeFirstResponder()
        }
        return false //devolver false evita que pueda introducir saltos de linea
    }
    
    //MARK: ACTIONS
    @IBAction func btLoginOnClick(_ sender: Any) {
        //comprobacion de todos los campos (que no esten vacios)
        guard
            let email: String = tfEmail.text, !email.isEmpty,
            let password: String = tfPassword.text, !password.isEmpty
        else {
            Alerts.errorAlert(self, "Rellene todos los campos")
            return
        }
        
        //login
        loginUser(email, password)
    }
    
    //MARK: FUNCTIONS
    private func loginUser(_ email: String, _ password: String) {
        //poner pantalla de carga
        Alerts.loadScreenAlert(self, "Espere...") {
            //realizar peticion
            let _ = HttpClient.get("usuario/login/" + email) { (data, response, error) in
                let response = response as! HTTPURLResponse
                if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            Alerts.errorAlert(self, "Correo electrónico o contraseña incorrecto")
                        })
                    }
                    return
                }

                //se ha obtenido un usuario, comprobar pass
                do {
                    let usuario = try JSONDecoder().decode(Usuario.self, from: data!)
                    if usuario.id > 0 && usuario.password == password {
                        //login correcto
                        DispatchQueue.main.async {
                            self.dismiss(animated: false, completion: { //quita pantalla de carga
                                if self.swRemember.isOn {
                                    Functions.rememberLogin(usuario.correo, usuario.password)
                                }
                                Functions.saveCurrentUser(usuario)
                                Functions.switchToMainNavigationController(self)
                            })
                        }
                    }
                    else
                    {
                        DispatchQueue.main.async {
                            self.dismiss(animated: false, completion: { //quita pantalla de carga
                                Alerts.errorAlert(self, "Correo electrónico o contraseña incorrecto")
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
}

