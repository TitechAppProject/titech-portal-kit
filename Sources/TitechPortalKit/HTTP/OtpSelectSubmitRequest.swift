import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct OtpSelectSubmitRequest: HTTPRequest {
    let url: URL = URL(
        string: BaseURL.origin + "/GetAccess/Login")!
    
    var method: HTTPMethod = .post
    
    var headerFields: [String : String]? = [
        "Referer": BaseURL.origin + "/GetAccess/Login?Template=idg_key&AUTHMETHOD=IG&GASF=CERTIFICATE,IG.GRID,IG.OTP&LOCALE=ja_JP&GAREASONCODE=13&GAIDENTIFICATIONID=UserPassword&GARESOURCEID=resourcelistID2&GAURI=https://portal.nap.gsic.titech.ac.jp/GetAccess/ResourceList&Reason=13&APPID=resourcelistID2&URI=https://portal.nap.gsic.titech.ac.jp/GetAccess/ResourceList",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja-jp",
    ]
    
    var body: [String : String]?
    
    init(htmlInputs: [HTMLInput], htmlSelects: [HTMLSelect]) {
        let inputsDic = htmlInputs.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }
        
        let selectsDic = htmlSelects.reduce(into: [String: String]()) {
            $0[$1.name] = $1.selectedValue
        }
        
        body = inputsDic.merging(selectsDic, uniquingKeysWith: { a, _ in a })
    }
}
