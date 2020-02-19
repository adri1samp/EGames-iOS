import UIKit

class MainTableViewCell: UITableViewCell {
    //MARK: OUTLETS
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbType: UILabel!
    @IBOutlet var stars: [UIImageView]!
    
    //MARK: VARS
    var juego: Juego!
    
    //MARK: METHODS
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
