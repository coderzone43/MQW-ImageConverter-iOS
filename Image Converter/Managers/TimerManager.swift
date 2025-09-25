import Foundation
import UIKit

class TimerManager {
    
    private var timer: Timer?
    private var timeEnd: Date
    private var currentData: Double = 0.0
    private var timerCallback: ((String) -> Void)?
    
    // MARK: - Initializer using currentOfferTime
    init() {
        let storedTime = AppDefaults.shared.currentOfferTime
        if storedTime == 0 {
            self.timeEnd = Date(timeIntervalSinceNow: 599)
        } else {
            self.timeEnd = Date(timeIntervalSinceNow: storedTime)
        }
    }
    
    func startTimer(callback: @escaping (String) -> Void) {
        self.timerCallback = callback
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimeLabel), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    func setTimeEnd(date: Date) {
        self.timeEnd = date
        AppDefaults.shared.currentOfferTime = date.timeIntervalSinceNow
    }
}

//MARK: - @objc Methods
extension TimerManager {
    @objc private func updateTimeLabel() {
        let timeNow = Date()
        if timeEnd.compare(timeNow) == ComparisonResult.orderedDescending {
            let interval = timeEnd.timeIntervalSince(timeNow)
            let minutes = Int(interval / 60)
            let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
            let timeString = "\(minutes) : \(String(format: "%02d", seconds))"
            self.timerCallback?(timeString)
            currentData = interval
            AppDefaults.shared.currentOfferTime = interval
        } else {
            self.timeEnd = Date(timeIntervalSinceNow: 599)
        }
    }
}
