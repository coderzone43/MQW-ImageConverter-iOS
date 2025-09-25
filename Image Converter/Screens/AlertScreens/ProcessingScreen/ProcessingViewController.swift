import UIKit

class CancellationToken {
    private var isCancelled = false
    private let lock = NSLock()

    func cancel() {
        lock.lock()
        isCancelled = true
        lock.unlock()
    }

    func cancelled() -> Bool {
        lock.lock()
        let result = isCancelled
        lock.unlock()
        return result
    }
}

class ProcessingViewController: UIViewController {
    //MARK: Outlets
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var cancelButton: UIView!
    
    var heading: String?
    var cancellationToken: CancellationToken?
    var onCancel: (() -> Void)?

    //MARK: View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
        progressBar.progress = 0.0
    }
    
    //MARK: Setup View
    private func setupView() {
        headingLabel.text = heading
    }

    //MARK: Update Progress (manual update)
    func updateProgress(_ percent: Double) {
        let clamped = max(0, min(1, percent))
        progressBar.progress = Float(clamped)
        progressLabel.text = "\(Int(clamped * 100))%"
    }
    
    //MARK: Button Action
    private func setupGestures() {
        cancelButton.addTapGestureRecognizer(target: self, action: #selector(cancelButtonTap))
    }
}

//MARK: - @objc Methods
extension ProcessingViewController {
    @objc func cancelButtonTap() {
        cancellationToken?.cancel()
        onCancel?()
        dismiss(animated: true)
    }
}
