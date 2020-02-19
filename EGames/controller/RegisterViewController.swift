import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {
    //MARK: OUTLETS
    @IBOutlet weak var tfUsername: UITextField!
    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfRepeatPassword: UITextField!
    @IBOutlet weak var swRemember: UISwitch!
    
    //MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //delegates
        tfUsername.delegate = self
        tfEmail.delegate = self
        tfPassword.delegate = self
        tfRepeatPassword.delegate = self
    }
    
    //funcionamiento comentado en LoginViewController.swift
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == tfUsername {
            tfEmail.becomeFirstResponder()
        }
        else if textField == tfEmail {
            tfPassword.becomeFirstResponder()
        }
        else if textField == tfPassword {
            tfRepeatPassword.becomeFirstResponder()
        }
        return false
    }
    
    //MARK: ACTIONS
    @IBAction func btRegisterOnClick(_ sender: UIButton) {
        //comprobacion de todos los campos (que no esten vacios)
        guard
            let username: String = tfUsername.text, !username.isEmpty,
            let email: String = tfEmail.text, !email.isEmpty,
            let password: String = tfPassword.text, !password.isEmpty,
            let repeatPassword: String = tfRepeatPassword.text, !repeatPassword.isEmpty
        else {
            Alerts.errorAlert(self, "Rellene todos los campos")
            return
        }
        
        //comprobar si las contraseñas son iguales
        if password != repeatPassword {
            Alerts.errorAlert(self, "Las contraseñas no coinciden")
            return
        }
        
        //registrar usuario
        registerUser(username, email, password)
    }
    
    //MARK: FUNCTIONS
    private func registerUser(_ username: String, _ email: String, _ password: String) {
        //poner pantalla de carga
        Alerts.loadScreenAlert(self, "Espere...") {
            //insertar usuario
            let user: [String: Any] = [
                "alias": username,
                "correo": email,
                "password": password
            ]
            let _ = HttpClient.post("usuario", user) { (data, response, error) in
                let response = response as! HTTPURLResponse
                if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            Alerts.errorAlert(self, "El alias o correo electrónico están en uso")
                        })
                    }
                    return
                }
                
                //usuario registrado
                do {
                    let usuario = try JSONDecoder().decode(Usuario.self, from: data!)
                    if usuario.id > 0 {
                        //todo OK: usuario con id valida
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
}
