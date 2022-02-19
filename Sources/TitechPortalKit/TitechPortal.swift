import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Kanna

public enum TitechPortalLoginError: Error {
    case invalidPasswordPageHtml
    case invalidMatrixcodePageHtml
    case invalidResourceListPageHtml(currentMatrices: [TitechPortalMatrix])
    
    case noMatrixcodeOption
    case failedCurrentMatrixParse
    
    case alreadyLoggedin
}

public struct TitechPortal {
    private let httpClient: HTTPClient

    public init(urlSession: URLSession) {
        self.httpClient = HTTPClientImpl(urlSession: urlSession)
    }
    
    /// TitechPortalにログイン
    /// - Parameter account: ログイン情報
    public func login(account: TitechPortalAccount) async throws {
        /// パスワードページの取得
        let passwordPageHtml = try await fetchPasswordPage()
        /// パスワードページのバリデーション
        guard try validatePasswordPage(html: passwordPageHtml) else {
            throw TitechPortalLoginError.invalidPasswordPageHtml
        }
        /// パスワードページのInputsのパース
        let passwordPageInputs = try parseHTMLInput(html: passwordPageHtml)
        /// パスワードFormの送信
        let passwordPageSubmitHtml = try await submitPassword(htmlInputs: passwordPageInputs, username: account.username, password: account.password)

        /// すでにログインセッションがある場合はパスワード入力後にすぐにResourceListページに飛ぶ
        if try validateResourceListPage(html: passwordPageHtml) {
            throw TitechPortalLoginError.alreadyLoggedin
        }

        let matrixcodePageHtml: String

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
            matrixcodePageHtml = try await submitOtpSelect(htmlInputs: otpSelectPageInputs, htmlSelects: otpSelectPageSelects)
        } else {
            matrixcodePageHtml = passwordPageSubmitHtml
        }
        /// マトリクスコードページのバリデーション
        guard try validateMatrixcodePage(html: matrixcodePageHtml) else {
            throw TitechPortalLoginError.invalidMatrixcodePageHtml
        }
        /// マトリクスコード入力ページのInputsのパース
        let matrixcodePageInputs = try parseHTMLInput(html: matrixcodePageHtml)
        /// マトリクスコード入力ページのCurrentMatrixのパース
        let matrixcodePageCurrentMatrix = try parseCurrentMatrixes(html: matrixcodePageHtml)
        /// マトリクスコードFormの送信
        let matrixcodePageSubmitHtml = try await submitMatrixcode(htmlInputs: matrixcodePageInputs, parsedMatrix: matrixcodePageCurrentMatrix, matrixcodes: account.matrixcode)
        /// リソースリストページのバリデーション
        guard try validateResourceListPage(html: matrixcodePageSubmitHtml) else {
            throw TitechPortalLoginError.invalidResourceListPageHtml(currentMatrices: matrixcodePageCurrentMatrix)
        }
    }
    
    /// UsernameとPasswordのみが正しいかチェック
    /// - Parameter account: チェックするアカウント情報
    /// - Returns: 正しくログインできればtrue, エラーであればfalseを返す
    public func checkUsernamePassword(username: String, password: String) async throws -> Bool {
        /// パスワードページの取得
        let passwordPageHtml = try await fetchPasswordPage()
        /// パスワードページのバリデーション
        guard try validatePasswordPage(html: passwordPageHtml) else {
            throw TitechPortalLoginError.invalidPasswordPageHtml
        }
        /// パスワードページのInputsのパース
        let passwordPageInputs = try parseHTMLInput(html: passwordPageHtml)
        /// パスワードFormの送信
        let passwordPageSubmitHtml = try await submitPassword(htmlInputs: passwordPageInputs, username: username, password: password)
        
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
        let passwordPageHtml = try await fetchPasswordPage()
        /// パスワードページのバリデーション
        guard try validatePasswordPage(html: passwordPageHtml) else {
            throw TitechPortalLoginError.invalidPasswordPageHtml
        }
        /// パスワードページのInputsのパース
        let passwordPageInputs = try parseHTMLInput(html: passwordPageHtml)
        /// パスワードFormの送信
        let passwordPageSubmitHtml = try await submitPassword(htmlInputs: passwordPageInputs, username: username, password: password)

        /// すでにログインセッションがある場合はパスワード入力後にすぐにResourceListページに飛ぶ
        if try validateResourceListPage(html: passwordPageHtml) {
            throw TitechPortalLoginError.alreadyLoggedin
        }

        let matrixcodePageHtml: String
        
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
            matrixcodePageHtml = try await submitOtpSelect(htmlInputs: otpSelectPageInputs, htmlSelects: otpSelectPageSelects)
        } else {
            matrixcodePageHtml = passwordPageSubmitHtml
        }
        /// マトリクスコードページのバリデーション
        guard try validateMatrixcodePage(html: matrixcodePageHtml) else {
            throw TitechPortalLoginError.invalidMatrixcodePageHtml
        }
        /// マトリクスコード入力ページのInputsのパース
        return try parseCurrentMatrixes(html: matrixcodePageHtml)
    }

    func fetchPasswordPage() async throws -> String {
        let request = PasswordPageRequest()

        return try await httpClient.send(request)
    }
    
    func validatePasswordPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Please input your account &amp; password.")
    }

    func submitPassword(htmlInputs: [HTMLInput], username: String, password: String) async throws -> String {
        let injectedHtmlInputs = inject(htmlInputs, username: username, password: password)
        
        let request = PasswordSubmitRequest(htmlInputs: injectedHtmlInputs)

        return try await httpClient.send(request)
    }
    
    func validateOtpPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Select Label for OTP")
    }
    
    func submitOtpSelect(htmlInputs: [HTMLInput], htmlSelects: [HTMLSelect]) async throws -> String {
        let selectedHtmlSelects: [HTMLSelect] = htmlSelects.map {
            var newHtmlSelect = $0
            
            newHtmlSelect.select(value: "GridAuthOption")
            
            return newHtmlSelect
        }
        
        let request = OtpSelectSubmitRequest(htmlInputs: htmlInputs, htmlSelects: selectedHtmlSelects)
        

        return try await httpClient.send(request)
    }
    
    func validateMatrixcodePage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Matrix Authentication")
    }
    
    func submitMatrixcode(htmlInputs: [HTMLInput], parsedMatrix: [TitechPortalMatrix], matrixcodes: [TitechPortalMatrix: String]) async throws -> String {
        let injectedHtmlInputs = inject(htmlInputs, parsedMatrix: parsedMatrix, matrixcodes: matrixcodes)

        let request = MatrixcodeSubmitRequest(htmlInputs: injectedHtmlInputs)

        return try await httpClient.send(request)
    }
    
    func validateResourceListPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("title").first?.innerHTML ?? ""

        return bodyHtml.contains("リソース メニュー")
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
