import UIKit

class DownloadedViewController: UIViewController {

    @IBOutlet weak var textLabel: UILabel!
    
    var changedText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = changedText ?? "Downloaded!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            dismiss(animated: true, completion: nil)
        }
    }
}
