import Foundation

enum HTMLInputType: String {
    case text
    case password
    case checkbox
    case radio
    case file
    case hidden
    case submit
    case reset
    case button
    case image
}

struct HTMLInput: Equatable {
    let name: String
    let type: HTMLInputType
    var value: String
}
