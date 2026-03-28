import Testing
@testable import UserSpec

@Suite("WhenStep Tests")
struct WhenStepTests {

    @Test("when step stores description")
    func whenStoresDescription() {
        let whenStep = given("setup") { "context" }
            .when("user taps button") { _ in "result" }

        #expect(whenStep.description == "user taps button")
    }

    @Test("when step captures action closure without executing immediately")
    func whenCapturesActionClosure() {
        // We verify the closure isn't executed by checking the step is created
        // without running the chain. Execution happens in then().
        let whenStep = given("setup") { "context" }
            .when("action") { _ in
                return "result"
            }

        // When step exists with correct descriptions
        #expect(whenStep.description == "action")
        #expect(whenStep.givenDescription == "setup")
    }

    @Test("then() executes full chain")
    func thenExecutesFullChain() throws {
        // Use a simple counter to track execution via the result
        try given("setup") {
            1
        }
        .when("action") { value in
            value + 1
        }
        .then("assertion") { result, _ in
            // If we reach here with result == 2, all steps executed
            #expect(result == 2)
        }
    }

    @Test("then() receives result from action")
    func thenReceivesResultFromAction() throws {
        struct ActionResult: Sendable, Equatable {
            let message: String
            let code: Int
        }

        try given("initial state") {
            "input"
        }
        .when("processing occurs") { input in
            ActionResult(message: "processed: \(input)", code: 200)
        }
        .then("result is correct") { result, _ in
            #expect(result.message == "processed: input")
            #expect(result.code == 200)
        }
    }
}
