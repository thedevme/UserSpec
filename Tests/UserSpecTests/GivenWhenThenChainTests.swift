import Testing
@testable import UserSpec

@Suite("Given-When-Then Chain Tests")
struct GivenWhenThenChainTests {

    @Test("full chain executes in order")
    func fullChainExecutesInOrder() throws {
        // Track execution order via accumulated string
        try given("setup phase") {
            "given"
        }
        .when("action phase") { order in
            order + ",when"
        }
        .then("assertion phase") { order, _ in
            #expect(order == "given,when")
        }
    }

    @Test("chain passes data through steps")
    func chainPassesDataThroughSteps() throws {
        struct User: Sendable {
            let id: Int
            let name: String
        }

        struct LoginResult: Sendable {
            let user: User
            let token: String
        }

        try given("a registered user") {
            User(id: 1, name: "Alice")
        }
        .when("user logs in") { user in
            LoginResult(user: user, token: "token-\(user.id)")
        }
        .then("login succeeds") { result, _ in
            #expect(result.user.name == "Alice")
            #expect(result.token == "token-1")
        }
    }

    @Test("chain works with complex types")
    func chainWithComplexTypes() throws {
        enum Status: Sendable {
            case pending
            case confirmed
            case cancelled
        }

        struct Booking: Sendable {
            let id: String
            let status: Status
        }

        try given("a pending booking") {
            Booking(id: "B001", status: .pending)
        }
        .when("booking is confirmed") { (booking: Booking) -> Booking in
            Booking(id: booking.id, status: .confirmed)
        }
        .then("booking status is confirmed") { (booking: Booking, _: StepContext) in
            #expect(booking.status == Status.confirmed)
        }
    }

    @Test("multiple chains are independent")
    func multipleChainsAreIndependent() throws {
        // First chain
        try given("first chain") {
            100
        }
        .when("we process") { value in
            value * 2
        }
        .then("result is 200") { result, _ in
            #expect(result == 200)
        }

        // Second chain - completely independent
        try given("second chain") {
            50
        }
        .when("we process differently") { value in
            value + 10
        }
        .then("result is 60") { result, _ in
            #expect(result == 60)
        }
    }

    @Test("chain with throwing setup propagates error")
    func chainWithThrowingSetup() throws {
        struct SetupError: Error, Equatable {}

        #expect(throws: SetupError.self) {
            try given("failing setup") { () throws -> String in
                throw SetupError()
            }
            .when("action") { context in
                context
            }
            .then("assertion") { _, _ in }
        }
    }

    @Test("chain with throwing action propagates error")
    func chainWithThrowingAction() throws {
        struct ActionError: Error, Equatable {}

        #expect(throws: ActionError.self) {
            try given("setup") {
                "context"
            }
            .when("failing action") { (_: String) throws -> String in
                throw ActionError()
            }
            .then("assertion") { _, _ in }
        }
    }
}
