#if os(Android) || os(Linux)   // Linux guard lets us compile in CI on Linux
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import SMPShared

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Internal runtime state (not exported)
// ─────────────────────────────────────────────────────────────────────────────

// nonisolated(unsafe) is intentional: the C-bridge entry points are called
// sequentially from the JNI layer; external synchronisation is the caller's
// responsibility.
nonisolated(unsafe) private var _networkClient: NetworkClient?
nonisolated(unsafe) private var _authManager: AuthManager?

// Cached snapshot of auth state – updated after every login/logout so the
// synchronous query functions can read it without crossing actor boundaries.
nonisolated(unsafe) private var _cachedIsAuthenticated: Bool = false
nonisolated(unsafe) private var _cachedDisplayName: String? = nil

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps the C callback pair so it can safely cross actor boundaries.
/// @unchecked is intentional: these are opaque C pointers whose thread-safety
/// is the responsibility of the JNI caller.
private struct LoginCallbackBox: @unchecked Sendable {
    let context: UnsafeMutableRawPointer?
    let callback: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> Void

    func succeed() { callback(context, nil) }
    func fail(_ message: String) { message.withCString { callback(context, $0) } }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - C-bridge implementation  (symbols declared in smp_bridge.h)
// ─────────────────────────────────────────────────────────────────────────────

/// Initialise the SMP runtime.
@_cdecl("SMP_configure")
public func SMP_configure(_ baseURL: UnsafePointer<CChar>) {
    let urlString = String(cString: baseURL)
    guard let url = URL(string: urlString) else {
        return
    }
    let client = NetworkClient(baseURL: url)
    _networkClient = client

    // AuthManager is @MainActor; spin it up on the cooperative thread pool.
    Task { @MainActor in
        _authManager = AuthManager(networkClient: client)
    }
}

/// Asynchronous login with a completion callback suitable for JNI dispatch.
@_cdecl("SMP_auth_login")
public func SMP_auth_login(
    _ username: UnsafePointer<CChar>,
    _ password: UnsafePointer<CChar>,
    _ context: UnsafeMutableRawPointer?,
    _ callback: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> Void
) {
    let user = String(cString: username)
    let pass = String(cString: password)
    let box = LoginCallbackBox(context: context, callback: callback)

    Task { @MainActor in
        guard let manager = _authManager else {
            box.fail("SMP not configured – call SMP_configure first")
            return
        }
        do {
            try await manager.login(username: user, password: pass)
            // Update the synchronous snapshot.
            if case .authenticated(let profile) = manager.state {
                _cachedIsAuthenticated = true
                _cachedDisplayName = profile.displayName
            }
            box.succeed()
        } catch {
            _cachedIsAuthenticated = false
            _cachedDisplayName = nil
            box.fail(error.localizedDescription)
        }
    }
}

/// Synchronously clears the current session.
@_cdecl("SMP_auth_logout")
public func SMP_auth_logout() {
    Task { @MainActor in
        await _authManager?.logout()
        _cachedIsAuthenticated = false
        _cachedDisplayName = nil
    }
}

/// Returns 1 if authenticated, 0 otherwise.
/// Reads the pre-computed snapshot – safe to call from any thread.
@_cdecl("SMP_auth_isAuthenticated")
public func SMP_auth_isAuthenticated() -> Int32 {
    return _cachedIsAuthenticated ? 1 : 0
}

/// Copies the current user's display name into @p buf.
/// Reads the pre-computed snapshot – safe to call from any thread.
@_cdecl("SMP_auth_currentDisplayName")
public func SMP_auth_currentDisplayName(
    _ buf: UnsafeMutablePointer<CChar>,
    _ bufLen: Int32
) -> Int32 {
    guard let name = _cachedDisplayName else { return -1 }
    return name.withCString { src in
        let len = min(Int(bufLen) - 1, strlen(src))
        memcpy(buf, src, len)
        buf[len] = 0
        return Int32(len)
    }
}
#endif
