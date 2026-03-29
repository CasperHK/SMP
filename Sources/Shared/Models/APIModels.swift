import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Request / Response models
// ─────────────────────────────────────────────────────────────────────────────

/// Generic wrapper for every paginated or single-item API response.
public struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    public let data: T
    public let message: String?
    public let statusCode: Int

    public init(data: T, message: String? = nil, statusCode: Int = 200) {
        self.data = data
        self.message = message
        self.statusCode = statusCode
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Auth models
// ─────────────────────────────────────────────────────────────────────────────

public struct LoginRequest: Codable, Sendable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct AuthToken: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    /// Expiry expressed as seconds since Unix epoch.
    public let expiresAt: TimeInterval

    public init(accessToken: String, refreshToken: String, expiresAt: TimeInterval) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool {
        Date().timeIntervalSince1970 >= expiresAt
    }
}

public struct UserProfile: Codable, Sendable, Equatable {
    public let id: String
    public let username: String
    public let email: String
    public let displayName: String

    public init(id: String, username: String, email: String, displayName: String) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
    }
}
