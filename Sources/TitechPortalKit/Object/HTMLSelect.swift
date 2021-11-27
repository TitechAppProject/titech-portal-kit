import Foundation

struct HTMLSelect {
    let name: String
    let values: [String]
    var selectedValue: String? = nil

    mutating func select(value selectValue: String) {
        if values.contains(selectValue) {
            selectedValue = selectValue
        }
    }
}
