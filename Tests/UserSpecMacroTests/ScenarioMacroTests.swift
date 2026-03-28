import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(UserSpecMacros)
import UserSpecMacros

final class ScenarioMacroTests: XCTestCase {

    let testMacros: [String: Macro.Type] = [
        "Scenario": ScenarioMacro.self,
    ]

    func testScenarioDoesNotModifyFunction() throws {
        // @Scenario is primarily for documentation and test runner display
        // It doesn't modify the function itself
        assertMacroExpansion(
            """
            @Scenario("User can login with valid credentials")
            func testValidLogin() {
            }
            """,
            expandedSource: """
            func testValidLogin() {
            }
            """,
            macros: testMacros
        )
    }

    func testScenarioWithParameters() throws {
        assertMacroExpansion(
            """
            @Scenario("Economy user cannot select business seat")
            func economyCannotSelectBusiness() {
                let user = User(ticketClass: .economy)
            }
            """,
            expandedSource: """
            func economyCannotSelectBusiness() {
                let user = User(ticketClass: .economy)
            }
            """,
            macros: testMacros
        )
    }

    func testScenarioWithAsyncFunction() throws {
        assertMacroExpansion(
            """
            @Scenario("Booking confirms against live API")
            func bookingConfirms() async throws {
            }
            """,
            expandedSource: """
            func bookingConfirms() async throws {
            }
            """,
            macros: testMacros
        )
    }
}
#endif
