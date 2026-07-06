import Foundation
import Testing

/// A test scoping trait that prints RSpec-format output after all tests complete.
///
/// Apply this trait to your test suite to enable RSpec-style documentation output:
///
/// ```swift
/// @Suite(.rspecReporting)
/// struct MyTests {
///     @UserStory("As a user, I want to...")
///     struct FeatureTests {
///         @Test func scenario1() throws { ... }
///         @Test func scenario2() throws { ... }
///     }
/// }
/// ```
///
/// The RSpec output will print after all tests in the suite complete.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct RSpecReportingTrait: TestTrait, SuiteTrait, TestScoping {
    public init() {}

    /// Non-recursive ensures this runs once for the entire suite, not per test
    public static var isRecursive: Bool { false }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        // Run all tests in the suite
        try await function()

        // After all tests complete, print the RSpec report
        if test.isSuite {
            RSpecReporter.shared.printReport()
        }
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Trait where Self == RSpecReportingTrait {
    /// Enables RSpec-style documentation output for a test suite.
    ///
    /// Apply to your top-level test suite:
    /// ```swift
    /// @Suite(.rspecReporting)
    /// struct AllTests {
    ///     // Your test suites here
    /// }
    /// ```
    public static var rspecReporting: Self { RSpecReportingTrait() }
}
