import UIKit

struct Preset {
    var name: String
    var size: [Int]?
    var options: [PresetOption]?
}

struct PresetOption {
    var name: String
    var size: [Int]?
}

let Presets: [Preset] = [
    Preset(name: "Custom", size:[1024, 1024], options: nil),
    Preset(name: "320 x 240 (pixels)", size: [320, 240], options: nil),
    Preset(name: "640 x 480 (pixels)", size: [640, 480], options: nil),
    Preset(name: "800 x 600 (pixels)", size: [800, 600], options: nil),
    Preset(name: "1280 x 1024 (pixels)", size: [1280, 1024], options: nil),
    Preset(name: "1280 x 720 (pixels) HD", size: [1280, 720], options: nil),
    Preset(name: "1920 x 1080 (pixels) Full HD", size: [1920, 1080], options: nil),
    Preset(name: "Facebook", size: nil, options: [
          PresetOption(name: "Page cover 820 × 312", size: [820, 312]),
          PresetOption(name: "Story 1080 × 1920", size: [1080, 1920]),
          PresetOption(name: "Profile image 180 × 180", size: [180, 180]),
          PresetOption(name: "Group cover 1640 × 859", size: [1640, 859]),
          PresetOption(name: "Post 1200 x 900", size: [1200, 900]),
    ]),
    Preset(name: "Instagram", size: nil, options: [
        PresetOption(name: "Story 1080 x 1920", size: [1080, 1920]),
        PresetOption(name: "Square 1080 x 1080", size: [1080, 1080]),
        PresetOption(name: "Portrait 1080 x 1350", size: [1080, 1350]),
        PresetOption(name: "Landscape 1080 x 566", size: [1080, 566]),
    ]),
    Preset(name: "X (Twitter)", size: nil, options: [
        PresetOption(name: "Post 1200 x 670", size: [1200, 670]),
        PresetOption(name: "Header 1500 × 500", size: [1500, 500]),
        PresetOption(name: "Profile image 400 × 400", size: [400, 400]),
        PresetOption(name: "Share image 1200 × 675", size: [1200, 675]),
    ]),
    Preset(name: "YouTube", size: nil, options: [
        PresetOption(name: "Thumbnail 1280 x 720", size: [1280, 720]),
        PresetOption(name: "Channel art 2560 × 1440", size: [2560, 1440]),
        PresetOption(name: "Channel icon 800 × 800", size: [800, 800]),
    ]),
    Preset(name: "Pinterest", size: nil, options: [
        PresetOption(name: "Pin 735 x 1102", size: [735, 1102]),
        PresetOption(name: "Pin 800 × 1200", size: [800, 1200]),
        PresetOption(name: "Board cover 222 × 150", size: [222, 150]),
        PresetOption(name: "Small thumbnail 55 × 55", size: [55, 55]),
        PresetOption(name: "Big Thumbnail 222 × 150", size: [222, 150]),
    ]),
    Preset(name: "Linkedin", size: nil, options: [
        PresetOption(name: "Personal background 1584 × 396", size: [1584, 396]),
        PresetOption(name: "Company background 1536 × 768", size: [1536, 768]),
        PresetOption(name: "Company hero 1128 × 376", size: [1128, 376]),
        PresetOption(name: "Square image 1140 × 736", size: [1140, 736]),
        PresetOption(name: "Company banner 646 × 220", size: [646, 220]),
        PresetOption(name: "Profile image 400 × 400", size: [400, 400]),
        PresetOption(name: "Company logo 300 × 300", size: [300, 300]),
        PresetOption(name: "Square logo 60 × 60", size: [60, 60]),
    ]),
]
