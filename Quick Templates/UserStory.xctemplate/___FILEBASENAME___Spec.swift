import Testing
import UserSpec

@UserStory("___VARIABLE_userStory___")
struct ___FILEBASENAMEASIDENTIFIER___Spec {

    @Test
    @Scenario("First scenario description")
    func firstScenario() throws {
        try given("initial state") {
            // Return your test context here
            <#Context#>()
        }
        .when("action is performed") { context in
            // Perform action and return result
            <#Result#>
        }
        .then("expected outcome") { result, stepContext in
            // Assert expectations
            #expect(<#condition#>)
        }
    }
}
