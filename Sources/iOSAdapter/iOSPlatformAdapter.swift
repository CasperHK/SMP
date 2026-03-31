#if canImport(UIKit)
import UIKit
import SMPShared

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - iOSPlatformAdapter
// ─────────────────────────────────────────────────────────────────────────────

/// Bootstraps the SMP framework on iOS / iPadOS.
/// Call `iOSPlatformAdapter.configure(baseURL:)` inside
/// `application(_:didFinishLaunchingWithOptions:)` or at the top of your
/// `@main App` struct.
public final class iOSPlatformAdapter: @unchecked Sendable {

    public static let shared = iOSPlatformAdapter()
    private init() {}

    // MARK: Publicly accessible services
    public private(set) var networkClient: NetworkClient!
    public private(set) var authManager: AuthManager!

    // MARK: Configuration
    public func configure(baseURL: URL) {
        networkClient = NetworkClient(baseURL: baseURL)
        Task { @MainActor in
            authManager = AuthManager(networkClient: networkClient)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SMPError + UIKit localised description
// ─────────────────────────────────────────────────────────────────────────────

extension SMPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let msg):   return "Network error: \(msg)"
        case .decodingError(let msg):  return "Decoding error: \(msg)"
        case .unauthorized:            return "You are not authorised to perform this action."
        case .unknown(let msg):        return "Unknown error: \(msg)"
        }
    }
}
#endif
