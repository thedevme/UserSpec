// MARK: - Macro Declarations

/// Marks a struct as a collection of scenarios for a specific user story.
///
/// The description should be a user story in plain English following the format:
/// "As a [role], I want to [action] so that [benefit]"
///
/// ## Example
///
/// ```swift
/// @UserStory("As a traveler, I want to select my seat so I can sit comfortably")
/// struct SeatSelectionSpec {
///     @Test
///     @Scenario("Economy user cannot select business class seat")
///     func economyCannotSelectBusiness() {
///         // Given/When/Then chain
///     }
/// }
/// ```
///
/// - Parameter description: The user story in plain English
@attached(member, names: named(userStoryDescription))
@attached(peer)
public macro UserStory(_ description: String) = #externalMacro(module: "UserSpecMacros", type: "UserStoryMacro")

/// Marks a function as a test scenario within a `@UserStory`.
///
/// Must be combined with `@Test` from Swift Testing. The scenario description
/// appears in the test navigator and in failure output.
///
/// ## Example
///
/// ```swift
/// @Test
/// @Scenario("Economy user cannot select business class seat")
/// func economyCannotSelectBusiness() {
///     given("user has an economy ticket") {
///         User(ticketClass: .economy)
///     }
///     .when("they tap seat 1A in Business Class") { user in
///         SeatMap().select(seat: "1A", for: user)
///     }
///     .then("selection fails with class restriction") { result in
///         #expect(result == .failed(.classRestriction))
///     }
/// }
/// ```
///
/// - Parameter description: A brief description of the scenario being tested
@attached(peer)
public macro Scenario(_ description: String) = #externalMacro(module: "UserSpecMacros", type: "ScenarioMacro")

/// UI testing variant of `@Scenario`. Used with XCUITest.
///
/// Provides integration with `givenApp`, `whenTap`, and `thenSee` convenience methods.
///
/// ## Example
///
/// ```swift
/// @Test
/// @UIScenario("Economy user sees error when tapping business seat")
/// func economySeesErrorOnBusinessSeat() {
///     givenApp("user has an economy ticket") {
///         app.launchWithEconomyUser()
///     }
///     .whenTap("seat 1A in Business Class") { app in
///         app.buttons["seat-1A"].tap()
///     }
///     .thenSee("class restriction error message") { app in
///         #expect(app.staticTexts["Only economy seats available"].exists)
///     }
/// }
/// ```
///
/// - Note: Available in v0.2.0
/// - Parameter description: A brief description of the UI scenario being tested
@attached(peer)
public macro UIScenario(_ description: String) = #externalMacro(module: "UserSpecMacros", type: "UIScenarioMacro")
