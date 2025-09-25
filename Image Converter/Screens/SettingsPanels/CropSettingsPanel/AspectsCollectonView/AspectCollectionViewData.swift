import UIKit

struct Aspect {
    var image: UIImage
    var title: String
    var ratio: [CGFloat]?
}

let cropAspects: [Aspect] = [
    Aspect(image: UIImage(named: "Aspect-01")!, title: "Original", ratio: nil),
    Aspect(image: UIImage(named: "Aspect-02")!, title: "Custom", ratio: nil),
    Aspect(image: UIImage(named: "Aspect-03")!, title: "1:1", ratio: [1, 1]),
    Aspect(image: UIImage(named: "Aspect-04")!, title: "2:1", ratio: [2, 1]),
    Aspect(image: UIImage(named: "Aspect-05")!, title: "3:4", ratio: [3, 4]),
    Aspect(image: UIImage(named: "Aspect-06")!, title: "4:5", ratio: [4, 5]),
    Aspect(image: UIImage(named: "Aspect-07")!, title: "9:16", ratio: [9, 16]),
    Aspect(image: UIImage(named: "Aspect-08")!, title: "16:9", ratio: [16, 9]),
    Aspect(image: UIImage(named: "Aspect-09")!, title: "2:1", ratio: [2, 1])
]
