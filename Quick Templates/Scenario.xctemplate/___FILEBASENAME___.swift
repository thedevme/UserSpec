@Test
@Scenario("___VARIABLE_scenario___")
func ___VARIABLE_productName:identifier___() throws {
    try given("<#initial state#>") {
        <#Context#>()
    }
    .when("<#action#>") { context in
        <#Result#>
    }
    .then("<#expected outcome#>") { result, stepContext in
        #expect(<#condition#>)
    }
}
