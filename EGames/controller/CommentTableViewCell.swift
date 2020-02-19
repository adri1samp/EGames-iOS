import UIKit

class CommentTableViewCell: UITableViewCell {
    //MARK: OUTLETS
    @IBOutlet weak var lbUsername: UILabel!
    @IBOutlet weak var btDelete: UIButton!
    @IBOutlet weak var tvComment: UITextView!
    
    //MARK: METHODS
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
