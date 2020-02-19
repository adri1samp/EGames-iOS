import UIKit

class Alerts {
    static func loadScreenAlert(_ controller: UIViewController, _ message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating();
        alert.view.addSubview(loadingIndicator)
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: completion)
        }
    }
    
    static func errorAlert(_ controller: UIViewController, _ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cerrar", style: UIAlertAction.Style.destructive, handler: nil))
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: nil)
        }
    }
}
