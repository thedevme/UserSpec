import Testing
@testable import UserSpec

@Suite("StepContext Tests")
struct StepContextTests {

    @Test("context stores all descriptions")
    func contextStoresAllDescriptions() {
        let context = StepContext(
            given: "a user is logged in",
            when: "they click logout",
            then: "they are redirected to login page"
        )

        #expect(context.givenDescription == "a user is logged in")
        #expect(context.whenDescription == "they click logout")
        #expect(context.thenDescription == "they are redirected to login page")
    }

    @Test("formatFailureMessage includes all steps")
    func formatFailureMessageIncludesAllSteps() {
        let context = StepContext(
            given: "setup description",
            when: "action description",
            then: "assertion description"
        )

        let message = context.formatFailureMessage()

        #expect(message.contains("setup description"))
        #expect(message.contains("action description"))
        #expect(message.contains("assertion description"))
    }

    @Test("formatFailureMessage matches expected format")
    func formatFailureMessageFormat() {
        let context = StepContext(
            given: "a flight with available seats",
            when: "user selects seat 12A",
            then: "seat 12A is marked as selected"
        )

        let message = context.formatFailureMessage()

        let expectedMessage = """
        Given: a flight with available seats
        When: user selects seat 12A
        Then: seat 12A is marked as selected
        """

        #expect(message == expectedMessage)
    }

    @Test("context is received in then closure")
    func contextReceivedInThenClosure() throws {
        try given("the given description") {
            "value"
        }
        .when("the when description") { value in
            value.uppercased()
        }
        .then("the then description") { _, context in
            #expect(context.givenDescription == "the given description")
            #expect(context.whenDescription == "the when description")
            #expect(context.thenDescription == "the then description")
        }
    }
}
