import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HTTPMethod
// ─────────────────────────────────────────────────────────────────────────────

public enum HTTPMethod: String, Sendable {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
    case patch  = "PATCH"
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NetworkRequest
// ─────────────────────────────────────────────────────────────────────────────

public struct NetworkRequest: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?

    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NetworkClientProtocol
// ─────────────────────────────────────────────────────────────────────────────

public protocol NetworkClientProtocol: Sendable {
    func send<T: Decodable & Sendable>(_ request: NetworkRequest) async throws -> T
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NetworkClient
// ─────────────────────────────────────────────────────────────────────────────

/// Platform-agnostic HTTP client built on top of `URLSession`.
/// On Android the Swift SDK ships its own Foundation-compatible `URLSession`,
/// so this implementation works unchanged on both platforms.
public final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .secondsSince1970
        self.decoder = d
    }

    public func send<T: Decodable & Sendable>(_ request: NetworkRequest) async throws -> T {
        guard let url = URL(string: request.path, relativeTo: baseURL) else {
            throw SMPError.networkError("Invalid URL: \(request.path)")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        var headers = request.headers
        if request.body != nil && headers["Content-Type"] == nil {
            headers["Content-Type"] = "application/json"
        }
        headers["Accept"] = "application/json"
        for (field, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw SMPError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw SMPError.unauthorized
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SMPError.decodingError(error.localizedDescription)
        }
    }
}
