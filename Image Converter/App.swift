//
//  App.swift
//  Image Converter
//
//  Created by Macbook Pro on 21/09/2025.
//

import Foundation
import UIKit

enum Appearance: String {
  case System
  case Light
  case Dark
}

class App {
    static var appearance: Appearance {
        get { .init(rawValue: AppDefaults.shared.displayMode) ?? .System }
        set {
            AppDefaults.shared.displayMode = newValue.rawValue
                  switch newValue {
                  case .System:
                    UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .unspecified
                  case .Light:
                    UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .light
                  case .Dark:
                    UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .dark
                  }
        }
    }
}
