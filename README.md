# UserSpec

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

A BDD testing framework for Swift, built natively on Swift Testing.

## What is UserSpec?

UserSpec brings the London School (outside-in) testing approach to iOS development. Write user stories, break them into Given/When/Then scenarios, and let them drive your implementation.

## Requirements

- Swift 6.0+
- Xcode 16+
- iOS 17+ / macOS 14+ / watchOS 10+ / tvOS 17+ / visionOS 1+

## Installation

Add UserSpec to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/thedevme/UserSpec.git", from: "1.0.0")
]
```

Add it to your test target:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: [
        "MyApp",
        .product(name: "UserSpec", package: "UserSpec")
    ]
)
```

Or in Xcode: File → Add Package Dependencies → paste the GitHub URL → Add to test target only.

## Quick Start

```swift
import Testing
import UserSpec

@UserStory("As a traveler, I want to select my seat so I can sit comfortably")
struct SeatSelectionSpec {

    @Test
    @Scenario("Economy user can select an economy seat")
    func economyCanSelectEconomySeat() throws {
        try given("user has an economy ticket") {
            User(ticketClass: .economy)
        }
        .when("they tap seat 22B in Economy") { user in
            SeatMap().select(seat: "22B", for: user)
        }
        .then("seat is confirmed") { result, context in
            #expect(result == .confirmed)
        }
    }
}
```

## The Full Chain

```
Design → User Story → @Scenario → Given/When/Then → #expect
```

UserSpec connects your design requirements to executable tests:

1. **@UserStory** — Marks a struct as a collection of scenarios
2. **@Scenario** — Marks a function as a specific test case
3. **given()** — Sets up the test context
4. **.when()** — Performs the action being tested
5. **.then()** — Asserts the expected outcome

## Async Support

UserSpec fully supports Swift Concurrency:

```swift
@Test
@Scenario("Booking confirms against live API")
func bookingConfirms() async throws {
    try await given("available flight to JFK") {
        await FlightAPI.shared.nextAvailableFlight()
    }
    .when("user books seat 12A") { flight in
        await FlightAPI.shared.bookSeat("12A", on: flight)
    }
    .then("booking is confirmed") { booking, context in
        #expect(booking.status == .confirmed)
        #expect(booking.reference != nil)
    }
}
```

## UI Testing

UserSpec provides a dedicated API for XCUITest integration:

```swift
import XCTest
import Testing
import UserSpec

@UserStory("As a traveler, I want to select my seat")
struct SeatSelectionUISpec {

    @Test
    @UIScenario("Economy user sees error when tapping business seat")
    func economySeesErrorOnBusinessSeat() throws {
        let app = XCUIApplication()

        try givenApp("user has an economy ticket") {
            app.launchArguments = ["--economy-user"]
            return app.launched()
        }
        .whenTap("seat 1A in Business Class") { app in
            app.buttons["seat-1A"].tap()
            return app
        }
        .thenSee("class restriction error message") { app, context in
            #expect(app.staticTexts["Only economy seats available"].exists)
        }
    }
}
```

### UI Testing API

| Function | Description |
|----------|-------------|
| `givenApp(_:setup:)` | Entry point — launches and configures the app |
| `.whenTap(_:action:)` | Chains to a tap action |
| `.when(_:action:)` | Chains to any UI action |
| `.thenSee(_:assertion:)` | Executes chain with visual assertion |

### XCUIApplication Extensions

```swift
// Launch and return for chaining
app.launched()

// Launch with arguments
app.launched(with: ["--reset-state"])

// Launch with environment
app.launched(environment: ["API_URL": "https://test.api.com"])
```

## Failure Output

When a test fails, UserSpec shows the full chain context:

```
❌ Test failed: Economy user cannot select business class seat

  Given: user has an economy ticket
  When: they tap seat 1A in Business Class
  Then: selection fails with class restriction

  Expectation failed: (result → .confirmed) == .failed(.classRestriction)
```

## API Reference

### Macros

| Macro | Description |
|-------|-------------|
| `@UserStory("...")` | Marks a struct as a collection of scenarios |
| `@Scenario("...")` | Marks a function as a test scenario |
| `@UIScenario("...")` | Marks a function as a UI test scenario |

### Unit Testing Functions

| Function | Description |
|----------|-------------|
| `given(_:setup:)` | Entry point — sets up test context |
| `.when(_:action:)` | Chains to action step |
| `.then(_:assertion:)` | Executes chain with assertion |

### UI Testing Functions

| Function | Description |
|----------|-------------|
| `givenApp(_:setup:)` | Entry point — sets up app context |
| `.whenTap(_:action:)` | Chains to tap action |
| `.when(_:action:)` | Chains to any action |
| `.thenSee(_:assertion:)` | Executes chain with visual assertion |

## The Book

UserSpec is the companion framework to **The Swift Testing Handbook** by Craig Clayton. Learn Design-Driven Development from the ground up.

## License

Apache 2.0
