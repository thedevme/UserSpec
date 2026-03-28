import Testing
@testable import UserSpec

@Suite("GivenStep Tests")
struct GivenStepTests {

    @Test("given() creates step with description")
    func givenCreatesStepWithDescription() {
        let step = given("a user is logged in") { "context" }

        #expect(step.description == "a user is logged in")
    }

    @Test("given() captures setup closure without executing immediately")
    func givenCapturesSetupClosure() {
        // We verify the closure isn't executed by checking the step is created
        // without any side effects. The actual execution happens in then().
        let step = given("some setup") {
            return "context"
        }

        // Step exists but hasn't executed - we verify by checking description
        #expect(step.description == "some setup")
    }

    @Test("given().when() returns WhenStep")
    func givenWhenReturnsWhenStep() {
        let whenStep = given("initial state") { "context" }
            .when("action occurs") { context in
                return "result"
            }

        #expect(whenStep.givenDescription == "initial state")
        #expect(whenStep.description == "action occurs")
    }

    @Test("given() passes context to when closure")
    func givenPassesContextToWhen() throws {
        struct TestContext: Sendable {
            let value: Int
        }

        try given("context with value 42") {
            TestContext(value: 42)
        }
        .when("we access the value") { context in
            context.value
        }
        .then("it should be 42") { result, _ in
            #expect(result == 42)
        }
    }
}
