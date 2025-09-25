import Foundation

struct History: Identifiable {
    var id: String
    var toType: FileFormat
    var category: ConversionCategory
    var action: ConversionAction
    var title: String
    var size: Int
    var date: Date
}
