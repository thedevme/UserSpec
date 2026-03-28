import Foundation

// MARK: - Mocking Framework
//
// Lightweight mocking, stubbing, and spying for UserSpec tests.

// MARK: - Mock Protocol

/// A type that can record and verify method calls.
///
/// Conform to this protocol to create mock objects that track invocations.
///
/// ## Example
///
/// ```swift
/// class MockPaymentService: PaymentService, Mockable {
///     let recorder = CallRecorder()
///
///     func charge(amount: Decimal) -> PaymentResult {
///         recorder.record(#function, args: [amount])
///         return recorder.stub(for: #function) ?? .success
///     }
/// }
///
/// // In test
/// let mock = MockPaymentService()
/// mock.recorder.stub(for: "charge(amount:)", return: .declined)
///
/// // ... run test ...
///
/// #expect(mock.recorder.wasCalled("charge(amount:)"))
/// ```
public protocol Mockable: AnyObject {
    var recorder: CallRecorder { get }
}

// MARK: - Call Recorder

/// Records method calls and manages stubs for mock objects.
///
/// Thread-safe call recording and stub management.
public final class CallRecorder: @unchecked Sendable {

    private var calls: [RecordedCall] = []
    private var stubs: [String: Any] = [:]
    private let lock = NSLock()

    public init() {}

    /// A recorded method call.
    public struct RecordedCall: @unchecked Sendable {
        public let method: String
        public let arguments: [Any]
        public let timestamp: Date

        public init(method: String, arguments: [Any], timestamp: Date = Date()) {
            self.method = method
            self.arguments = arguments
            self.timestamp = timestamp
        }
    }

    // MARK: - Recording

    /// Records a method call.
    ///
    /// - Parameters:
    ///   - method: The method name (use `#function`).
    ///   - args: The arguments passed to the method.
    public func record(_ method: String, args: [Any] = []) {
        lock.lock()
        defer { lock.unlock() }
        calls.append(RecordedCall(method: method, arguments: args, timestamp: Date()))
    }

    /// Returns all recorded calls.
    public func allCalls() -> [RecordedCall] {
        lock.lock()
        defer { lock.unlock() }
        return calls
    }

    /// Returns calls matching the given method name.
    public func calls(for method: String) -> [RecordedCall] {
        lock.lock()
        defer { lock.unlock() }
        return calls.filter { $0.method == method }
    }

    /// Clears all recorded calls.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        calls.removeAll()
        stubs.removeAll()
    }

    // MARK: - Verification

    /// Returns whether a method was called.
    public func wasCalled(_ method: String) -> Bool {
        !calls(for: method).isEmpty
    }

    /// Returns the number of times a method was called.
    public func callCount(for method: String) -> Int {
        calls(for: method).count
    }

    /// Returns whether a method was called exactly n times.
    public func wasCalled(_ method: String, times: Int) -> Bool {
        callCount(for: method) == times
    }

    /// Returns whether a method was never called.
    public func wasNotCalled(_ method: String) -> Bool {
        calls(for: method).isEmpty
    }

    /// Returns the arguments from the last call to a method.
    public func lastArguments(for method: String) -> [Any]? {
        calls(for: method).last?.arguments
    }

    /// Returns the arguments from the nth call to a method (0-indexed).
    public func arguments(for method: String, callIndex: Int) -> [Any]? {
        let methodCalls = calls(for: method)
        guard callIndex >= 0 && callIndex < methodCalls.count else { return nil }
        return methodCalls[callIndex].arguments
    }

    // MARK: - Stubbing

    /// Sets a stub return value for a method.
    ///
    /// - Parameters:
    ///   - method: The method name.
    ///   - value: The value to return when the method is called.
    public func stub<T>(for method: String, return value: T) {
        lock.lock()
        defer { lock.unlock() }
        stubs[method] = value
    }

    /// Returns the stubbed value for a method.
    ///
    /// - Parameter method: The method name.
    /// - Returns: The stubbed value, or nil if not stubbed.
    public func stub<T>(for method: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return stubs[method] as? T
    }

    /// Sets a stub closure that computes the return value.
    ///
    /// - Parameters:
    ///   - method: The method name.
    ///   - handler: A closure that returns the stubbed value.
    public func stub<T>(for method: String, handler: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        stubs[method] = handler
    }

    /// Returns the result of invoking a stub handler.
    public func invokeStub<T>(for method: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        if let handler = stubs[method] as? () -> T {
            return handler()
        }
        return stubs[method] as? T
    }
}

// MARK: - Spy

/// A spy that wraps a real object and records all method calls.
///
/// Use spies when you want to verify interactions while using real behavior.
///
/// ## Example
///
/// ```swift
/// let realService = PaymentService()
/// let spy = Spy(realService)
///
/// // Call through spy
/// spy.subject.charge(100)
///
/// // Verify
/// #expect(spy.recorder.wasCalled("charge"))
/// ```
public final class Spy<T>: @unchecked Sendable {

    /// The wrapped object.
    public let subject: T

    /// The call recorder.
    public let recorder = CallRecorder()

    /// Creates a spy wrapping the given object.
    public init(_ subject: T) {
        self.subject = subject
    }

    /// Records a method call and returns the subject for chaining.
    @discardableResult
    public func record(_ method: String, args: [Any] = []) -> T {
        recorder.record(method, args: args)
        return subject
    }
}

// MARK: - Stub Builder

/// Fluent API for building stubs.
///
/// ## Example
///
/// ```swift
/// let stub = Stub<PaymentService>()
///     .when("charge(amount:)") { .success }
///     .when("refund(id:)") { .pending }
///
/// // Use in mock
/// mock.recorder = stub.recorder
/// ```
public struct Stub<T> {

    /// The underlying call recorder.
    public let recorder = CallRecorder()

    public init() {}

    /// Adds a stub for a method.
    @discardableResult
    public func when<R>(_ method: String, return value: R) -> Stub<T> {
        recorder.stub(for: method, return: value)
        return self
    }

    /// Adds a stub closure for a method.
    @discardableResult
    public func when<R>(_ method: String, handler: @escaping () -> R) -> Stub<T> {
        recorder.stub(for: method, handler: handler)
        return self
    }
}

// MARK: - Argument Matchers

/// Matchers for verifying method arguments.
public enum ArgumentMatcher {

    /// Matches any value.
    public static func any<T>() -> AnyMatcher<T> {
        AnyMatcher<T>()
    }

    /// Matches a specific value using equality.
    public static func equal<T: Equatable & Sendable>(to value: T) -> EqualMatcher<T> {
        EqualMatcher(expected: value)
    }

    /// Matches values satisfying a predicate.
    public static func matching<T>(_ predicate: @escaping @Sendable (T) -> Bool) -> PredicateMatcher<T> {
        PredicateMatcher(predicate: predicate)
    }

    /// Matches nil values.
    public static func isNil<T>() -> NilMatcher<T> {
        NilMatcher<T>()
    }

    /// Matches non-nil values.
    public static func isNotNil<T>() -> NotNilMatcher<T> {
        NotNilMatcher<T>()
    }
}

/// Protocol for argument matchers.
public protocol ArgumentMatcherProtocol: Sendable {
    func matches(_ value: Any) -> Bool
}

// MARK: - Matcher Types

/// Matches any value of type T.
public struct AnyMatcher<T>: ArgumentMatcherProtocol {
    public init() {}
    public func matches(_ value: Any) -> Bool { value is T }
}

/// Matches a specific equatable value.
public struct EqualMatcher<T: Equatable & Sendable>: ArgumentMatcherProtocol {
    let expected: T
    public init(expected: T) { self.expected = expected }
    public func matches(_ value: Any) -> Bool {
        guard let typed = value as? T else { return false }
        return typed == expected
    }
}

/// Matches values satisfying a predicate.
public struct PredicateMatcher<T>: ArgumentMatcherProtocol {
    let predicate: @Sendable (T) -> Bool
    public init(predicate: @escaping @Sendable (T) -> Bool) { self.predicate = predicate }
    public func matches(_ value: Any) -> Bool {
        guard let typed = value as? T else { return false }
        return predicate(typed)
    }
}

/// Matches nil values.
public struct NilMatcher<T>: ArgumentMatcherProtocol {
    public init() {}
    public func matches(_ value: Any) -> Bool {
        // Use Mirror to check if the value is an optional containing nil
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional && mirror.children.isEmpty {
            return true
        }
        return false
    }
}

/// Matches non-nil values.
public struct NotNilMatcher<T>: ArgumentMatcherProtocol {
    public init() {}
    public func matches(_ value: Any) -> Bool {
        // Use Mirror to check if the value is not nil
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return !mirror.children.isEmpty
        }
        // Non-optional values are always "not nil"
        return value is T
    }
}

// MARK: - Verification Helpers

/// Verification utilities for mock objects.
public enum Verify {

    /// Verifies a method was called on a mock.
    ///
    /// - Parameters:
    ///   - mock: The mock object.
    ///   - method: The method name.
    /// - Returns: True if the method was called.
    public static func called<M: Mockable>(_ mock: M, _ method: String) -> Bool {
        mock.recorder.wasCalled(method)
    }

    /// Verifies a method was called a specific number of times.
    public static func called<M: Mockable>(_ mock: M, _ method: String, times: Int) -> Bool {
        mock.recorder.wasCalled(method, times: times)
    }

    /// Verifies a method was never called.
    public static func notCalled<M: Mockable>(_ mock: M, _ method: String) -> Bool {
        mock.recorder.wasNotCalled(method)
    }

    /// Verifies method arguments match expected matchers.
    public static func calledWith<M: Mockable>(
        _ mock: M,
        _ method: String,
        matchers: [ArgumentMatcherProtocol]
    ) -> Bool {
        guard let args = mock.recorder.lastArguments(for: method) else { return false }
        guard args.count == matchers.count else { return false }

        for (arg, matcher) in zip(args, matchers) {
            if !matcher.matches(arg) { return false }
        }
        return true
    }
}

// MARK: - Mock Expectations

/// A verification failure for mock expectations.
public struct MockVerificationFailure: Error, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

/// Throws if verification fails.
public func verifyMock<M: Mockable>(
    _ mock: M,
    called method: String,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    guard mock.recorder.wasCalled(method) else {
        throw MockVerificationFailure("Expected \(method) to be called, but it was not")
    }
}

/// Throws if verification fails.
public func verifyMock<M: Mockable>(
    _ mock: M,
    called method: String,
    times: Int,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let actual = mock.recorder.callCount(for: method)
    guard actual == times else {
        throw MockVerificationFailure("Expected \(method) to be called \(times) time(s), but was called \(actual) time(s)")
    }
}

/// Throws if the method was called.
public func verifyMock<M: Mockable>(
    _ mock: M,
    notCalled method: String,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    guard mock.recorder.wasNotCalled(method) else {
        let count = mock.recorder.callCount(for: method)
        throw MockVerificationFailure("Expected \(method) not to be called, but was called \(count) time(s)")
    }
}
