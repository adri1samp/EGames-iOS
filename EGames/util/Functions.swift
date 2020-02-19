import UIKit

class Functions {
    //remember
    static func rememberLogin(_ email: String, _ password: String) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "remember")
        defaults.set(email, forKey: "email")
        defaults.set(password, forKey: "password")
    }
    
    static func removeRememberLogin() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "remember")
        defaults.removeObject(forKey: "email")
        defaults.removeObject(forKey: "password")
    }
    
    static func getRememberLogin() -> (Bool, String?, String?) {
        let defaults = UserDefaults.standard
        return (
            defaults.bool(forKey: "remember"),
            defaults.string(forKey: "email"),
            defaults.string(forKey: "password")
        )
    }
    
    //current user
    static func saveCurrentUser(_ usuario: Usuario) {
        if let encoded = try? JSONEncoder().encode(usuario) {
            UserDefaults.standard.setValue(encoded, forKey: "current_user")
        }
    }
    
    static func getCurrentUser() -> Usuario? {
        if let current_user = UserDefaults.standard.object(forKey: "current_user") as? Data {
            if let usuario: Usuario = try? JSONDecoder().decode(Usuario.self, from: current_user) {
                return usuario
            }
        }
        return nil
    }
    
    static func removeCurrentUser() {
        UserDefaults.standard.removeObject(forKey: "current_user")
    }
    
    //main controller
    static func switchToMainNavigationController(_ controller: UIViewController) {
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = mainStoryBoard.instantiateViewController(withIdentifier: "mainNav") as! UINavigationController
        controller.view.window!.rootViewController = mainViewController
    }
    
    static func switchToLoginNavigationController(_ controller: UIViewController) {
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = mainStoryBoard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
        controller.view.window!.rootViewController = mainViewController
    }
    
    //date
    static func stringToDate(_ date: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: date)!
    }
    
    static func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    static func dateTimeToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    //image
    static func setImageFromUrl(url: String, image: UIImageView) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let url = URL(string: url)!
        let task = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil && (response as! HTTPURLResponse).statusCode == 200 {
                if let img = UIImage(data: data!) {
                    DispatchQueue.main.async {
                        image.image = img
                    }
                }
            }
        }
        task.resume()
    }
    
    //stars
    static func unprintStars(stars: [UIImageView]) {
        let starImage = UIImage(systemName: "star")
        for star in stars {
            star.image = starImage
        }
    }
    
    static func unprintStars(stars: [UIButton]) {
        let starImage = UIImage(systemName: "star")
        for star in stars {
            star.setImage(starImage, for: .normal)
        }
    }
    
    static func printStars(valoracion: Double, stars: [UIImageView]) {
        let totalStars = Int(valoracion)
        if totalStars > stars.count {
            return
        }
        
        if totalStars > 0 {
            let starFill = UIImage(systemName: "star.fill")
            for i in 0 ..< totalStars {
                stars[i].image = starFill
            }
        }
        
        if totalStars < 5 {
            let decimalPart = valoracion.truncatingRemainder(dividingBy: 1)
            if decimalPart >= 0.5 {
                stars[totalStars].image = UIImage(systemName: "star.lefthalf.fill")
            }
        }
    }
    
    static func printStars(valoracion: Double, stars: [UIButton]) {
        let totalStars = Int(valoracion)
        if totalStars > stars.count {
            return
        }
        
        if totalStars > 0 {
            let starFill = UIImage(systemName: "star.fill")
            for i in 0 ..< totalStars {
                stars[i].setImage(starFill, for: .normal)
            }
        }
        
        if totalStars < 5 {
            let decimalPart = valoracion.truncatingRemainder(dividingBy: 1)
            if decimalPart >= 0.5 {
                stars[totalStars].setImage(UIImage(systemName: "star.lefthalf.fill"), for: .normal)
            }
        }
    }
}
