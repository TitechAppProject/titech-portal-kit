import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MatrixcodeSubmitRequest: HTTPRequest {
    let url: URL = URL(
        string: BaseURL.origin + "/GetAccess/Login")!

    var method: HTTPMethod = .post

    var headerFields: [String: String]?

    var body: [String: String]?

    init(htmlInputs: [HTMLInput], htmlSelects: [HTMLSelect], referer: URL?) {
        let inputsDic = htmlInputs.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }

        let selectsDic = htmlSelects.reduce(into: [String: String]()) {
            $0[$1.name] = $1.selectedValue
        }

        body = inputsDic.merging(selectsDic, uniquingKeysWith: { a, _ in a })

        var headers = [
            "Origin": BaseURL.origin,
            "Connection": "keep-alive",
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Encoding": "br, gzip, deflate",
            "Accept-Language": "ja-jp",
        ]
        if let referer {
            headers["Referer"] = referer.absoluteString
        }
        headerFields = headers
    }
}
