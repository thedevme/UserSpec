import Testing
@testable import UserSpec

// MARK: - Test Types

struct TestUser: Buildable, Equatable, Sendable {
    var name: String
    var age: Int
    var email: String

    static var defaultValue: TestUser {
        TestUser(name: "Default", age: 0, email: "default@test.com")
    }
}

struct TestProduct: Buildable, FixtureProviding, Equatable, Sendable {
    var name: String
    var price: Double

    static var defaultValue: TestProduct {
        TestProduct(name: "Default Product", price: 0)
    }

    static var fixtures: [String: TestProduct] {
        [
            "cheap": TestProduct(name: "Cheap Item", price: 9.99),
            "expensive": TestProduct(name: "Expensive Item", price: 999.99),
        ]
    }
}

// MARK: - Builder Tests

@Suite("Builder Tests")
struct BuilderTests {

    @Test("build() with closure modifies default")
    func buildWithClosure() {
        let user = TestUser.build { $0.name = "Alice" }

        #expect(user.name == "Alice")
        #expect(user.age == 0) // default
        #expect(user.email == "default@test.com") // default
    }

    @Test("build() without closure returns default")
    func buildWithoutClosure() {
        let user = TestUser.build()

        #expect(user == TestUser.defaultValue)
    }

    @Test("build() can modify multiple properties")
    func buildMultipleProperties() {
        let user = TestUser.build {
            $0.name = "Bob"
            $0.age = 30
            $0.email = "bob@test.com"
        }

        #expect(user.name == "Bob")
        #expect(user.age == 30)
        #expect(user.email == "bob@test.com")
    }

    @Test("builder() with chaining works")
    func builderChaining() {
        let user = TestUser.builder()
            .with(\.name, "Charlie")
            .with(\.age, 25)
            .build()

        #expect(user.name == "Charlie")
        #expect(user.age == 25)
    }

    @Test("builder configured() applies closure")
    func builderConfigured() {
        let user = TestUser.builder()
            .configured { $0.name = "Diana"; $0.age = 40 }
            .build()

        #expect(user.name == "Diana")
        #expect(user.age == 40)
    }

    @Test("builder is immutable - each with() returns new builder")
    func builderImmutability() {
        let builder1 = TestUser.builder().with(\.name, "First")
        let builder2 = builder1.with(\.name, "Second")

        #expect(builder1.build().name == "First")
        #expect(builder2.build().name == "Second")
    }
}

// MARK: - Fixture Tests

@Suite("Fixture Tests")
struct FixtureTests {

    @Test("fixture() returns named fixture")
    func fixtureReturnsNamed() {
        let cheap = TestProduct.fixture("cheap")
        let expensive = TestProduct.fixture("expensive")

        #expect(cheap.price == 9.99)
        #expect(expensive.price == 999.99)
    }

    @Test("fixture(named:) returns nil for unknown")
    func fixtureNamedReturnsNil() {
        let unknown = TestProduct.fixture(named: "unknown")

        #expect(unknown == nil)
    }

    @Test("fixture(named:) returns fixture for known")
    func fixtureNamedReturnsKnown() {
        let cheap = TestProduct.fixture(named: "cheap")

        #expect(cheap != nil)
        #expect(cheap?.name == "Cheap Item")
    }
}

// MARK: - Array Builder Tests

@Suite("Array Builder Tests")
struct ArrayBuilderTests {

    @Test("build(count:) creates array of defaults")
    func buildCountCreatesDefaults() {
        let users = [TestUser].build(count: 3)

        #expect(users.count == 3)
        #expect(users.allSatisfy { $0 == TestUser.defaultValue })
    }

    @Test("build(count:configure:) customizes each element")
    func buildCountWithConfigure() {
        let users = [TestUser].build(count: 3) { index, user in
            user.name = "User \(index)"
            user.age = index * 10
        }

        #expect(users.count == 3)
        #expect(users[0].name == "User 0")
        #expect(users[1].name == "User 1")
        #expect(users[2].name == "User 2")
        #expect(users[0].age == 0)
        #expect(users[1].age == 10)
        #expect(users[2].age == 20)
    }

    @Test("build(count: 0) returns empty array")
    func buildCountZero() {
        let users = [TestUser].build(count: 0)

        #expect(users.isEmpty)
    }
}
