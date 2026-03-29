import Foundation
import Observation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AuthState
// ─────────────────────────────────────────────────────────────────────────────

public enum AuthState: Sendable, Equatable {
    case unauthenticated
    case authenticating
    case authenticated(UserProfile)
    case error(String)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AuthManagerProtocol
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
public protocol AuthManagerProtocol: AnyObject {
    var state: AuthState { get }
    func login(username: String, password: String) async throws
    func logout() async
    func refreshIfNeeded() async throws
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AuthManager
// ─────────────────────────────────────────────────────────────────────────────

/// Manages authentication state using Swift Observation (Swift 5.9 / 6+).
/// UI layers on both iOS and Android observe `state` directly – no Combine
/// or manual delegate wiring required.
@MainActor
@Observable
public final class AuthManager: AuthManagerProtocol {

    // MARK: Observed state
    public private(set) var state: AuthState = .unauthenticated

    // MARK: Private storage
    private let networkClient: any NetworkClientProtocol
    private var currentToken: AuthToken?

    // MARK: Init
    public init(networkClient: any NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - Login
    public func login(username: String, password: String) async throws {
        state = .authenticating

        let loginBody = LoginRequest(username: username, password: password)
        let bodyData = try JSONEncoder().encode(loginBody)

        let request = NetworkRequest(
            path: "auth/login",
            method: .post,
            body: bodyData
        )

        do {
            let response: APIResponse<AuthToken> = try await networkClient.send(request)
            currentToken = response.data

            let profileRequest = NetworkRequest(
                path: "auth/profile",
                headers: ["Authorization": "Bearer \(response.data.accessToken)"]
            )
            let profileResponse: APIResponse<UserProfile> = try await networkClient.send(profileRequest)
            state = .authenticated(profileResponse.data)
        } catch SMPError.unauthorized {
            state = .error("Invalid credentials")
            throw SMPError.unauthorized
        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Logout
    public func logout() async {
        currentToken = nil
        state = .unauthenticated
    }

    // MARK: - Token refresh
    public func refreshIfNeeded() async throws {
        guard let token = currentToken else {
            throw SMPError.unauthorized
        }
        guard token.isExpired else { return }

        let bodyData = try JSONEncoder().encode(["refreshToken": token.refreshToken])
        let request = NetworkRequest(
            path: "auth/refresh",
            method: .post,
            body: bodyData
        )
        let response: APIResponse<AuthToken> = try await networkClient.send(request)
        currentToken = response.data
    }
}
