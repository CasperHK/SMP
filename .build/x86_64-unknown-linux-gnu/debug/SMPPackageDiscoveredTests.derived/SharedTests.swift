import XCTest
@testable import SharedTests

fileprivate extension AuthManagerTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__AuthManagerTests = [
        ("testInitialStateIsUnauthenticated", testInitialStateIsUnauthenticated),
        ("testLoginFailureWithUnauthorizedSetsErrorState", asyncTest(testLoginFailureWithUnauthorizedSetsErrorState)),
        ("testLoginSetsAuthenticatingBeforeResult", asyncTest(testLoginSetsAuthenticatingBeforeResult)),
        ("testLoginTransitionsToAuthenticated", asyncTest(testLoginTransitionsToAuthenticated)),
        ("testLogoutResetsState", asyncTest(testLogoutResetsState))
    ]
}

fileprivate extension ModelTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__ModelTests = [
        ("testAPIResponseRoundTrip", testAPIResponseRoundTrip),
        ("testAuthTokenIsExpiredWhenPastDate", testAuthTokenIsExpiredWhenPastDate),
        ("testAuthTokenIsNotExpiredWhenFuture", testAuthTokenIsNotExpiredWhenFuture),
        ("testLoginRequestEncoding", testLoginRequestEncoding)
    ]
}

fileprivate extension NetworkClientTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__NetworkClientTests = [
        ("testSendDecodesValidResponse", asyncTest(testSendDecodesValidResponse)),
        ("testSendPropagatesQueuedError", asyncTest(testSendPropagatesQueuedError)),
        ("testSendThrowsWhenQueueEmpty", asyncTest(testSendThrowsWhenQueueEmpty))
    ]
}

fileprivate extension NetworkRequestTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__NetworkRequestTests = [
        ("testCustomMethod", testCustomMethod),
        ("testDefaultMethodIsGet", testDefaultMethodIsGet),
        ("testHeadersArePropagated", testHeadersArePropagated)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __SharedTests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AuthManagerTests.__allTests__AuthManagerTests),
        testCase(ModelTests.__allTests__ModelTests),
        testCase(NetworkClientTests.__allTests__NetworkClientTests),
        testCase(NetworkRequestTests.__allTests__NetworkRequestTests)
    ]
}