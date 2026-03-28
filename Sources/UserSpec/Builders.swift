// MARK: - Test Data Builders
//
// Fluent API for creating test fixtures with sensible defaults.

/// A protocol for types that can be built using a fluent builder pattern.
///
/// Conform your domain types to `Buildable` to enable fluent test data creation:
///
/// ```swift
/// struct User: Buildable {
///     var name: String
///     var email: String
///     var age: Int
///
///     static var defaultValue: User {
///         User(name: "Test User", email: "test@example.com", age: 25)
///     }
/// }
///
/// // In tests:
/// let user = User.build { $0.name = "Alice" }
/// ```
public protocol Buildable {
    /// The default instance used as a starting point for building.
    static var defaultValue: Self { get }
}

extension Buildable {
    /// Creates an instance using the default value, optionally modified by a closure.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let user = User.build { $0.name = "Alice" }
    /// let defaultUser = User.build()
    /// ```
    ///
    /// - Parameter configure: A closure to modify the default value.
    /// - Returns: The configured instance.
    public static func build(_ configure: (inout Self) -> Void = { _ in }) -> Self {
        var instance = defaultValue
        configure(&instance)
        return instance
    }
}

/// A fluent builder for creating test instances with chained modifications.
///
/// Use `Builder` when you need more control or want method chaining:
///
/// ```swift
/// let user = Builder<User>()
///     .with(\.name, "Alice")
///     .with(\.email, "alice@example.com")
///     .build()
/// ```
public struct Builder<T: Buildable> {
    private var instance: T

    /// Creates a builder starting with the type's default value.
    public init() {
        self.instance = T.defaultValue
    }

    /// Creates a builder starting with a specific instance.
    ///
    /// - Parameter instance: The starting instance to modify.
    public init(from instance: T) {
        self.instance = instance
    }

    /// Sets a property using a key path.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the property.
    ///   - value: The value to set.
    /// - Returns: A new builder with the modification applied.
    public func with<V>(_ keyPath: WritableKeyPath<T, V>, _ value: V) -> Builder<T> {
        var copy = self
        copy.instance[keyPath: keyPath] = value
        return copy
    }

    /// Applies a custom modification closure.
    ///
    /// - Parameter configure: A closure that modifies the instance.
    /// - Returns: A new builder with the modification applied.
    public func configured(_ configure: (inout T) -> Void) -> Builder<T> {
        var copy = self
        configure(&copy.instance)
        return copy
    }

    /// Builds and returns the configured instance.
    ///
    /// - Returns: The fully configured instance.
    public func build() -> T {
        instance
    }
}

/// Convenience extension for creating builders.
extension Buildable {
    /// Returns a new builder for this type.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let user = User.builder()
    ///     .with(\.name, "Alice")
    ///     .with(\.age, 30)
    ///     .build()
    /// ```
    public static func builder() -> Builder<Self> {
        Builder()
    }
}

// MARK: - Fixture Support

/// A protocol for types that provide named fixtures.
///
/// Implement this to provide pre-defined test scenarios:
///
/// ```swift
/// extension User: FixtureProviding {
///     static var fixtures: [String: User] {
///         [
///             "admin": User(name: "Admin", email: "admin@example.com", role: .admin),
///             "guest": User(name: "Guest", email: "guest@example.com", role: .guest)
///         ]
///     }
/// }
///
/// // In tests:
/// let admin = User.fixture("admin")
/// ```
public protocol FixtureProviding {
    /// A dictionary of named fixtures.
    static var fixtures: [String: Self] { get }
}

extension FixtureProviding {
    /// Returns a named fixture.
    ///
    /// - Parameter name: The fixture name.
    /// - Returns: The fixture, or crashes if not found.
    public static func fixture(_ name: String) -> Self {
        guard let fixture = fixtures[name] else {
            fatalError("Unknown fixture: '\(name)'. Available: \(fixtures.keys.sorted().joined(separator: ", "))")
        }
        return fixture
    }

    /// Returns a named fixture, or nil if not found.
    ///
    /// - Parameter name: The fixture name.
    /// - Returns: The fixture, or nil.
    public static func fixture(named name: String) -> Self? {
        fixtures[name]
    }
}

// MARK: - Array Builders

extension Array where Element: Buildable {
    /// Creates an array of built instances.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let users = [User].build(count: 3) { index, user in
    ///     user.name = "User \(index)"
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - count: The number of instances to create.
    ///   - configure: A closure to configure each instance with its index.
    /// - Returns: An array of configured instances.
    public static func build(
        count: Int,
        configure: (Int, inout Element) -> Void = { _, _ in }
    ) -> [Element] {
        (0..<count).map { index in
            var instance = Element.defaultValue
            configure(index, &instance)
            return instance
        }
    }
}
