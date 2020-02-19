import UIKit

class RatingTableViewCell: UITableViewCell {
    //MARK: OUTLETS
    @IBOutlet weak var lbUsername: UILabel!
    @IBOutlet weak var btDelete: UIButton!
    @IBOutlet var stars: [UIImageView]!
    
    //MARK: METHODS
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
