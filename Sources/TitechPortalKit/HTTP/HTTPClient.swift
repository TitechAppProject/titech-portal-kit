import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol HTTPClient {
    func send(_ request: HTTPRequest) async throws -> String
    func statusCode(_ request: HTTPRequest) async throws -> Int
}

struct HTTPClientImpl: HTTPClient {
    private let urlSession: URLSession
    private let urlSessionDelegate: URLSessionTaskDelegate
    private let urlSessionDelegateWithoutRedirect: URLSessionTaskDelegate
    private let userAgent: String

    init(urlSession: URLSession, userAgent: String) {
        self.urlSession =  urlSession
        self.urlSessionDelegate = HTTPClientDelegate()
        self.urlSessionDelegateWithoutRedirect = HTTPClientDelegateWithoutRedirect()
        self.userAgent = userAgent
    }

    func send(_ request: HTTPRequest) async throws -> String {
        let (data, _) = try await urlSession.data(
            for: request.generate(userAgent: userAgent),
               delegate: urlSessionDelegate
        )

        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func statusCode(_ request: HTTPRequest) async throws -> Int {
        let (_, response) = try await urlSession.data(
            for: request.generate(userAgent: userAgent),
               delegate: urlSessionDelegateWithoutRedirect
        )

        return (response as? HTTPURLResponse)?.statusCode ?? 0
    }
}

struct HTTPClientMock: HTTPClient {
    func send(_ request: HTTPRequest) async throws -> String {
        ""
    }
    
    func statusCode(_ request: HTTPRequest) async throws -> Int {
        0
    }
}

class HTTPClientDelegate: URLProtocol, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Swift.Void
    ) {
        #if DEBUG
            print("")
            print("\(response.statusCode) \(task.currentRequest?.httpMethod ?? "") \(task.currentRequest?.url?.absoluteString ?? "")")
            print("  requestHeader: \(task.currentRequest?.allHTTPHeaderFields ?? [:])")
            print("  requestBody: \(String(data: task.originalRequest?.httpBody ?? Data(), encoding: .utf8) ?? "")")
            print("  responseHeader: \(response.allHeaderFields)")
            print("  redirect -> \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
            print("")
        #endif
        
        completionHandler(request)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting _: URLSessionTaskMetrics) {
        #if DEBUG
            print("")
            print("200 \(task.currentRequest!.httpMethod!) \(task.currentRequest!.url!.absoluteString)")
            print("  requestHeader: \(task.currentRequest!.allHTTPHeaderFields ?? [:])")
            print("  requestBody: \(String(data: task.originalRequest!.httpBody ?? Data(), encoding: .utf8) ?? "")")
            print("")
        #endif
    }
}

class HTTPClientDelegateWithoutRedirect: URLProtocol, URLSessionTaskDelegate {
    func urlSession(
        _: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest _: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Swift.Void
    ) {
        #if DEBUG
            print("")
            print("\(response.statusCode) \(task.currentRequest?.httpMethod ?? "") \(task.currentRequest?.url?.absoluteString ?? "")")
            print("  requestHeader: \(task.currentRequest?.allHTTPHeaderFields ?? [:])")
            print("  requestBody: \(String(data: task.originalRequest?.httpBody ?? Data(), encoding: .utf8) ?? "")")
            print("")
        #endif
        completionHandler(nil)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        #if DEBUG
            if metrics.redirectCount == 0 {
                print("")
                print("200 \(task.currentRequest?.httpMethod ?? "") \(task.currentRequest?.url?.absoluteString ?? "")")
                print("  requestHeader: \(task.currentRequest?.allHTTPHeaderFields ?? [:])")
                print("  requestBody: \(String(data: task.originalRequest?.httpBody ?? Data(), encoding: .utf8) ?? "")")
                print("")
            }
        #endif
    }
}
