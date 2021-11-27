import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct PasswordSubmitRequest: HTTPRequest {
    let url: URL = URL(
        string: BaseURL.origin + "/GetAccess/Login")!
    
    var method: HTTPMethod = .post
    
    var headerFields: [String : String]? = [
        "Referer": BaseURL.origin + "/GetAccess/Login?Template=userpass_key&AUTHMETHOD=UserPassword",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": userAgent,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja-jp",
    ]
    
    var body: [String : String]?
    
    init(htmlInputs: [HTMLInput]) {
        body = htmlInputs.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }
    }
}
