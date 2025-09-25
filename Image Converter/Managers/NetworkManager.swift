import Foundation
import Network

protocol NetworkManagerDelegate: AnyObject {
    func networkStatusChanged(status: NetworkStatus)
}

enum NetworkStatus {
    case connected
    case disconnected
    case wifi
    case ethernet
    case mobileData
    case slowConnection
}

class NetworkManager {
    
    private var monitor: NWPathMonitor
    private var queue: DispatchQueue
    weak var delegate: NetworkManagerDelegate?
    var currentStatus: NetworkStatus = .disconnected
    
    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "NetworkMonitorQueue")
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdate(path)
        }
        monitor.start(queue: queue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        var newStatus: NetworkStatus
        
        if path.status == .satisfied {
            if path.isExpensive {
                newStatus = .mobileData
            } else if path.usesInterfaceType(.wifi) {
                newStatus = .wifi
            } else if path.usesInterfaceType(.wiredEthernet) {
                newStatus = .ethernet
            } else {
                newStatus = .connected
            }
            
            // Check for slow connection if the connection is satisfied
            if isSlowConnection() {
                newStatus = .slowConnection
            }
        } else {
            newStatus = .disconnected
        }
        
        // Only notify if the status has changed
        if newStatus != currentStatus {
            currentStatus = newStatus
            delegate?.networkStatusChanged(status: newStatus)
        }
    }
    
    private func isSlowConnection() -> Bool {
        let speedThreshold = 1.0  // Example threshold
        let currentSpeed = getCurrentInternetSpeed()
        return currentSpeed < speedThreshold
    }
    
    private func getCurrentInternetSpeed() -> Double {
        // This is a placeholder for actual speed measurement
        return 0.5
    }
}
