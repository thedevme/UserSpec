import Foundation
import Testing
import os.lock

/// Global state tracking test failures for RSpec reporting.
/// This is used to detect expectRSpec failures.
private final class FailureTracker: Sendable {
    static let shared = FailureTracker()

    private let lock: OSAllocatedUnfairLock<Set<String>>

    init() {
        lock = OSAllocatedUnfairLock(initialState: [])
    }

    func recordFailure(for testName: String) {
        lock.withLock { $0.insert(testName) }
    }

    func hasFailure(for testName: String) -> Bool {
        lock.withLock { $0.contains(testName) }
    }

    func clearFailure(for testName: String) {
        lock.withLock { $0.remove(testName) }
    }
}

/// Checks if the current test has recorded any failures via expectRSpec.
///
/// Note: This ONLY detects failures from expectRSpec().
/// Regular #expect failures from Swift Testing are NOT detected
/// because Swift Testing doesn't expose failure state through public APIs.
///
/// - Returns: true if expectRSpec recorded a failure for this test
func hasTestRecordedFailures() -> Bool {
    guard let testName = Test.current?.displayName else {
        return false
    }
    return FailureTracker.shared.hasFailure(for: testName)
}

/// Clears failure state for the current test.
/// Called at the start of each scenario.
func clearTestFailures() {
    guard let testName = Test.current?.displayName else {
        return
    }
    FailureTracker.shared.clearFailure(for: testName)
}

/// A throwing expectation for use with RSpec reporting.
///
/// Unlike `#expect`, this function throws when the condition is false,
/// allowing the RSpec reporter to correctly detect failures.
///
/// ## Example
///
/// ```swift
/// .then("user is authenticated") { result, _ in
///     try expectRSpec(result.isAuthenticated)
/// }
/// ```
///
/// - Parameters:
///   - condition: The condition to evaluate
///   - message: Optional failure message
/// - Throws: `RSpecExpectationFailure` if the condition is false
public func expectRSpec(
    _ condition: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String = ""
) throws {
    let result = try condition()
    guard result else {
        // Record the failure for RSpec reporting
        if let testName = Test.current?.displayName {
            FailureTracker.shared.recordFailure(for: testName)
        }

        let failureMessage = message()
        throw RSpecExpectationFailure(
            message: failureMessage.isEmpty ? "Expectation failed" : failureMessage
        )
    }
}

/// Error thrown when an RSpec expectation fails.
public struct RSpecExpectationFailure: Error, CustomStringConvertible {
    public let message: String

    public var description: String {
        message
    }
}
