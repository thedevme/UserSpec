# RSpec-Style Documentation Output

UserSpec automatically prints your test scenarios in RSpec documentation format, making it easy to see which user stories and scenarios passed or failed.

## Output Format

```
As a traveler, I want to select my seat so I can sit comfortably
  ✓ Economy user can select an economy seat
  ✓ Economy user cannot select a business seat
  ✗ Business user can select a business seat

3 scenarios, 1 failure
```

## Setup

### For Command-Line Tests (swift test)

RSpec output works automatically when running `swift test` from the command line. No setup required.

```bash
swift test
```

### For Xcode / iOS Simulator Tests

When running tests in Xcode or targeting iOS Simulator, you need to apply the `.rspecReporting` trait to your test suite:

```swift
import Testing
import UserSpec

@Suite(.rspecReporting)
struct AllTests {
    @UserStory("As a user, I want to...")
    struct FeatureTests {
        @Test func scenario1() throws { ... }
        @Test func scenario2() throws { ... }
    }
}
```

**Requirements:**
- macOS 15.0+ / iOS 18.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 2.0+
- Swift 6.1+ (for Test Scoping Traits)

**Why is this needed?** Xcode's test runner doesn't call process exit handlers (`atexit`) for iOS Simulator tests, so the trait ensures the report prints after all tests complete.

## Features

- ✓ **Automatic Story Grouping** - Scenarios are grouped under their `@UserStory` description
- ✓ **Pass/Fail Indicators** - Green ✓ for passing, Red ✗ for failing scenarios
- ✓ **Incomplete Detection** - Scenarios that throw before `.then()` are marked as incomplete
- ✓ **Color Output** - Automatic color when output is a TTY
- ✓ **Summary** - Shows total scenario count and failures

## Using expectRSpec() for Accurate Reporting

Standard `#expect` assertions cannot be detected by the RSpec reporter due to Swift Testing API limitations. For accurate pass/fail reporting, use `expectRSpec()` instead:

```swift
.then("seat is confirmed") { result, context in
    try expectRSpec(result == .confirmed)
}
```

`expectRSpec()` throws when the condition fails, allowing the reporter to detect and report failures correctly.

## Example

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
            SeatMap().select(seat: "22B", in: .economy, for: user)
        }
        .then("seat is confirmed") { result, context in
            try expectRSpec(result == .confirmed)
        }
    }
}
```

Running this will output:

```
As a traveler, I want to select my seat so I can sit comfortably
  ✓ Economy user can select an economy seat

1 scenario, 0 failures
```
