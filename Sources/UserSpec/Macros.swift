// MARK: - Macro Declarations

/// Marks a struct as a collection of scenarios for a specific user story.
///
/// Use `@UserStory` to group related test scenarios that verify a single
/// user story. The description should follow the format:
/// "As a [role], I want to [action] so that [benefit]"
///
/// ## Example
///
/// ```swift
/// @UserStory("As a traveler, I want to select my seat so I can sit comfortably")
/// struct SeatSelectionSpec {
///
///     @Test
///     @Scenario("Economy user can select an economy seat")
///     func economyCanSelectEconomySeat() throws {
///         try given("user has an economy ticket") {
///             User(ticketClass: .economy)
///         }
///         .when("they tap seat 22B in Economy") { user in
///             SeatMap().select(seat: "22B", for: user)
///         }
///         .then("seat is confirmed") { result, context in
///             #expect(result == .confirmed)
///         }
///     }
/// }
/// ```
///
/// ## Behavior
///
/// The macro:
/// - Adds a static `userStoryDescription` property containing the description
/// - Description appears in Xcode's test navigator
/// - Description appears in CI output on failure
///
/// Multiple `@UserStory` structs can exist in a single file.
///
/// - Parameter description: The user story in plain English.
@attached(member, names: named(userStoryDescription), named(_storyRegistration), named(init()))
@attached(peer)
public macro UserStory(_ description: String) = #externalMacro(module: "UserSpecMacros", type: "UserStoryMacro")

/// Marks a function as a test scenario within a `@UserStory`.
///
/// Use `@Scenario` with `@Test` from Swift Testing to define individual
/// test cases. The scenario description appears in the test navigator
/// and in failure output.
///
/// ## Example
///
/// ```swift
/// @Test
/// @Scenario("Economy user cannot select business class seat")
/// func economyCannotSelectBusiness() throws {
///     try given("user has an economy ticket") {
///         User(ticketClass: .economy)
///     }
///     .when("they tap seat 1A in Business Class") { user in
///         SeatMap().select(seat: "1A", for: user)
///     }
///     .then("selection fails with class restriction") { result, context in
///         #expect(result == .failed(.classRestriction))
///     }
/// }
/// ```
///
/// ## Behavior
///
/// - Works with `@Test` from Swift Testing
/// - Scenario description printed in failure output
/// - Each scenario is independent — no shared state between scenarios
///
/// - Parameter description: A brief description of the scenario being tested.
@attached(peer)
public macro Scenario(_ description: String) = #externalMacro(module: "UserSpecMacros", type: "ScenarioMacro")

/// Marks a function as a UI test scenario.
///
/// Use `@UIScenario` with `@Test` for XCUITest-based UI tests.
/// Combine with ``givenApp(_:setup:)-1lpqv``, `whenTap`, and `thenSee`.
///
/// ## Example
///
/// ```swift
/// @Test
/// @UIScenario("Economy user sees error when tapping business seat")
/// func economySeesErrorOnBusinessSeat() throws {
///     let app = XCUIApplication()
///
///     try givenApp("user has an economy ticket") {
///         app.launchArguments = ["--economy-user"]
///         return app.launched()
///     }
///     .whenTap("seat 1A in Business Class") { app in
///         app.buttons["seat-1A"].tap()
///         return app
///     }
///     .thenSee("class restriction error message") { app, context in
///         #expect(app.staticTexts["Only economy seats available"].exists)
///     }
/// }
/// ```
///
/// - Note: `@UIScenario` requires XCUIApplication. Use in UI test targets only.
/// - Parameter description: A brief description of the UI scenario being tested.
///
/// ## See Also
///
/// - <doc:UITesting>
/// - ``givenApp(_:setup:)-1lpqv``
/// - ``UIGivenStep``
@attached(peer)
public macro UIScenario(_ description: String) = #externalMacro(module: "UserSpecMacros", type: "UIScenarioMacro")
