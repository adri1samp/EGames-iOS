import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, MainViewDelegate {
    //MARK: OUTLETS
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mainTable: UITableView!
    
    //MARK: VARS
    var usuario: Usuario!
    var juegos: [Juego] = [Juego]()
    var sections = [JuegoSection]()
    var filtering: Bool = false
    var filteredJuegos: [Juego] = [Juego]()
    let refreshControl = UIRefreshControl()
    
    //MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //assigns
        usuario = Functions.getCurrentUser()
        if usuario == nil {
            //si el usuario es nil por alguna razon, remover persistencia, remover current user y llevarlo a la pantalla de login
            //esto nunca deberia pasar, pero es una forma de asegurarse de que hay usuario actual
            logout()
        }
        mainTable.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshGames), for: UIControl.Event.valueChanged)
        
        //cargar juegos
        refreshGames()
        
        //delegates
        searchBar.delegate = self
        mainTable.delegate = self
        mainTable.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if filtering {
            return 1
        }
        
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering {
            return filteredJuegos.count
        }
        
        return sections[section].juegos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainCell", for: indexPath) as! MainTableViewCell
        
        if filtering {
            cell.juego = filteredJuegos[indexPath.row]
        }
        else {
            let section = sections[indexPath.section]
            cell.juego = section.juegos[indexPath.row]
        }
        
        cell.lbTitle.text = cell.juego.titulo
        cell.lbType.text = cell.juego.tipo
        if let valoracion = cell.juego.valoracion {
            if let valoracion = Double(valoracion) {
                Functions.unprintStars(stars: cell.stars)
                Functions.printStars(valoracion: valoracion, stars: cell.stars)
            }
            else {
                Functions.unprintStars(stars: cell.stars)
            }
        }
        else {
            Functions.unprintStars(stars: cell.stars)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if filtering {
            return "Buscando: '" + searchBar.text! + "'"
        }
        
        return sections[section].firstLetter
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = mainTable.cellForRow(at: indexPath) as! MainTableViewCell
        performSegue(withIdentifier: "viewGame", sender: cell.juego)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filtering = !searchText.isEmpty
        if filtering {
            filteredJuegos = juegos.filter {
                $0.titulo.range(of: searchText, options: .caseInsensitive) != nil
            }
            mainTable.reloadData()
        }
        else {
            mainTable.reloadData()
        }
    }
    
    //MARK: ACTIONS
    @IBAction func optionsOnClick(_ sender: UIBarButtonItem) {
        let addGame = UIAlertAction(title: "Añadir juego", style: .default, handler:
        {
            (alert: UIAlertAction!) -> Void in
            self.performSegue(withIdentifier: "addGame", sender: self)
        })
        let logout = UIAlertAction(title: "Cerrar sesión", style: .destructive, handler:
        {
            (alert: UIAlertAction!) -> Void in
            self.logout()
        })
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(addGame)
        alert.addAction(logout)
        alert.addAction(cancel)
        alert.popoverPresentationController?.barButtonItem = sender //para el iPad
        present(alert, animated: true)
    }
    
    @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
        if let gameViewController = unwindSegue.source as? GameViewController {
            //juego borrado
            if let index = juegos.firstIndex(of: gameViewController.juego) {
                juegos.remove(at: index)
                refreshSections()
            }
        }
        else if let editGameViewController = unwindSegue.source as? EditGameViewController {
            //juego añadido
            juegos.append(editGameViewController.juego!)
            refreshSections()
        }
    }
    
    //MARK: FUNCS
    private func logout() {
        Functions.removeRememberLogin()
        Functions.removeCurrentUser()
        Functions.switchToLoginNavigationController(self)
    }
    
    func updateGame(oldJuego: Juego, newJuego: Juego) {
        if let index = juegos.firstIndex(of: oldJuego) {
            searchBar.text = ""
            searchBar.resignFirstResponder()
            filtering = false
            juegos[index] = newJuego
            refreshSections()
        }
    }
    
    @objc private func refreshGames() {
        //deshabilitar interaccion con la pantalla
        self.view.isUserInteractionEnabled = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filtering = false
        
        //poner pantalla de carga
        if !refreshControl.isRefreshing {
            Alerts.loadScreenAlert(self, "Cargando...") {
                self.refreshGamesRequest()
            }
        }
        else {
            refreshGamesRequest()
        }
    }
    
    private func refreshGamesRequest() {
        //realizar peticion
        let _ = HttpClient.get("juego2") { (data, response, error) in
            let response = response as! HTTPURLResponse
            if response.statusCode != 200 { //si el codigo de respuesta de HTTP es distinto de 200 (OK): cancelar
                DispatchQueue.main.async {
                    if self.refreshControl.isRefreshing {
                        self.view.isUserInteractionEnabled = true
                        self.refreshControl.endRefreshing()
                        Alerts.errorAlert(self, "No se han podido cargar los datos")
                    }
                    else {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            self.view.isUserInteractionEnabled = true
                            Alerts.errorAlert(self, "No se han podido cargar los datos")
                        })
                    }
                }
                return
            }
            
            //no hay error en la peticion
            do {
                self.juegos = try JSONDecoder().decode([Juego].self, from: data!)
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }
                    else {
                        self.dismiss(animated: false, completion: nil) //quita la pantalla de carga
                    }
                    self.refreshSections()
                }
            }
            catch let parsingError {
                DispatchQueue.main.async {
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                        Alerts.errorAlert(self, "Ha ocurrido un error: " + parsingError.localizedDescription)
                    }
                    else {
                        self.dismiss(animated: false, completion: { //quita pantalla de carga
                            Alerts.errorAlert(self, "Ha ocurrido un error: " + parsingError.localizedDescription)
                        })
                    }
                }
            }
        }
    }
    
    private func refreshSections() {
        let groupedDictionary =
            Dictionary(grouping: juegos, by: {
                String($0.titulo.prefix(1))
                    .uppercased() //lo pone en mayuscula
                    .folding(options: .diacriticInsensitive, locale: .current) //convierte los caracteres especiales a caracteres normales, á->a ñ->n
                    .replacingOccurrences(of: "[^A-Z]", with: "#", options: .regularExpression) //reemplaza todo lo que no sea una letra de la A a la Z por un #
                
            })

        let keys = groupedDictionary.keys.sorted()
        
        sections = keys.map{ JuegoSection(firstLetter: $0, juegos: groupedDictionary[$0]!.sorted()) }
        
        mainTable.reloadData()
    }
    
    //MARK: NAVIGATION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewGame" {
            let gameViewController = segue.destination as! GameViewController
            if let currentRow = mainTable.indexPathForSelectedRow {
                gameViewController.mainViewDelegate = self
                gameViewController.usuario = self.usuario
                gameViewController.juego = sender as? Juego
                mainTable.deselectRow(at: currentRow, animated: false)
            }
        }
    }
}

protocol MainViewDelegate: class {
    func updateGame(oldJuego: Juego, newJuego: Juego)
}
