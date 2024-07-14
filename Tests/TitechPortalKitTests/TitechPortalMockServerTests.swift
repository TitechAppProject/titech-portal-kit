import XCTest
@testable import TitechPortalKit

final class TitechPortalMockServerTests: XCTestCase {
    func testMockServerLogin() async throws {
        TitechPortal.changeToMockServer()
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
        TitechPortal.changeToMockServer()
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
            XCTAssertEqual(
                error as! TitechPortalLoginError,
                TitechPortalLoginError.invalidMatrixcodePageHtml
            )
        }
    }
    
    func testMockServerLoginInvalidMatrix() async throws {
        TitechPortal.changeToMockServer()
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
            XCTAssertEqual(
                error as! TitechPortalLoginError,
                TitechPortalLoginError.invalidResourceListPageHtml(currentMatrices: [TitechPortalKit.TitechPortalMatrix.d2, TitechPortalKit.TitechPortalMatrix.e2, TitechPortalKit.TitechPortalMatrix.i6], html: "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n<html><head>\n<title>404 Not Found</title>\n</head><body>\n<h1>Not Found</h1>\n<p>The requested URL was not found on this server.</p>\n</body></html>\n")
            )
        }
    }
    
    func testMockServerCheckUsernamePassword() async throws {
        TitechPortal.changeToMockServer()
        let portal = TitechPortal(urlSession: .shared)

        let checkResult = try! await portal.checkUsernamePassword(
            username: "00B00000",
            password: "passw0rd&"
        )
        
        XCTAssertTrue(checkResult)
    }

    func testMockServerFetchCurrentMatrix() async throws {
        TitechPortal.changeToMockServer()
        let portal = TitechPortal(urlSession: .shared)

        let currentMatrix = try! await portal.fetchCurrentMatrix(
            username: "00B00000",
            password: "passw0rd&"
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
