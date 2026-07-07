import Foundation
import Testing

// MARK: - Step Context

/// Captures descriptions from all steps in a chain for failure reporting.
///
/// `StepContext` is passed to your assertion closure in `.then()`, containing
/// the descriptions from each step in the chain. Use it for debugging or
/// custom failure messages.
///
/// ## Example
///
/// ```swift
/// .then("expected outcome") { result, context in
///     print(context.formatFailureMessage())
///     #expect(result == expected)
/// }
/// ```
///
/// ## See Also
///
/// - ``GivenStep``
/// - ``WhenStep``
public struct StepContext: Sendable {
    /// The description from the `given()` step.
    public let givenDescription: String

    /// The description from the `.when()` step.
    public let whenDescription: String

    /// The description from the `.then()` step.
    public let thenDescription: String

    /// Creates a new step context with the given descriptions.
    ///
    /// - Parameters:
    ///   - given: The description from the given step.
    ///   - when: The description from the when step.
    ///   - then: The description from the then step.
    public init(given: String, when: String, then: String) {
        self.givenDescription = given
        self.whenDescription = when
        self.thenDescription = then
    }

    /// Formats a failure message showing the full chain context.
    ///
    /// Returns a multi-line string with all step descriptions:
    /// ```
    /// Given: a user is logged in
    /// When: they click logout
    /// Then: they are redirected to login page
    /// ```
    ///
    /// - Returns: A formatted string containing all step descriptions.
    public func formatFailureMessage() -> String {
        """
        Given: \(givenDescription)
        When: \(whenDescription)
        Then: \(thenDescription)
        """
    }
}

// MARK: - Given Step

/// Entry point for BDD chains — captures the setup context.
///
/// Create a `GivenStep` using the ``given(_:setup:)-4l5wm`` free function.
/// Chain it with ``when(_:action:)`` to describe the action, then terminate
/// with `.then()` to verify the result.
///
/// ## Example
///
/// ```swift
/// given("user has an economy ticket") {
///     User(ticketClass: .economy)
/// }
/// .when("they tap seat 1A") { user in
///     SeatMap().select(seat: "1A", for: user)
/// }
/// .then("selection fails") { result, context in
///     #expect(result == .failed(.classRestriction))
/// }
/// ```
///
/// ## Topics
///
/// ### Chaining
///
/// - ``when(_:action:)``
///
/// ## See Also
///
/// - ``given(_:setup:)-4l5wm``
/// - ``WhenStep``
/// - ``AsyncGivenStep``
public struct GivenStep<Context: Sendable>: Sendable {
    /// The description of the initial state being set up.
    public let description: String

    let setup: @Sendable () throws -> Context

    /// Creates a new given step with a description and setup closure.
    ///
    /// - Parameters:
    ///   - description: A description of the initial state.
    ///   - setup: A closure that creates and returns the test context.
    public init(_ description: String, setup: @escaping @Sendable () throws -> Context) {
        self.description = description
        self.setup = setup
    }

    /// Chains to a when step with an action.
    ///
    /// The action closure receives the context created by the setup closure
    /// and returns a result that will be passed to the assertion.
    ///
    /// - Parameters:
    ///   - description: A description of the action being performed.
    ///   - action: A closure that performs the action and returns a result.
    /// - Returns: A ``WhenStep`` ready to be terminated with `.then()`.
    public func when<Result: Sendable>(
        _ description: String,
        action: @escaping @Sendable (Context) throws -> Result
    ) -> WhenStep<Context, Result> {
        WhenStep(
            givenDescription: self.description,
            description: description,
            setup: setup,
            action: action
        )
    }
}

// MARK: - When Step

/// Intermediate step in the BDD chain — captures the action.
///
/// A `WhenStep` is created by calling ``GivenStep/when(_:action:)`` on a
/// ``GivenStep``. Terminate the chain with ``then(_:assertion:)`` to execute
/// the full test.
///
/// ## Example
///
/// ```swift
/// given("a shopping cart") { Cart() }
/// .when("user adds an item") { cart in      // Creates WhenStep
///     cart.add(Item(name: "Book"))
/// }
/// .then("cart has one item") { cart, _ in
///     #expect(cart.items.count == 1)
/// }
/// ```
///
/// ## Topics
///
/// ### Executing the Chain
///
/// - ``then(_:assertion:)``
///
/// ## See Also
///
/// - ``GivenStep``
/// - ``AsyncWhenStep``
public struct WhenStep<Context: Sendable, Result: Sendable>: Sendable {
    /// The description from the given step.
    public let givenDescription: String

    /// The description of the action being performed.
    public let description: String

    let setup: @Sendable () throws -> Context
    let action: @Sendable (Context) throws -> Result

    /// Creates a new when step.
    ///
    /// - Parameters:
    ///   - givenDescription: The description from the given step.
    ///   - description: The description of this action.
    ///   - setup: The setup closure from the given step.
    ///   - action: The action closure to perform.
    public init(
        givenDescription: String,
        description: String,
        setup: @escaping @Sendable () throws -> Context,
        action: @escaping @Sendable (Context) throws -> Result
    ) {
        self.givenDescription = givenDescription
        self.description = description
        self.setup = setup
        self.action = action
    }

    /// Executes the chain with an assertion.
    ///
    /// This method:
    /// 1. Runs the setup closure from `given()`
    /// 2. Passes the context to the action closure from `when()`
    /// 3. Passes the result and step context to your assertion closure
    ///
    /// - Parameters:
    ///   - description: A description of the expected outcome.
    ///   - assertion: A closure that verifies the result.
    /// - Throws: Any error thrown by the setup, action, or assertion closures.
    public func then(
        _ description: String,
        assertion: @escaping @Sendable (Result, StepContext) throws -> Void
    ) throws {
        let context = try setup()
        let result = try action(context)
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
            let scenarioName = Test.current?.displayName ?? "Scenario"
            print("\n\(symbol) \(scenarioName)")
            print("  given \(stepContext.givenDescription) when \(stepContext.whenDescription) then \(stepContext.thenDescription)")
            if let error = errorMessage {
                print("  ❌ Error: \(error)")
            }
        }
    }
}

// MARK: - Async Given Step

/// Async variant of ``GivenStep`` for asynchronous setup.
///
/// Use `AsyncGivenStep` when your setup closure needs to perform async
/// operations like network calls or database queries.
///
/// ## Example
///
/// ```swift
/// try await given("user data is loaded") {
///     await UserService.fetchCurrentUser()
/// }
/// .when("user updates profile") { user in
///     await user.updateName("New Name")
/// }
/// .then("name is updated") { result, _ in
///     #expect(result.success)
/// }
/// ```
///
/// ## See Also
///
/// - ``given(_:setup:)-68bc2``
/// - ``GivenStep``
/// - ``AsyncWhenStep``
public struct AsyncGivenStep<Context: Sendable>: Sendable {
    /// The description of the initial state being set up.
    public let description: String

    let setup: @Sendable () async throws -> Context

    /// Creates a new async given step.
    ///
    /// - Parameters:
    ///   - description: A description of the initial state.
    ///   - setup: An async closure that creates and returns the test context.
    public init(_ description: String, setup: @escaping @Sendable () async throws -> Context) {
        self.description = description
        self.setup = setup
    }

    /// Chains to an async when step.
    ///
    /// - Parameters:
    ///   - description: A description of the action being performed.
    ///   - action: An async closure that performs the action.
    /// - Returns: An ``AsyncWhenStep`` ready to be terminated with `.then()`.
    public func when<Result: Sendable>(
        _ description: String,
        action: @escaping @Sendable (Context) async throws -> Result
    ) -> AsyncWhenStep<Context, Result> {
        AsyncWhenStep(
            givenDescription: self.description,
            description: description,
            setup: setup,
            action: action
        )
    }
}

// MARK: - Async When Step

/// Async variant of ``WhenStep`` for asynchronous actions.
///
/// An `AsyncWhenStep` is created by calling ``AsyncGivenStep/when(_:action:)``
/// on an ``AsyncGivenStep``.
///
/// ## See Also
///
/// - ``AsyncGivenStep``
/// - ``WhenStep``
public struct AsyncWhenStep<Context: Sendable, Result: Sendable>: Sendable {
    /// The description from the given step.
    public let givenDescription: String

    /// The description of the action being performed.
    public let description: String

    let setup: @Sendable () async throws -> Context
    let action: @Sendable (Context) async throws -> Result

    /// Creates a new async when step.
    ///
    /// - Parameters:
    ///   - givenDescription: The description from the given step.
    ///   - description: The description of this action.
    ///   - setup: The async setup closure from the given step.
    ///   - action: The async action closure to perform.
    public init(
        givenDescription: String,
        description: String,
        setup: @escaping @Sendable () async throws -> Context,
        action: @escaping @Sendable (Context) async throws -> Result
    ) {
        self.givenDescription = givenDescription
        self.description = description
        self.setup = setup
        self.action = action
    }

    /// Executes the async chain with an assertion.
    ///
    /// - Parameters:
    ///   - description: A description of the expected outcome.
    ///   - assertion: An async closure that verifies the result.
    /// - Throws: Any error thrown by the setup, action, or assertion closures.
    public func then(
        _ description: String,
        assertion: @escaping @Sendable (Result, StepContext) async throws -> Void
    ) async throws {
        let context = try await setup()
        let result = try await action(context)
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
            let scenarioName = Test.current?.displayName ?? "Scenario"
            print("\n\(symbol) \(scenarioName)")
            print("  given \(stepContext.givenDescription) when \(stepContext.whenDescription) then \(stepContext.thenDescription)")
            if let error = errorMessage {
                print("  ❌ Error: \(error)")
            }
        }
    }
}

// MARK: - Free Functions

/// Creates a new BDD test chain with the given setup.
///
/// This is the entry point for writing Given/When/Then tests. The setup
/// closure creates the initial context that will be passed to the action.
///
/// ## Example
///
/// ```swift
/// try given("a registered user") {
///     User(email: "test@example.com")
/// }
/// .when("they login") { user in
///     AuthService().login(user)
/// }
/// .then("access is granted") { result, _ in
///     #expect(result == .success)
/// }
/// ```
///
/// - Parameters:
///   - description: A description of the initial state.
///   - setup: A closure that creates and returns the test context.
/// - Returns: A ``GivenStep`` ready to chain with `.when()`.
public func given<Context: Sendable>(
    _ description: String,
    setup: @escaping @Sendable () throws -> Context
) -> GivenStep<Context> {
    // Register scenario start for RSpec reporting (only when enabled)
    if RSpecReporter.isEnabled,
       let scenarioName = Test.current?.displayName {
        ensureRSpecReporterBootstrapped()
        clearTestFailures()  // Clear any previous failure state
        let storyName = extractUserStoryDescription()
        RSpecReporter.shared.registerScenarioStart(scenarioName, story: storyName)
    }

    return GivenStep(description, setup: setup)
}

/// Creates a new async BDD test chain with the given setup.
///
/// Use this overload when your setup needs to perform async operations.
///
/// ## Example
///
/// ```swift
/// try await given("user data from API") {
///     await API.fetchUser(id: 123)
/// }
/// .when("updating profile") { user in
///     await user.save()
/// }
/// .then("changes persist") { result, _ in
///     #expect(result.saved)
/// }
/// ```
///
/// - Parameters:
///   - description: A description of the initial state.
///   - setup: An async closure that creates and returns the test context.
/// - Returns: An ``AsyncGivenStep`` ready to chain with `.when()`.
public func given<Context: Sendable>(
    _ description: String,
    setup: @escaping @Sendable () async throws -> Context
) -> AsyncGivenStep<Context> {
    // Register scenario start for RSpec reporting (only when enabled)
    if RSpecReporter.isEnabled,
       let scenarioName = Test.current?.displayName {
        ensureRSpecReporterBootstrapped()
        clearTestFailures()  // Clear any previous failure state
        let storyName = extractUserStoryDescription()
        RSpecReporter.shared.registerScenarioStart(scenarioName, story: storyName)
    }

    return AsyncGivenStep(description, setup: setup)
}
