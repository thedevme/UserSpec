// MARK: - Step Context

/// Captures descriptions from all steps in a chain for failure reporting
public struct StepContext: Sendable {
    public let givenDescription: String
    public let whenDescription: String
    public let thenDescription: String

    public init(given: String, when: String, then: String) {
        self.givenDescription = given
        self.whenDescription = when
        self.thenDescription = then
    }

    /// Formats a failure message showing the full chain context
    public func formatFailureMessage() -> String {
        """
        Given: \(givenDescription)
        When: \(whenDescription)
        Then: \(thenDescription)
        """
    }
}

// MARK: - Given Step

/// Entry point for BDD chains - captures setup context
public struct GivenStep<Context: Sendable>: Sendable {
    public let description: String
    let setup: @Sendable () throws -> Context

    public init(_ description: String, setup: @escaping @Sendable () throws -> Context) {
        self.description = description
        self.setup = setup
    }

    /// Chain to a when step with an action
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

/// Intermediate step capturing the action
public struct WhenStep<Context: Sendable, Result: Sendable>: Sendable {
    public let givenDescription: String
    public let description: String
    let setup: @Sendable () throws -> Context
    let action: @Sendable (Context) throws -> Result

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

    /// Execute the chain with an assertion
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
        try assertion(result, stepContext)
    }
}

// MARK: - Async Given Step

/// Async variant of GivenStep
public struct AsyncGivenStep<Context: Sendable>: Sendable {
    public let description: String
    let setup: @Sendable () async throws -> Context

    public init(_ description: String, setup: @escaping @Sendable () async throws -> Context) {
        self.description = description
        self.setup = setup
    }

    /// Chain to an async when step
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

/// Async variant of WhenStep
public struct AsyncWhenStep<Context: Sendable, Result: Sendable>: Sendable {
    public let givenDescription: String
    public let description: String
    let setup: @Sendable () async throws -> Context
    let action: @Sendable (Context) async throws -> Result

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

    /// Execute the async chain with an assertion
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
        try await assertion(result, stepContext)
    }
}

// MARK: - Free Functions

/// Entry point for BDD chains
public func given<Context: Sendable>(
    _ description: String,
    setup: @escaping @Sendable () throws -> Context
) -> GivenStep<Context> {
    GivenStep(description, setup: setup)
}

/// Async entry point for BDD chains
public func given<Context: Sendable>(
    _ description: String,
    setup: @escaping @Sendable () async throws -> Context
) -> AsyncGivenStep<Context> {
    AsyncGivenStep(description, setup: setup)
}
