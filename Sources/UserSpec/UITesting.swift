// MARK: - UI Testing Support
//
// These types provide BDD-style UI testing with XCUITest.
// Use in UI test targets only.

#if canImport(XCTest)
import Foundation
import Testing
import XCTest

// MARK: - UI Given Step

/// Entry point for UI test chains - sets up the app context
///
/// Use `givenApp` to create a UI test chain:
/// ```swift
/// givenApp("user is on login screen") { app in
///     app.launch()
///     return app
/// }
/// .whenTap("login button") { app in
///     app.buttons["Login"].tap()
/// }
/// .thenSee("home screen") { app in
///     #expect(app.navigationBars["Home"].exists)
/// }
/// ```
public struct UIGivenStep<App> {
    public let description: String
    let setup: () throws -> App

    public init(_ description: String, setup: @escaping () throws -> App) {
        self.description = description
        self.setup = setup
    }

    /// Chain to a tap action
    ///
    /// - Parameters:
    ///   - description: Description of the tap action
    ///   - action: Closure that performs the tap and returns a result
    /// - Returns: A `UIWhenStep` to continue the chain
    public func whenTap<Result>(
        _ description: String,
        action: @escaping (App) throws -> Result
    ) -> UIWhenStep<App, Result> {
        UIWhenStep(
            givenDescription: self.description,
            description: description,
            setup: setup,
            action: action
        )
    }

    /// Chain to a generic action (not just tap)
    ///
    /// - Parameters:
    ///   - description: Description of the action
    ///   - action: Closure that performs the action and returns a result
    /// - Returns: A `UIWhenStep` to continue the chain
    public func when<Result>(
        _ description: String,
        action: @escaping (App) throws -> Result
    ) -> UIWhenStep<App, Result> {
        UIWhenStep(
            givenDescription: self.description,
            description: description,
            setup: setup,
            action: action
        )
    }
}

// MARK: - UI When Step

/// Intermediate step in UI test chain - captures the action
public struct UIWhenStep<App, Result> {
    public let givenDescription: String
    public let description: String
    let setup: () throws -> App
    let action: (App) throws -> Result

    public init(
        givenDescription: String,
        description: String,
        setup: @escaping () throws -> App,
        action: @escaping (App) throws -> Result
    ) {
        self.givenDescription = givenDescription
        self.description = description
        self.setup = setup
        self.action = action
    }

    /// Execute the chain with a visual assertion
    ///
    /// - Parameters:
    ///   - description: Description of what should be visible
    ///   - assertion: Closure that verifies the expected UI state
    public func thenSee(
        _ description: String,
        assertion: @escaping (Result, StepContext) throws -> Void
    ) throws {
        let app = try setup()
        let result = try action(app)
        let stepContext = StepContext(
            given: givenDescription,
            when: self.description,
            then: description
        )

        // Execute assertion and track result for RSpec reporting
        var passed = true
        var errorMessage: String? = nil

        do {
            try assertion(result, stepContext)

            // Check if #expect recorded any failures even though no exception was thrown
            if RSpecReporter.isEnabled && hasTestRecordedFailures() {
                passed = false
                errorMessage = "Expectation failed (detected via #expect)"
            }
        } catch {
            passed = false
            errorMessage = String(describing: error)

            // Mark scenario complete before rethrowing (only when enabled)
            if RSpecReporter.isEnabled,
               let scenarioName = Test.current?.displayName {
                RSpecReporter.shared.markScenarioComplete(scenarioName, passed: false, error: errorMessage)
            }

            throw error
        }

        // Print scenario result directly (doesn't rely on Test.current)
        if RSpecReporter.isEnabled {
            let symbol = passed ? "✅" : "❌"
            print("\(symbol)")
            print("  Given \(stepContext.givenDescription)")
            print("  When \(stepContext.whenDescription)")
            print("  Then \(stepContext.thenDescription)")
            if let error = errorMessage {
                print("  ❌ Error: \(error)")
            }
        }
    }

    /// Execute the chain with a generic assertion
    ///
    /// - Parameters:
    ///   - description: Description of the expected outcome
    ///   - assertion: Closure that verifies the expected state
    public func then(
        _ description: String,
        assertion: @escaping (Result, StepContext) throws -> Void
    ) throws {
        try thenSee(description, assertion: assertion)
    }
}

// MARK: - Async UI Given Step

/// Async variant of UIGivenStep for async UI operations
public struct AsyncUIGivenStep<App> {
    public let description: String
    let setup: () async throws -> App

    public init(_ description: String, setup: @escaping () async throws -> App) {
        self.description = description
        self.setup = setup
    }

    /// Chain to an async tap action
    public func whenTap<Result>(
        _ description: String,
        action: @escaping (App) async throws -> Result
    ) -> AsyncUIWhenStep<App, Result> {
        AsyncUIWhenStep(
            givenDescription: self.description,
            description: description,
            setup: setup,
            action: action
        )
    }

    /// Chain to a generic async action
    public func when<Result>(
        _ description: String,
        action: @escaping (App) async throws -> Result
    ) -> AsyncUIWhenStep<App, Result> {
        AsyncUIWhenStep(
            givenDescription: self.description,
            description: description,
            setup: setup,
            action: action
        )
    }
}

// MARK: - Async UI When Step

/// Async variant of UIWhenStep
public struct AsyncUIWhenStep<App, Result> {
    public let givenDescription: String
    public let description: String
    let setup: () async throws -> App
    let action: (App) async throws -> Result

    public init(
        givenDescription: String,
        description: String,
        setup: @escaping () async throws -> App,
        action: @escaping (App) async throws -> Result
    ) {
        self.givenDescription = givenDescription
        self.description = description
        self.setup = setup
        self.action = action
    }

    /// Execute the async chain with a visual assertion
    public func thenSee(
        _ description: String,
        assertion: @escaping (Result, StepContext) async throws -> Void
    ) async throws {
        let app = try await setup()
        let result = try await action(app)
        let stepContext = StepContext(
            given: givenDescription,
            when: self.description,
            then: description
        )

        // Execute assertion and track result for RSpec reporting
        var passed = true
        var errorMessage: String? = nil

        do {
            try await assertion(result, stepContext)

            // Check if #expect recorded any failures even though no exception was thrown
            if RSpecReporter.isEnabled && hasTestRecordedFailures() {
                passed = false
                errorMessage = "Expectation failed (detected via #expect)"
            }
        } catch {
            passed = false
            errorMessage = String(describing: error)

            // Mark scenario complete before rethrowing (only when enabled)
            if RSpecReporter.isEnabled,
               let scenarioName = Test.current?.displayName {
                RSpecReporter.shared.markScenarioComplete(scenarioName, passed: false, error: errorMessage)
            }

            throw error
        }

        // Print scenario result directly (doesn't rely on Test.current)
        if RSpecReporter.isEnabled {
            let symbol = passed ? "✅" : "❌"
            print("\(symbol)")
            print("  Given \(stepContext.givenDescription)")
            print("  When \(stepContext.whenDescription)")
            print("  Then \(stepContext.thenDescription)")
            if let error = errorMessage {
                print("  ❌ Error: \(error)")
            }
        }
    }

    /// Execute the async chain with a generic assertion
    public func then(
        _ description: String,
        assertion: @escaping (Result, StepContext) async throws -> Void
    ) async throws {
        try await thenSee(description, assertion: assertion)
    }
}

// MARK: - Free Functions

/// Entry point for UI test chains
///
/// Creates a UI test chain starting with app setup.
///
/// ## Example
///
/// ```swift
/// @Test
/// @UIScenario("User can login successfully")
/// func testLogin() throws {
///     let app = XCUIApplication()
///
///     try givenApp("app is launched") {
///         app.launch()
///         return app
///     }
///     .whenTap("login button") { app in
///         app.buttons["Login"].tap()
///         return app
///     }
///     .thenSee("home screen is displayed") { app, context in
///         #expect(app.navigationBars["Home"].exists)
///     }
/// }
/// ```
///
/// - Parameters:
///   - description: Description of the initial app state
///   - setup: Closure that sets up and returns the app
/// - Returns: A `UIGivenStep` to start the chain
public func givenApp<App>(
    _ description: String,
    setup: @escaping () throws -> App
) -> UIGivenStep<App> {
    // Register scenario start for RSpec reporting (only when enabled)
    if RSpecReporter.isEnabled,
       let scenarioName = Test.current?.displayName {
        ensureRSpecReporterBootstrapped()
        clearTestFailures()  // Clear any previous failure state
        let storyName = extractUserStoryDescription()
        RSpecReporter.shared.registerScenarioStart(scenarioName, story: storyName)
    }

    return UIGivenStep(description, setup: setup)
}

/// Async entry point for UI test chains
///
/// - Parameters:
///   - description: Description of the initial app state
///   - setup: Async closure that sets up and returns the app
/// - Returns: An `AsyncUIGivenStep` to start the chain
public func givenApp<App>(
    _ description: String,
    setup: @escaping () async throws -> App
) -> AsyncUIGivenStep<App> {
    // Register scenario start for RSpec reporting (only when enabled)
    if RSpecReporter.isEnabled,
       let scenarioName = Test.current?.displayName {
        ensureRSpecReporterBootstrapped()
        clearTestFailures()  // Clear any previous failure state
        let storyName = extractUserStoryDescription()
        RSpecReporter.shared.registerScenarioStart(scenarioName, story: storyName)
    }

    return AsyncUIGivenStep(description, setup: setup)
}

// MARK: - XCUIApplication Extensions

/// Convenience extension for XCUIApplication to work seamlessly with UserSpec
extension XCUIApplication {
    /// Launches the app and returns self for chaining
    ///
    /// Use in `givenApp` setup closures:
    /// ```swift
    /// givenApp("app is launched") {
    ///     XCUIApplication().launched()
    /// }
    /// ```
    @discardableResult
    public func launched() -> XCUIApplication {
        launch()
        return self
    }

    /// Launches the app with arguments and returns self for chaining
    ///
    /// - Parameter arguments: Launch arguments to pass to the app
    /// - Returns: Self for chaining
    @discardableResult
    public func launched(with arguments: [String]) -> XCUIApplication {
        launchArguments = arguments
        launch()
        return self
    }

    /// Launches the app with environment variables and returns self for chaining
    ///
    /// - Parameter environment: Environment variables to set
    /// - Returns: Self for chaining
    @discardableResult
    public func launched(environment: [String: String]) -> XCUIApplication {
        launchEnvironment = environment
        launch()
        return self
    }
}

#endif
