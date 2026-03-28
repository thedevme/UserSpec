// MARK: - Shared Examples
//
// Reusable test behaviors that can be included across multiple specs.

/// A container for shared example definitions.
///
/// Register shared examples that can be reused across specs:
///
/// ```swift
/// // Define shared behavior
/// SharedExamples.define("a valid response") { (context: ResponseContext) in
///     try given("the response") {
///         context.response
///     }
///     .when("checking validity") { response in
///         response.isValid
///     }
///     .then("it is valid") { isValid, _ in
///         #expect(isValid == true)
///     }
/// }
///
/// // Use in specs
/// @Test func testAPIResponse() throws {
///     let response = api.fetch()
///     try SharedExamples.run("a valid response", with: ResponseContext(response: response))
/// }
/// ```
public enum SharedExamples {
    /// Storage for registered shared examples.
    private nonisolated(unsafe) static var registry: [String: Any] = [:]

    /// Defines a shared example with a name and behavior closure.
    ///
    /// - Parameters:
    ///   - name: A unique name for the shared example.
    ///   - behavior: A closure that executes the shared behavior.
    public static func define<Context>(
        _ name: String,
        behavior: @escaping (Context) throws -> Void
    ) {
        registry[name] = behavior
    }

    /// Defines an async shared example.
    ///
    /// - Parameters:
    ///   - name: A unique name for the shared example.
    ///   - behavior: An async closure that executes the shared behavior.
    public static func defineAsync<Context>(
        _ name: String,
        behavior: @escaping (Context) async throws -> Void
    ) {
        registry[name] = behavior
    }

    /// Runs a shared example with the provided context.
    ///
    /// - Parameters:
    ///   - name: The name of the shared example to run.
    ///   - context: The context to pass to the shared behavior.
    /// - Throws: If the shared example is not found or throws an error.
    public static func run<Context>(_ name: String, with context: Context) throws {
        guard let behavior = registry[name] as? (Context) throws -> Void else {
            throw SharedExampleError.notFound(name)
        }
        try behavior(context)
    }

    /// Runs an async shared example with the provided context.
    ///
    /// - Parameters:
    ///   - name: The name of the shared example to run.
    ///   - context: The context to pass to the shared behavior.
    /// - Throws: If the shared example is not found or throws an error.
    public static func runAsync<Context>(_ name: String, with context: Context) async throws {
        guard let behavior = registry[name] as? (Context) async throws -> Void else {
            throw SharedExampleError.notFound(name)
        }
        try await behavior(context)
    }

    /// Clears all registered shared examples.
    ///
    /// Useful for test cleanup between test runs.
    public static func reset() {
        registry.removeAll()
    }

    /// Returns all registered shared example names.
    public static var registeredNames: [String] {
        Array(registry.keys).sorted()
    }
}

/// Errors that can occur when working with shared examples.
public enum SharedExampleError: Error, CustomStringConvertible {
    case notFound(String)

    public var description: String {
        switch self {
        case .notFound(let name):
            return "Shared example '\(name)' not found. Registered: \(SharedExamples.registeredNames.joined(separator: ", "))"
        }
    }
}

// MARK: - Behavior Protocol

/// A protocol for defining reusable test behaviors.
///
/// Implement this protocol to create self-contained, reusable test behaviors:
///
/// ```swift
/// struct ValidResponseBehavior: SharedBehavior {
///     let response: Response
///
///     func execute() throws {
///         try given("the response") {
///             response
///         }
///         .when("checking status code") { response in
///             response.statusCode
///         }
///         .then("status is 200") { code, _ in
///             #expect(code == 200)
///         }
///     }
/// }
///
/// // Use in tests:
/// @Test func testResponse() throws {
///     try ValidResponseBehavior(response: myResponse).execute()
/// }
/// ```
public protocol SharedBehavior {
    /// Executes the shared behavior.
    func execute() throws
}

/// Async variant of SharedBehavior.
public protocol AsyncSharedBehavior {
    /// Executes the shared behavior asynchronously.
    func execute() async throws
}

// MARK: - It Behaves Like

/// Convenience function for running shared examples inline.
///
/// ## Example
///
/// ```swift
/// @Test func testAdminUser() throws {
///     let user = User.fixture("admin")
///     try itBehavesLike("an authorized user", context: user)
/// }
/// ```
///
/// - Parameters:
///   - name: The name of the shared example.
///   - context: The context to pass to the shared behavior.
public func itBehavesLike<Context>(_ name: String, context: Context) throws {
    try SharedExamples.run(name, with: context)
}

/// Async convenience function for running shared examples.
public func itBehavesLikeAsync<Context>(_ name: String, context: Context) async throws {
    try await SharedExamples.runAsync(name, with: context)
}
