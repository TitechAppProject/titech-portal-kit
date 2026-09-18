import Foundation
import Kanna

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum TitechPortalLoginError: Error, Equatable {
    case invalidPasswordPageHtml
    case invalidMatrixcodePageHtml
    case invalidResourceListPageHtml(currentMatrices: [TitechPortalMatrix], html: String)

    case noMatrixcodeOption
    case failedCurrentMatrixParse

    case alreadyLoggedin
    case passwordChangeRequired
}

public struct TitechPortal {
    private let httpClient: HTTPClient
    public static let defaultUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

    public init(urlSession: URLSession, userAgent: String = TitechPortal.defaultUserAgent) {
        self.httpClient = HTTPClientImpl(urlSession: urlSession, userAgent: userAgent)
    }

    /// TitechPortalにログイン
    /// - Parameter account: ログイン情報
    public func login(account: TitechPortalAccount) async throws {
        /// パスワードページの取得
        let passwordPageResponse = try await fetchPasswordPage()
        let passwordPageHtml = passwordPageResponse.body
        /// パスワードページのバリデーション
        guard try validatePasswordPage(html: passwordPageHtml) else {
            throw TitechPortalLoginError.invalidPasswordPageHtml
        }
        /// パスワードページのInputsのパース
        let passwordPageInputs = try parseHTMLInput(html: passwordPageHtml)
        /// パスワードFormの送信
        let passwordPageSubmitResponse = try await submitPassword(htmlInputs: passwordPageInputs, username: account.username, password: account.password)
        let passwordPageSubmitHtml = passwordPageSubmitResponse.body

        /// すでにログインセッションがある場合はパスワード入力後にすぐにResourceListページに飛ぶ
        if try validateResourceListPage(html: passwordPageHtml) {
            throw TitechPortalLoginError.alreadyLoggedin
        }

        let matrixcodePageResponse: HTTPResponse

        if try validateOtpPage(html: passwordPageSubmitHtml) {
            /// OTP選択ページのInputsのパース
            let otpSelectPageInputs = try parseHTMLInput(html: passwordPageSubmitHtml)
            /// OTP選択ページのSelectのパース
            let otpSelectPageSelects = try parseHTMLSelect(html: passwordPageSubmitHtml)
            /// OTP選択ページのSelectにGridAuthOptionが含まれているか確認
            /// これがない場合マトリクス認証が許可されていない
            let hasMatrixcodeOption = otpSelectPageSelects.contains {
                $0.values.contains("GridAuthOption")
            }
            guard hasMatrixcodeOption else {
                throw TitechPortalLoginError.noMatrixcodeOption
            }
            /// OTP選択Formの送信
            matrixcodePageResponse = try await submitOtpSelect(htmlInputs: otpSelectPageInputs, htmlSelects: otpSelectPageSelects, referer: passwordPageSubmitResponse.url)
        } else {
            matrixcodePageResponse = HTTPResponse(body: passwordPageSubmitHtml, url: passwordPageSubmitResponse.url)
        }
        let matrixcodePageHtml = matrixcodePageResponse.body
        /// マトリクスコードページのバリデーション
        guard try validateMatrixcodePage(html: matrixcodePageHtml) else {
            throw TitechPortalLoginError.invalidMatrixcodePageHtml
        }
        /// マトリクスコード入力ページのInputsのパース
        let matrixcodePageInputs = try parseHTMLInput(html: matrixcodePageHtml)
        /// マトリクスコード入力ページのCurrentMatrixのパース
        let matrixcodePageCurrentMatrix = try parseCurrentMatrixes(html: matrixcodePageHtml)
        ///マトリクスコード入力ページのSelectのパース
        let matrixcodePageSelects = try parseHTMLSelect(html: matrixcodePageHtml)
        /// マトリクスコードFormの送信
        let matrixcodePageSubmitResponse = try await submitMatrixcode(
            htmlInputs: matrixcodePageInputs, htmlSelects: matrixcodePageSelects, parsedMatrix: matrixcodePageCurrentMatrix, matrixcodes: account.matrixcode, referer: matrixcodePageResponse.url)
        let matrixcodePageSubmitHtml = matrixcodePageSubmitResponse.body
        /// パスワード変更ページの検出
        if try validatePasswordChangePage(html: matrixcodePageSubmitHtml) {
            throw TitechPortalLoginError.passwordChangeRequired
        }
        /// リソースリストページのバリデーション
        guard try validateResourceListPage(html: matrixcodePageSubmitHtml) else {
            throw TitechPortalLoginError.invalidResourceListPageHtml(currentMatrices: matrixcodePageCurrentMatrix, html: matrixcodePageSubmitHtml)
        }
    }

    /// UsernameとPasswordのみが正しいかチェック
    /// - Parameter account: チェックするアカウント情報
    /// - Returns: 正しくログインできればtrue, エラーであればfalseを返す
    public func checkUsernamePassword(username: String, password: String) async throws -> Bool {
        /// パスワードページの取得
        let passwordPageResponse = try await fetchPasswordPage()
        let passwordPageHtml = passwordPageResponse.body
        /// パスワードページのバリデーション
        guard try validatePasswordPage(html: passwordPageHtml) else {
            throw TitechPortalLoginError.invalidPasswordPageHtml
        }
        /// パスワードページのInputsのパース
        let passwordPageInputs = try parseHTMLInput(html: passwordPageHtml)
        /// パスワードFormの送信
        let passwordPageSubmitResponse = try await submitPassword(htmlInputs: passwordPageInputs, username: username, password: password)
        let passwordPageSubmitHtml = passwordPageSubmitResponse.body

        return try validateOtpPage(html: passwordPageSubmitHtml) || validateMatrixcodePage(html: passwordPageSubmitHtml)
    }

    /// ログイン済みかを判定
    /// - Returns: ログイン済みのセッションであればtrue、ログイン済みでなければfalse
    public func isLoggedIn() async throws -> Bool {
        let statusCode = try await httpClient.statusCode(ResourceListPageRequest())

        return statusCode == 200
    }

    /// 現在のマトリクスを取得
    /// - Parameter account: ログイン情報
    /// - Returns: 現在のマトリクス
    public func fetchCurrentMatrix(username: String, password: String) async throws -> [TitechPortalMatrix] {
        /// パスワードページの取得
        let passwordPageResponse = try await fetchPasswordPage()
        let passwordPageHtml = passwordPageResponse.body
        /// パスワードページのバリデーション
        guard try validatePasswordPage(html: passwordPageHtml) else {
            throw TitechPortalLoginError.invalidPasswordPageHtml
        }
        /// パスワードページのInputsのパース
        let passwordPageInputs = try parseHTMLInput(html: passwordPageHtml)
        /// パスワードFormの送信
        let passwordPageSubmitResponse = try await submitPassword(htmlInputs: passwordPageInputs, username: username, password: password)
        let passwordPageSubmitHtml = passwordPageSubmitResponse.body

        /// すでにログインセッションがある場合はパスワード入力後にすぐにResourceListページに飛ぶ
        if try validateResourceListPage(html: passwordPageHtml) {
            throw TitechPortalLoginError.alreadyLoggedin
        }

        let matrixcodePageResponse: HTTPResponse

        if try validateOtpPage(html: passwordPageSubmitHtml) {
            /// OTP選択ページのInputsのパース
            let otpSelectPageInputs = try parseHTMLInput(html: passwordPageSubmitHtml)
            /// OTP選択ページのSelectのパース
            let otpSelectPageSelects = try parseHTMLSelect(html: passwordPageSubmitHtml)
            /// OTP選択ページのSelectにGridAuthOptionが含まれているか確認
            /// これがない場合マトリクス認証が許可されていない
            let hasMatrixcodeOption = otpSelectPageSelects.contains {
                $0.values.contains("GridAuthOption")
            }
            guard hasMatrixcodeOption else {
                throw TitechPortalLoginError.noMatrixcodeOption
            }
            /// OTP選択Formの送信
            matrixcodePageResponse = try await submitOtpSelect(htmlInputs: otpSelectPageInputs, htmlSelects: otpSelectPageSelects, referer: passwordPageSubmitResponse.url)
        } else {
            matrixcodePageResponse = HTTPResponse(body: passwordPageSubmitHtml, url: passwordPageSubmitResponse.url)
        }
        let matrixcodePageHtml = matrixcodePageResponse.body
        /// マトリクスコードページのバリデーション
        guard try validateMatrixcodePage(html: matrixcodePageHtml) else {
            throw TitechPortalLoginError.invalidMatrixcodePageHtml
        }
        /// マトリクスコード入力ページのInputsのパース
        return try parseCurrentMatrixes(html: matrixcodePageHtml)
    }

    func fetchPasswordPage() async throws -> HTTPResponse {
        let request = PasswordPageRequest()

        return try await httpClient.send(request)
    }

    func validatePasswordPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Please input your account &amp; password.")
    }

    func submitPassword(htmlInputs: [HTMLInput], username: String, password: String) async throws -> HTTPResponse {
        let injectedHtmlInputs = inject(htmlInputs, username: username, password: password)

        let request = PasswordSubmitRequest(htmlInputs: injectedHtmlInputs)

        return try await httpClient.send(request)
    }

    func validateOtpPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Select Label for OTP") || bodyHtml.contains("Enter Token Dynamic Password")
    }

    func submitOtpSelect(htmlInputs: [HTMLInput], htmlSelects: [HTMLSelect], referer: URL?) async throws -> HTTPResponse {
        let selectedHtmlSelects: [HTMLSelect] = htmlSelects.map {
            var newHtmlSelect = $0

            newHtmlSelect.select(value: "GridAuthOption")

            return newHtmlSelect
        }

        let request = OtpSelectSubmitRequest(htmlInputs: htmlInputs, htmlSelects: selectedHtmlSelects, referer: referer)

        return try await httpClient.send(request)
    }

    func validateMatrixcodePage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Matrix Authentication")
    }

    func submitMatrixcode(htmlInputs: [HTMLInput], htmlSelects: [HTMLSelect], parsedMatrix: [TitechPortalMatrix], matrixcodes: [TitechPortalMatrix: String], referer: URL?) async throws -> HTTPResponse {
        let injectedHtmlInputs = inject(htmlInputs, parsedMatrix: parsedMatrix, matrixcodes: matrixcodes)

        let injectedSelects: [HTMLSelect] = htmlSelects.map {
            if $0.values.contains("NoOtherIGAuthOption") {
                return HTMLSelect(name: $0.name, values: $0.values, selectedValue: "NoOtherIGAuthOption")
            } else {
                return $0
            }
        }

        let request = MatrixcodeSubmitRequest(htmlInputs: injectedHtmlInputs, htmlSelects: injectedSelects, referer: referer)

        return try await httpClient.send(request)
    }

    func validateResourceListPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("title").first?.innerHTML ?? ""

        return bodyHtml.contains("リソース メニュー")
    }

    func validatePasswordChangePage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let title = doc.css("title").first?.innerHTML ?? ""

        return title.contains("Password Change")
    }

    func parseHTMLInput(html: String) throws -> [HTMLInput] {
        let doc = try HTML(html: html, encoding: .utf8)

        return doc.css("input").map {
            HTMLInput(
                name: $0["name"] ?? "",
                type: HTMLInputType(rawValue: $0["type"] ?? "") ?? .text,
                value: $0["value"] ?? ""
            )
        }
    }

    func parseHTMLSelect(html: String) throws -> [HTMLSelect] {
        let doc = try HTML(html: html, encoding: .utf8)

        return doc.css("select").map {
            HTMLSelect(
                name: $0["name"] ?? "",
                values: $0.css("option").map { $0["value"] ?? "" }
            )
        }
    }

    func parseCurrentMatrixes(html: String) throws -> [TitechPortalMatrix] {
        guard let matrixArr = html.matches("\\[([A-J]{1}),([1-7]{1})\\]") else {
            throw TitechPortalLoginError.failedCurrentMatrixParse
        }

        let alphabets = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

        return matrixArr.compactMap { matrix -> TitechPortalMatrix? in
            for alphabet in alphabets {
                if matrix[0].contains(alphabet), let i = Int(matrix[1]) {
                    return TitechPortalMatrix(rawValue: "\(alphabet.lowercased())\(i)")
                }
            }
            return nil
        }
    }

    func inject(_ inputs: [HTMLInput], username: String, password: String) -> [HTMLInput] {
        guard
            let firstTextInput = inputs.first(where: { $0.type == .text }),
            let firstPasswordInput = inputs.first(where: { $0.type == .password })
        else {
            // TODO: エラーにした方がいいかも
            return inputs
        }

        return inputs.map {
            if $0 == firstTextInput {
                var newInput = $0
                newInput.value = username
                return newInput
            }
            if $0 == firstPasswordInput {
                var newInput = $0
                newInput.value = password
                return newInput
            }
            return $0
        }
    }

    func inject(_ inputs: [HTMLInput], parsedMatrix: [TitechPortalMatrix], matrixcodes: [TitechPortalMatrix: String]) -> [HTMLInput] {
        guard !parsedMatrix.isEmpty else {
            return inputs
        }

        var index = 0

        return inputs.map { input -> HTMLInput in
            if input.type == .password {
                var newInput = input
                if parsedMatrix.count > index {
                    newInput.value = matrixcodes[parsedMatrix[index]] ?? ""
                    index += 1
                }
                return newInput
            } else {
                return input
            }
        }
    }

    public static func changeToMockServer() {
        BaseURL.changeToMockServer()
    }
}
