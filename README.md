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

## Test Data Builders

UserSpec includes a fluent builder API for test data:

```swift
struct User: Buildable {
    var name: String
    var email: String

    static var defaultValue: User {
        User(name: "Default", email: "default@test.com")
    }
}

// Quick build with closure
let user = User.build { $0.name = "Alice" }

// Fluent builder chain
let user = User.builder()
    .with(\.name, "Bob")
    .with(\.email, "bob@test.com")
    .build()

// Array building
let users = [User].build(count: 5) { index, user in
    user.name = "User \(index)"
}
```

## Shared Examples

Reuse test behaviors across specs:

```swift
// Define once
SharedExamples.define("validates required fields") { (form: FormData) in
    try given("empty form") { form }
    .when("submitted") { $0.submit() }
    .then("shows validation errors") { result, _ in
        #expect(result.errors.contains(.requiredFieldsMissing))
    }
}

// Use anywhere
@Test func signupValidates() throws {
    try itBehavesLike("validates required fields", context: SignupForm())
}
```

## Story Parser

Convert plain text user stories to Swift test code:

```swift
let text = """
As a shopper, I want to add items to cart so that I can purchase later

Scenario: Adding in-stock item
Given an empty cart
When user adds a product
Then cart contains one item
"""

// Parse to structured data
let story = StoryParser.parse(text)

// Generate Swift test stub
let swiftCode = StoryParser.generateSwift(from: story, moduleName: "MyApp")

// Export to Gherkin format
let gherkin = StoryParser.generateGherkin(from: story)
```

## Test Reports

Generate reports from test results:

```swift
// Record results during test execution
TestReporter.shared.record(TestReporter.TestResult(
    userStory: "Shopping Cart",
    scenario: "Add item",
    given: "empty cart",
    when: "add product",
    then: "cart has item",
    passed: true,
    duration: 0.15
))

// Generate reports
let html = ReportGenerator.generateHTML(from: TestReporter.shared.allResults())
let gherkin = ReportGenerator.generateGherkin(from: TestReporter.shared.allResults())
let console = ReportGenerator.generateConsole(from: TestReporter.shared.allResults())

// Write to file
try ReportGenerator.writeHTML(from: TestReporter.shared.allResults(), to: "report.html")
```

## Mocking

UserSpec includes a lightweight mocking framework:

```swift
// 1. Create a mock by conforming to Mockable
protocol PaymentService {
    func charge(amount: Decimal) -> PaymentResult
}

class MockPaymentService: PaymentService, Mockable {
    let recorder = CallRecorder()

    func charge(amount: Decimal) -> PaymentResult {
        recorder.record(#function, args: [amount])
        return recorder.stub(for: #function) ?? .success
    }
}

// 2. Use in tests
@Test
func paymentIsProcessed() throws {
    let mock = MockPaymentService()
    mock.recorder.stub(for: "charge(amount:)", return: .success)

    try given("a cart ready for checkout") {
        Cart(paymentService: mock)
    }
    .when("user completes purchase") { cart in
        cart.checkout(amount: 99.99)
    }
    .then("payment is charged") { result, context in
        #expect(mock.recorder.wasCalled("charge(amount:)"))
        #expect(result == .confirmed)
    }
}
```

### Verification

```swift
// Verify method was called
#expect(mock.recorder.wasCalled("methodName"))

// Verify call count
#expect(mock.recorder.callCount(for: "methodName") == 2)

// Verify arguments
let args = mock.recorder.lastArguments(for: "methodName")
#expect(args?.first as? Int == 42)

// Use Verify helpers
#expect(Verify.called(mock, "methodName", times: 1))
```

### Argument Matchers

```swift
// Match any value
let matcher = ArgumentMatcher.any() as AnyMatcher<Int>

// Match specific value
let matcher = ArgumentMatcher.equal(to: "expected")

// Match with predicate
let matcher = ArgumentMatcher.matching { (value: Int) in value > 10 }
```

## Performance Testing

Measure and assert performance in your tests:

```swift
@Test
@Scenario("Search completes quickly")
func searchPerformance() throws {
    try given("a large dataset") {
        Dataset.generate(size: 10_000)
    }
    .when("performing search") { dataset in
        Benchmark.measure {
            dataset.search("query")
        }
    }
    .then("completes under 100ms") { result, context in
        #expect(result.duration < 0.1)
    }
}
```

### Benchmark

```swift
// Measure single execution
let result = Benchmark.measure {
    expensiveOperation()
}
print("Took \(result.milliseconds)ms")

// Measure average over iterations
let avg = Benchmark.measureAverage(iterations: 10) {
    operation()
}

// Async measurement
let result = await Benchmark.measure {
    await asyncOperation()
}
```

### Performance Assertions

```swift
// Assert operation completes within threshold
let value = try PerformanceAssert.completes(within: 0.5) {
    slowOperation()
}

// Milliseconds convenience
try PerformanceAssert.completesInMilliseconds(100) {
    operation()
}
```

### Baselines and Regression Detection

```swift
// Set a baseline
PerformanceBaseline.shared.setBaseline("search", duration: 0.05)

// Compare against baseline
let result = PerformanceBaseline.shared.compare("search", tolerance: 0.1) {
    performSearch()
}

switch result.status {
case .withinTolerance: print("OK")
case .regression: print("Slower by \(result.deviationPercentage!)")
case .improvement: print("Faster!")
case .noBaseline: print("No baseline set")
}
```

### Memory Measurement

```swift
// Current memory usage
print("Using \(MemoryMeasurement.currentUsageMB) MB")

// Measure memory delta
let result = MemoryMeasurement.measure {
    loadLargeData()
}
print("Allocated \(result.megabytesAllocated) MB")
```

## Snapshot Testing

Capture and compare snapshots for regression testing:

```swift
struct User: Codable, SnapshotRepresentable {
    var name: String
    var email: String
}

@Test
func userSerializationSnapshot() throws {
    let user = User(name: "Alice", email: "alice@example.com")

    // Assert against stored snapshot (creates on first run)
    try assertSnapshot(user, named: "user_default")
}
```

### Recording Snapshots

```swift
// Enable record mode to create/update snapshots
SnapshotManager.shared.config = .record

// Or configure custom directory
SnapshotManager.shared.config = SnapshotConfig(
    snapshotDirectory: "__Snapshots__",
    recordMode: false,
    fileExtension: "snap"
)
```

### Inline Snapshots

For simple values, use inline snapshots:

```swift
@Test
func calculationSnapshot() throws {
    let result = calculate(input: 42)

    // Compare against inline expected value
    try inlineSnapshot("expected output").assert(result)
}
```

### JSON Snapshots

```swift
@Test
func apiResponseSnapshot() throws {
    let response = api.fetchUser()

    try JSONSnapshot.assert(response, named: "user_response")
}
```

### Text Snapshots

```swift
@Test
func reportSnapshot() throws {
    let report = generateReport()

    try TextSnapshot.assert(report, named: "quarterly_report")
}
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
