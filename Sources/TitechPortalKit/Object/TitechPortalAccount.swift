import Foundation

public struct TitechPortalAccount {
    let username: String
    let password: String
    let matrixcode: [TitechPortalMatrix: String]
    
    public init(username: String, password: String, matrixcode: [TitechPortalMatrix: String]) {
        self.username = username
        self.password = password
        self.matrixcode = matrixcode
    }
}
