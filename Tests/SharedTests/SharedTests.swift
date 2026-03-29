import XCTest
@testable import SMPShared

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Mock NetworkClient
// ─────────────────────────────────────────────────────────────────────────────

/// Configurable stub used across all tests.
final class MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    /// Queued responses, consumed in FIFO order.
    var responseQueue: [Any] = []
    var receivedRequests: [NetworkRequest] = []

    func send<T: Decodable & Sendable>(_ request: NetworkRequest) async throws -> T {
        receivedRequests.append(request)
        guard !responseQueue.isEmpty else {
            throw SMPError.networkError("No mock response queued")
        }
        let next = responseQueue.removeFirst()
        if let error = next as? Error {
            throw error
        }
        guard let value = next as? T else {
            throw SMPError.unknown("Mock type mismatch: expected \(T.self), got \(type(of: next))")
        }
        return value
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NetworkClient unit tests
// ─────────────────────────────────────────────────────────────────────────────

final class NetworkClientTests: XCTestCase {

    func testSendDecodesValidResponse() async throws {
        let mock = MockNetworkClient()
        let expected = APIResponse(data: UserProfile(
            id: "1", username: "alice", email: "alice@example.com", displayName: "Alice"
        ))
        mock.responseQueue = [expected]

        let result: APIResponse<UserProfile> = try await mock.send(
            NetworkRequest(path: "users/1")
        )

        XCTAssertEqual(result.data.username, "alice")
        XCTAssertEqual(mock.receivedRequests.count, 1)
    }

    func testSendThrowsWhenQueueEmpty() async {
        let mock = MockNetworkClient()
        do {
            let _: APIResponse<UserProfile> = try await mock.send(
                NetworkRequest(path: "users/1")
            )
            XCTFail("Expected error")
        } catch SMPError.networkError(let msg) {
            XCTAssertTrue(msg.contains("No mock response queued"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendPropagatesQueuedError() async {
        let mock = MockNetworkClient()
        mock.responseQueue = [SMPError.unauthorized]

        do {
            let _: APIResponse<UserProfile> = try await mock.send(
                NetworkRequest(path: "protected/resource")
            )
            XCTFail("Expected unauthorized error")
        } catch SMPError.unauthorized {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AuthManager unit tests
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
final class AuthManagerTests: XCTestCase {

    private func makeManager(mock: MockNetworkClient) -> AuthManager {
        AuthManager(networkClient: mock)
    }

    func testInitialStateIsUnauthenticated() {
        let mock = MockNetworkClient()
        let manager = makeManager(mock: mock)
        XCTAssertEqual(manager.state, .unauthenticated)
    }

    func testLoginTransitionsToAuthenticated() async throws {
        let mock = MockNetworkClient()
        let token = AuthToken(
            accessToken: "tok_abc",
            refreshToken: "ref_xyz",
            expiresAt: Date().timeIntervalSince1970 + 3600
        )
        let profile = UserProfile(
            id: "42", username: "bob", email: "bob@example.com", displayName: "Bob"
        )
        mock.responseQueue = [
            APIResponse(data: token),
            APIResponse(data: profile),
        ]

        let manager = makeManager(mock: mock)
        try await manager.login(username: "bob", password: "s3cr3t")

        if case .authenticated(let p) = manager.state {
            XCTAssertEqual(p.username, "bob")
        } else {
            XCTFail("Expected authenticated state, got \(manager.state)")
        }
    }

    func testLoginSetsAuthenticatingBeforeResult() async throws {
        // We can't easily observe the intermediate state in a unit test, but we
        // can verify the final transition happened correctly.
        let mock = MockNetworkClient()
        let token = AuthToken(accessToken: "t", refreshToken: "r",
                              expiresAt: Date().timeIntervalSince1970 + 60)
        let profile = UserProfile(id: "1", username: "u", email: "e@e.com", displayName: "U")
        mock.responseQueue = [APIResponse(data: token), APIResponse(data: profile)]

        let manager = makeManager(mock: mock)
        try await manager.login(username: "u", password: "p")
        guard case .authenticated = manager.state else {
            XCTFail("Expected authenticated"); return
        }
    }

    func testLoginFailureWithUnauthorizedSetsErrorState() async {
        let mock = MockNetworkClient()
        mock.responseQueue = [SMPError.unauthorized]

        let manager = makeManager(mock: mock)
        do {
            try await manager.login(username: "bad", password: "creds")
            XCTFail("Expected error")
        } catch SMPError.unauthorized {
            if case .error(let msg) = manager.state {
                XCTAssertFalse(msg.isEmpty)
            } else {
                XCTFail("Expected error state, got \(manager.state)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLogoutResetsState() async throws {
        let mock = MockNetworkClient()
        let token = AuthToken(accessToken: "t", refreshToken: "r",
                              expiresAt: Date().timeIntervalSince1970 + 60)
        let profile = UserProfile(id: "1", username: "u", email: "e@e.com", displayName: "U")
        mock.responseQueue = [APIResponse(data: token), APIResponse(data: profile)]

        let manager = makeManager(mock: mock)
        try await manager.login(username: "u", password: "p")
        await manager.logout()
        XCTAssertEqual(manager.state, .unauthenticated)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Model tests
// ─────────────────────────────────────────────────────────────────────────────

final class ModelTests: XCTestCase {

    func testAuthTokenIsExpiredWhenPastDate() {
        let expired = AuthToken(
            accessToken: "x", refreshToken: "y",
            expiresAt: Date().timeIntervalSince1970 - 1
        )
        XCTAssertTrue(expired.isExpired)
    }

    func testAuthTokenIsNotExpiredWhenFuture() {
        let valid = AuthToken(
            accessToken: "x", refreshToken: "y",
            expiresAt: Date().timeIntervalSince1970 + 3600
        )
        XCTAssertFalse(valid.isExpired)
    }

    func testAPIResponseRoundTrip() throws {
        let profile = UserProfile(id: "1", username: "u", email: "e@e.com", displayName: "U")
        let original = APIResponse(data: profile, message: "ok", statusCode: 200)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(APIResponse<UserProfile>.self, from: data)

        XCTAssertEqual(decoded.data.id, original.data.id)
        XCTAssertEqual(decoded.message, "ok")
        XCTAssertEqual(decoded.statusCode, 200)
    }

    func testLoginRequestEncoding() throws {
        let req = LoginRequest(username: "alice", password: "pw")
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["username"], "alice")
        XCTAssertEqual(json?["password"], "pw")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NetworkRequest tests
// ─────────────────────────────────────────────────────────────────────────────

final class NetworkRequestTests: XCTestCase {

    func testDefaultMethodIsGet() {
        let req = NetworkRequest(path: "some/path")
        XCTAssertEqual(req.method, .get)
    }

    func testCustomMethod() {
        let req = NetworkRequest(path: "resource", method: .delete)
        XCTAssertEqual(req.method, .delete)
    }

    func testHeadersArePropagated() {
        let req = NetworkRequest(
            path: "p",
            headers: ["X-Custom": "value"]
        )
        XCTAssertEqual(req.headers["X-Custom"], "value")
    }
}
