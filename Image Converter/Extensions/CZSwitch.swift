//
//  CZSwitch.swift
//  Fashion-Ai
//
//  Created by Macbook Pro on 18/02/2025.
//

import UIKit

class CZSwitch: UIControl {
    var isOn = false {
        didSet {
            updateState()
        }
    }
    
    var onBackgroundColor = UIColor.systemGreen {
        didSet {
            if isOn { backgroundColor = onBackgroundColor }
        }
    }
    var offBackgroundColor = UIColor.systemGray4 {
        didSet {
            if !isOn { backgroundColor = offBackgroundColor }
        }
    }
    var thumbTintColor = UIColor.white {
        didSet {
            thumbView.backgroundColor = thumbTintColor
        }
    }
    
    var onIcon: UIImage? {
        didSet {
            onIconView.image = onIcon
        }
    }

    var offIcon: UIImage? {
        didSet {
            offIconView.image = offIcon
        }
    }
    
    var padding: CGFloat = 2 {
        didSet {
            setNeedsLayout()
        }
    }

    var onValueChanged: ((Bool) -> Void)?
    
    private var thumbView = UIView(frame: CGRect.zero)
    private var onIconView = UIImageView()
    private var offIconView = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupUI() {
        clipsToBounds = false
        thumbView.backgroundColor = thumbTintColor
        thumbView.isUserInteractionEnabled = false
        addSubview(thumbView)
        
        onIconView.contentMode = .scaleAspectFit
        offIconView.contentMode = .scaleAspectFit
        addSubview(onIconView)
        addSubview(offIconView)
        updateState()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = frame.size.height / 2
        let thumbSize = frame.size.height - padding * 2
        thumbView.frame = CGRect(
            x: isOn ? (frame.size.width - thumbSize - padding) : padding,
            y: padding,
            width: thumbSize,
            height: thumbSize
        )
        thumbView.layer.cornerRadius = thumbView.frame.size.height / 2
        backgroundColor = isOn ? onBackgroundColor : offBackgroundColor
        
        let iconSize = thumbSize / 2
        onIconView.frame = CGRect(x: frame.size.width - thumbSize + (thumbSize - iconSize) / 2 - padding, y: (frame.size.height - iconSize) / 2, width: iconSize, height: iconSize)
        offIconView.frame = CGRect(x: (thumbSize - iconSize) / 2 + padding, y: (frame.size.height - iconSize) / 2, width: iconSize, height: iconSize)
    }

    func setOn(isOn: Bool, animated: Bool) {
        if isOn != self.isOn {
            sendActions(for: .valueChanged)
            if animated {
                UIView.animate(withDuration: 0.15) {
                    self.isOn = isOn
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                    self.onValueChanged?(isOn)
                }
            } else {
                self.isOn = isOn
                setNeedsLayout()
                onValueChanged?(isOn)
            }
        }
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        self.setOn(isOn: !isOn, animated: true)
        return true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }

    private func updateState() {
        backgroundColor = isOn ? onBackgroundColor : offBackgroundColor
        setNeedsLayout()
    }
}
