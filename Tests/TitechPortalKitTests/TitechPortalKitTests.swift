import XCTest
@testable import TitechPortalKit

final class TitechPortalKitTests: XCTestCase {
    func testPasswordPageValidation() throws {
        let portal = TitechPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "password_page", withExtension: "html")!)
        
        XCTAssertTrue(try! portal.validatePasswordPage(html: html))
    }
    
    func testPasswordPageParseHTMLInputs() throws {
        let portal = TitechPortal(urlSession: .shared)

        let passwordPageHtml = try! String(contentsOf: Bundle.module.url(forResource: "password_page", withExtension: "html")!)
        
        let passwordPageInputs = try! portal.parseHTMLInput(html: passwordPageHtml)
        
        XCTAssertEqual(
            passwordPageInputs,
            [
                HTMLInput(name: "usr_name", type: .text, value: ""),
                HTMLInput(name: "usr_password", type: .password, value: ""),
                HTMLInput(name: "OK", type: .submit, value: "    OK    "),
                HTMLInput(name: "AUTHTYPE", type: .hidden, value: ""),
                HTMLInput(name: "HiddenURI", type: .hidden, value: "https://portal.nap.gsic.titech.ac.jp/GetAccess/ResourceList"),
                HTMLInput(name: "Template", type: .hidden, value: "userpass_key"),
                HTMLInput(name: "AUTHMETHOD", type: .hidden, value: "UserPassword"),
                HTMLInput(name: "pageGenTime", type: .hidden, value: "100"),
                HTMLInput(name: "LOCALE", type: .hidden, value: "ja_JP"),
                HTMLInput(name: "CSRFFormToken", type: .hidden, value: "CSRFFormTokenValue")
            ]
        )
    }

    func testValidateOtpPageForMatrixcodePage() throws {
        let portal = TitechPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "matrix_code_page", withExtension: "html")!)
        
        XCTAssertFalse(try! portal.validateOtpPage(html: html))
    }

    func testValidateOtpPageForOTPSelectPage() throws {
        let portal = TitechPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "otp_select_page", withExtension: "html")!)
        
        XCTAssertTrue(try! portal.validateOtpPage(html: html))
    }

    func testValidateOtpPageForTOTP() throws {
        let portal = TitechPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "totp_page", withExtension: "html")!)
        
        XCTAssertTrue(try! portal.validateOtpPage(html: html))
    }
    
    func testResourceMenuValidation() throws {
        let portal = TitechPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "resource_list_page-ja", withExtension: "html")!)
        
        XCTAssertTrue(try! portal.validateResourceListPage(html: html))
    }
}
