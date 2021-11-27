import XCTest
@testable import TitechPortalKit

final class TitechPortalMockServerTests: XCTestCase {
    func testMockServerLogin() async throws {
        TitechPortal.changeToMock()
        let portal = TitechPortal(urlSession: .shared)

        try! await portal.login(
            account: TitechPortalAccount(
                username: "00B00000",
                password: "passw0rd&",
                matrixcode: TitechPortalMatrix.allCases.reduce(into: [TitechPortalMatrix: String]()) {
                    $0[$1] = "A"
                }
            )
        )
    }
    
    func testMockServerLoginInvalidPassword() async throws {
        TitechPortal.changeToMock()
        let portal = TitechPortal(urlSession: .shared)

        do {
            try await portal.login(
                account: TitechPortalAccount(
                    username: "00B00000",
                    password: "aaa",
                    matrixcode: TitechPortalMatrix.allCases.reduce(into: [TitechPortalMatrix: String]()) {
                        $0[$1] = "A"
                    }
                )
            )
            XCTFail()
        } catch {
            XCTAssertEqual(error as! TitechPortalLoginError, TitechPortalLoginError.invalidMatrixcodePageHtml)
        }
    }
    
    func testMockServerLoginInvalidMatrix() async throws {
        TitechPortal.changeToMock()
        let portal = TitechPortal(urlSession: .shared)

        do {
            try await portal.login(
                account: TitechPortalAccount(
                    username: "00B00000",
                    password: "passw0rd&",
                    matrixcode: TitechPortalMatrix.allCases.reduce(into: [TitechPortalMatrix: String]()) {
                        $0[$1] = "B"
                    }
                )
            )
            XCTFail()
        } catch {
            XCTAssertEqual(error as! TitechPortalLoginError, TitechPortalLoginError.invalidResourceListPageHtml)
        }
    }
    
    func testMockServerCheckUsernamePassword() async throws {
        TitechPortal.changeToMock()
        let portal = TitechPortal(urlSession: .shared)

        let checkResult = try! await portal.checkUsernamePassword(
            account: TitechPortalAccount(
                username: "00B00000",
                password: "passw0rd&",
                matrixcode: [:]
            )
        )
        
        XCTAssertTrue(checkResult)
    }

    func testMockServerFetchCurrentMatrix() async throws {
        TitechPortal.changeToMock()
        let portal = TitechPortal(urlSession: .shared)

        let currentMatrix = try! await portal.fetchCurrentMatrix(
            account: TitechPortalAccount(
                username: "00B00000",
                password: "passw0rd&",
                matrixcode: [:]
            )
        )
        
        XCTAssertEqual(
            currentMatrix,
            [
                .d2,
                .e2,
                .i6
            ]
        )
    }
}
