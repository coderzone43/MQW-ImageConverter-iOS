import UIKit

struct Setting {
    var icon: UIImage
    var title: String
    var contextMenuItems: [Any]?
}

struct Languages {
  let languageName: String
  let code: String
}

let displayModes: [String] = ["System", "Light", "Dark"]

let appLanguages = [
  Languages(languageName: "English", code: "en"),
  Languages(languageName: "Arabic", code: "ar"),
  Languages(languageName: "Catalan", code: "ca"),
  Languages(languageName: "Chinese, Simplified", code: "zh-Hans"),
  Languages(languageName: "Chinese, Traditional", code: "zh-Hant"),
  Languages(languageName: "Croatian", code: "hr"),
  Languages(languageName: "Czech", code: "cs"),
  Languages(languageName: "Danish", code: "da"),
  Languages(languageName: "Dutch", code: "nl"),
  Languages(languageName: "Finnish", code: "fi"),
  Languages(languageName: "French", code: "fr"),
  Languages(languageName: "German", code: "de"),
  Languages(languageName: "Greek", code: "el"),
  Languages(languageName: "Hebrew", code: "he"),
  Languages(languageName: "Hindi", code: "hi"),
  Languages(languageName: "Hungarian", code: "hu"),
  Languages(languageName: "Indonesian", code: "id"),
  Languages(languageName: "Italian", code: "it"),
  Languages(languageName: "Japanese", code: "ja"),
  Languages(languageName: "Korean", code: "ko"),
  Languages(languageName: "Malay", code: "ms"),
  Languages(languageName: "Norwegian Bokmål", code: "nb"),
  Languages(languageName: "Polish", code: "pl"),
  Languages(languageName: "Portuguese (Brazil)", code: "pt-BR"),
  Languages(languageName: "Romanian", code: "ro"),
  Languages(languageName: "Russian", code: "ru"),
  Languages(languageName: "Slovak", code: "sk"),
  Languages(languageName: "Spanish", code: "es"),
  Languages(languageName: "Swedish", code: "sv"),
  Languages(languageName: "Thai", code: "th"),
  Languages(languageName: "Turkish", code: "tr"),
  Languages(languageName: "Ukrainian", code: "uk"),
  Languages(languageName: "Vietnamese", code: "vi")
]

var settings: [Setting] = [
    Setting(icon: UIImage(named: "Display-Icon")!, title: "Display Mode", contextMenuItems: displayModes),
//    Setting(icon: UIImage(named: "Language-Icon")!, title: "App Language", contextMenuItems: appLanguages),
    Setting(icon: UIImage(named: "Rate-Icon")!, title: "Rate Us", contextMenuItems: nil),
    Setting(icon: UIImage(named: "Share-Icon")!, title: "Share App", contextMenuItems: nil),
    Setting(icon: UIImage(named: "Privacy-Icon")!, title: "Privacy Policy", contextMenuItems: nil),
    Setting(icon: UIImage(named: "Terms-Icon")!, title: "Terms & Conditions", contextMenuItems: nil),
    Setting(icon: UIImage(named: "Apps-Icon")!, title: "More Apps", contextMenuItems: nil),
    Setting(icon: UIImage(named: "Restore-Icon")!, title: "Restore Purchase", contextMenuItems: nil),
]
