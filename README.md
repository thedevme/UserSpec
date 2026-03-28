# UserSpec

A BDD testing framework for Swift, built natively on Swift Testing.

## What is UserSpec?

UserSpec brings the London School (outside-in) testing approach to iOS development. Write user stories, break them into Given/When/Then scenarios, and let them drive your implementation.

## Requirements

- Swift 6.0+
- Xcode 16+
- iOS 17+ / macOS 14+ / watchOS 10+ / tvOS 17+ / visionOS 1+

## Installation (Swift Package Manager)

Add UserSpec to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/thedevme/UserSpec.git", from: "0.1.0")
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
| `@UIScenario("...")` | UI testing variant (v0.2.0) |

### Functions

| Function | Description |
|----------|-------------|
| `given(_:setup:)` | Entry point — sets up test context |
| `.when(_:action:)` | Chains to action step |
| `.then(_:assertion:)` | Executes chain with assertion |

## Roadmap

- **v0.1.0** — Core framework with Given/When/Then chains, macros, async support
- **v0.2.0** — UI testing with `@UIScenario`, `givenApp`, `whenTap`, `thenSee`
- **v1.0.0** — Stable release with full documentation

## The Book

UserSpec is the companion framework to **The Swift Testing Handbook** by Craig Clayton. Learn Design-Driven Development from the ground up.

## License

Apache 2.0
