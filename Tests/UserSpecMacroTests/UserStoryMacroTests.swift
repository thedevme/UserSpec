import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(UserSpecMacros)
import UserSpecMacros

final class UserStoryMacroTests: XCTestCase {

    let testMacros: [String: Macro.Type] = [
        "UserStory": UserStoryMacro.self,
    ]

    func testUserStoryAddsStaticProperty() throws {
        assertMacroExpansion(
            """
            @UserStory("As a traveler, I want to select my seat")
            struct SeatSelectionSpec {
            }
            """,

            expandedSource: """
            struct SeatSelectionSpec {

                static let userStoryDescription: String = "As a traveler, I want to select my seat"

                private static let _storyRegistration: Void = {
                    UserStoryRegistry.shared.register(
                        typeName: String(describing: Self.self),
                        story: userStoryDescription
                    )
                }()

                init() {
                    _ = Self._storyRegistration
                }
            }
            """,

            macros: testMacros
        )
    }

    func testUserStoryWithLongDescription() throws {
        assertMacroExpansion(
            """
            @UserStory("As a frequent flyer, I want to upgrade my seat so that I can enjoy more legroom on long flights")
            struct SeatUpgradeSpec {
            }
            """,
            expandedSource: """
            struct SeatUpgradeSpec {

                static let userStoryDescription: String = "As a frequent flyer, I want to upgrade my seat so that I can enjoy more legroom on long flights"

                private static let _storyRegistration: Void = {
                    UserStoryRegistry.shared.register(
                        typeName: String(describing: Self.self),
                        story: userStoryDescription
                    )
                }()

                init() {
                    _ = Self._storyRegistration
                }
            }
            """,
            macros: testMacros
        )
    }

    func testUserStoryWithExistingMembers() throws {
        assertMacroExpansion(
            """
            @UserStory("As a user, I want to login")
            struct LoginSpec {
                let mockService = MockAuthService()
            }
            """,
            expandedSource: """
            struct LoginSpec {
                let mockService = MockAuthService()

                static let userStoryDescription: String = "As a user, I want to login"

                private static let _storyRegistration: Void = {
                    UserStoryRegistry.shared.register(
                        typeName: String(describing: Self.self),
                        story: userStoryDescription
                    )
                }()

                init() {
                    _ = Self._storyRegistration
                }
            }
            """,
            macros: testMacros
        )
    }
}
#endif
