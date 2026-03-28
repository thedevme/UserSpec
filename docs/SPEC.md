# UserSpec — Framework Spec
*Version 1.0 — March 2026*

---

## OVERVIEW

UserSpec is a BDD (Behavior-Driven Development) testing framework for Swift, built natively on top of Apple's Swift Testing framework. It brings the London School (outside-in) approach to iOS testing by connecting user stories, scenarios, and Given/When/Then specs in a single coherent chain.

---

## GOALS

- Provide a native Swift BDD layer on top of Swift Testing
- Zero external dependencies — Swift Testing ships with Xcode 16
- Feel like a natural extension of Swift, not a third-party overlay
- Support the full chain: User Story → Scenario → Unit Test → UI Test
- Work seamlessly with Swift Concurrency (async/await)
- Be available via Swift Package Manager
- Be open source on GitHub under Apache 2.0

---

## NON-GOALS

- Does not replace Swift Testing — sits on top of it
- Does not support XCTest (old framework)
- Does not support Objective-C
- Does not support iOS versions below 17 / macOS below 14
- Does not try to replicate Gherkin/Cucumber feature files

---

## PLATFORM REQUIREMENTS

```
Swift 6.0+
iOS 17+
macOS 14+
watchOS 10+
tvOS 17+
visionOS 1+
Xcode 16+
```

---

## GITHUB SETUP

### Repository
```
https://github.com/craigclayton/UserSpec
```

### Repository Structure
```
UserSpec/
├── .github/
│   ├── workflows/
│   │   └── ci.yml              # GitHub Actions CI
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
├── Sources/
│   └── UserSpec/
│       ├── Macros/
│       │   ├── UserStoryMacro.swift
│       │   └── ScenarioMacro.swift
│       ├── Steps/
│       │   ├── GivenStep.swift
│       │   ├── WhenStep.swift
│       │   └── ThenStep.swift
│       ├── UITesting/
│       │   ├── UIScenario.swift
│       │   ├── UIGivenStep.swift
│       │   ├── UIWhenStep.swift
│       │   └── UIThenStep.swift
│       ├── Core/
│       │   ├── Spec.swift
│       │   ├── StepRunner.swift
│       │   └── StepContext.swift
│       └── UserSpec.swift      # Public API exports
├── Tests/
│   └── UserSpecTests/
│       ├── GivenWhenThenTests.swift
│       ├── MacroTests.swift
│       ├── AsyncTests.swift
│       └── UIScenarioTests.swift
├── Package.swift
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE                     # Apache 2.0
└── .gitignore
```

### Branch Strategy
- `main` — stable, tagged releases only
- `develop` — integration branch
- `feature/xxx` — feature branches off develop

### Releases
- Semantic versioning: `v0.1.0`, `v0.2.0`, `v1.0.0`
- GitHub Releases with changelogs
- Each release tagged — required for SPM versioning

---

## SWIFT PACKAGE MANAGER

### Package.swift
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UserSpec",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "UserSpec",
            targets: ["UserSpec"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "UserSpec",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "UserSpecTests",
            dependencies: ["UserSpec"]
        )
    ]
)
```

### How Developers Install It
```swift
// In their Package.swift
dependencies: [
    .package(
        url: "https://github.com/craigclayton/UserSpec.git",
        from: "0.1.0"
    )
]

// In their test target
.testTarget(
    name: "MyAppTests",
    dependencies: [
        "MyApp",
        .product(name: "UserSpec", package: "UserSpec")
    ]
)
```

### Xcode Integration
File → Add Package Dependencies → paste GitHub URL → Add to test target only (never main target)

---

## PUBLIC API SPEC

### @UserStory Macro
Attaches to a struct. Marks the struct as a collection of scenarios for a specific user story. The description is the user story in plain English.

```swift
@UserStory("As a traveler, I want to select my seat so I can sit comfortably")
struct SeatSelectionSpec { }
```

**Behavior:**
- Generates a `@Suite` annotation under the hood
- Description appears in Xcode test navigator
- Description appears in CI output on failure
- Multiple @UserStory structs can exist per file

---

### @Scenario Macro
Attaches to a function inside a @UserStory struct. Marks the function as a test scenario. Must be combined with @Test from Swift Testing.

```swift
@UserStory("As a traveler, I want to select my seat")
struct SeatSelectionSpec {

    @Test
    @Scenario("Economy user cannot select business class seat")
    func economyCannotSelectBusiness() { }
}
```

**Behavior:**
- Generates a `@Test` wrapper under the hood (or combines with existing @Test)
- Scenario description appears in test navigator
- Scenario description printed in failure output
- Each scenario is independent — no shared state between scenarios

---

### given() Function
Top level free function. Takes a description string and a setup closure. Returns a GivenStep. This is the entry point for every test.

```swift
given("user has an economy ticket") {
    User(ticketClass: .economy)
}
```

**Signature:**
```swift
public func given<Context>(
    _ description: String,
    setup: @escaping () -> Context
) -> GivenStep<Context>

// Async variant
public func given<Context>(
    _ description: String,
    setup: @escaping () async throws -> Context
) -> AsyncGivenStep<Context>
```

---

### GivenStep.when()
Chained method on GivenStep. Takes a description and an action closure that receives the context from given(). Returns a WhenStep.

```swift
given("user has an economy ticket") { ... }
.when("they tap seat 1A in Business Class") { user in
    SeatMap().select(seat: "1A", for: user)
}
```

**Signature:**
```swift
public func when<Result>(
    _ description: String,
    action: @escaping (Context) -> Result
) -> WhenStep<Context, Result>

// Async variant
public func when<Result>(
    _ description: String,
    action: @escaping (Context) async throws -> Result
) -> AsyncWhenStep<Context, Result>
```

---

### WhenStep.then()
Terminal method. Takes a description and an assertion closure. Executes the full chain. Returns nothing — this is where the test runs.

```swift
.then("selection fails with class restriction") { result in
    #expect(result == .failed(.classRestriction))
}
```

**Signature:**
```swift
public func then(
    _ description: String,
    assertion: @escaping (Result) -> Void
)

// Async variant
public func then(
    _ description: String,
    assertion: @escaping (Result) async throws -> Void
) async throws
```

---

### Full Unit Test Example
```swift
import Testing
import UserSpec

@UserStory("As a traveler, I want to select my seat")
struct SeatSelectionSpec {

    @Test
    @Scenario("Economy user cannot select business class seat")
    func economyCannotSelectBusiness() {
        given("user has an economy ticket") {
            User(ticketClass: .economy)
        }
        .when("they tap seat 1A in Business Class") { user in
            SeatMap().select(seat: "1A", for: user)
        }
        .then("selection fails with class restriction") { result in
            #expect(result == .failed(.classRestriction))
        }
    }

    @Test
    @Scenario("Economy user can select an economy seat")
    func economyCanSelectEconomySeat() {
        given("user has an economy ticket") {
            User(ticketClass: .economy)
        }
        .when("they tap seat 22B in Economy") { user in
            SeatMap().select(seat: "22B", for: user)
        }
        .then("seat is confirmed") { result in
            #expect(result == .confirmed)
        }
    }
}
```

---

### Async Example
```swift
@Test
@Scenario("Booking confirms against live API")
func bookingConfirms() async throws {
    given("available flight to JFK") {
        await FlightAPI.shared.nextAvailableFlight()
    }
    .when("user books seat 12A") { flight in
        await FlightAPI.shared.bookSeat("12A", on: flight)
    }
    .then("booking is confirmed with reference number") { booking in
        #expect(booking.status == .confirmed)
        #expect(booking.reference != nil)
    }
}
```

---

### @UIScenario Macro
UI testing variant. Used with XCUITest. Provides givenApp, whenTap, thenSee convenience methods.

```swift
@UserStory("As a traveler, I want to select my seat")
struct SeatSelectionUISpec {

    @Test
    @UIScenario("Economy user sees error when tapping business seat")
    func economySeesErrorOnBusinessSeat() {
        givenApp("user has an economy ticket") {
            app.launchWithEconomyUser()
        }
        .whenTap("seat 1A in Business Class") { app in
            app.buttons["seat-1A"].tap()
        }
        .thenSee("class restriction error message") { app in
            #expect(app.staticTexts["Only economy seats available"].exists)
        }
    }
}
```

**Note:** @UIScenario requires XCUIApplication to be passed or available. XCUITest target only — never main app target.

---

## FAILURE OUTPUT

When a test fails the output should show the full Given/When/Then chain:

```
❌ Test failed: Economy user cannot select business class seat

  Given: user has an economy ticket
  When:  they tap seat 1A in Business Class
  Then:  selection fails with class restriction

  Expectation failed: (result → .confirmed) == .failed(.classRestriction)
  UserSpecTests/SeatSelectionSpec.swift:24
```

---

## INTERNAL ARCHITECTURE

### Step Types (Generic Chain)
```swift
// GivenStep — holds setup closure
public struct GivenStep<Context> {
    let description: String
    let setup: () -> Context
}

// WhenStep — holds given + action
public struct WhenStep<Context, Result> {
    let given: GivenStep<Context>
    let description: String
    let action: (Context) -> Result
}

// Async variants mirror the sync versions
public struct AsyncGivenStep<Context> { ... }
public struct AsyncWhenStep<Context, Result> { ... }
```

### StepContext
Captures Given/When/Then descriptions for failure reporting.

```swift
struct StepContext {
    let givenDescription: String
    let whenDescription: String
    let thenDescription: String

    func formatFailureMessage() -> String {
        """
        Given: \(givenDescription)
        When:  \(whenDescription)
        Then:  \(thenDescription)
        """
    }
}
```

### StepRunner
Executes the full chain and handles failure reporting.

```swift
struct StepRunner {
    static func run<Context, Result>(
        context: StepContext,
        setup: () -> Context,
        action: (Context) -> Result,
        assertion: (Result) -> Void
    ) {
        let ctx = setup()
        let result = action(ctx)
        assertion(result)
    }
}
```

---

## GITHUB ACTIONS CI

### .github/workflows/ci.yml
```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: Test on ${{ matrix.platform }}
    runs-on: macos-14
    strategy:
      matrix:
        platform: [iOS, macOS]

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Build and Test (macOS)
        if: matrix.platform == 'macOS'
        run: swift test

      - name: Build and Test (iOS Simulator)
        if: matrix.platform == 'iOS'
        run: |
          xcodebuild test \
            -scheme UserSpec \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

---

## README STRUCTURE

```markdown
# UserSpec

A BDD testing framework for Swift, built natively on Swift Testing.

## What is UserSpec?

UserSpec brings the London School (outside-in) testing approach to iOS 
development. Write user stories, break them into Given/When/Then scenarios, 
and let them drive your implementation.

## Requirements
- Swift 6.0+
- Xcode 16+
- iOS 17+ / macOS 14+

## Installation (Swift Package Manager)
[code example]

## Quick Start
[basic example]

## The Full Chain
Design → User Story → @Scenario → Given/When/Then → #expect

## Documentation
[link to docs]

## The Book
UserSpec is the companion framework to The Swift Testing Handbook by Craig Clayton.
Learn Design-Driven Development from the ground up.
[link to book]

## License
Apache 2.0
```

---

## CHANGELOG FORMAT

```markdown
# Changelog

## [Unreleased]

## [0.1.0] - 2026-XX-XX
### Added
- @UserStory macro
- @Scenario macro
- given() / when() / then() chain
- Async support
- Swift Package Manager distribution

## [0.2.0] - TBD
### Added
- @UIScenario macro
- XCUITest integration
- givenApp / whenTap / thenSee API
```

---

## DOCUMENTATION

### Format — DocC
Apple's DocC is the standard for Swift packages. It generates documentation from source comments and renders in Xcode's documentation browser and as a hosted website.

### DocC Catalog Structure
```
Sources/UserSpec/
└── UserSpec.docc/
    ├── UserSpec.md              # Landing page
    ├── GettingStarted.md        # Quick start guide
    ├── UserStoryMacro.md        # @UserStory deep dive
    ├── ScenarioMacro.md         # @Scenario deep dive
    ├── GivenWhenThen.md         # The step chain explained
    ├── AsyncTesting.md          # Async/await guide
    ├── UITesting.md             # @UIScenario guide
    ├── Resources/
    │   └── userspec-chain.png   # Diagram: design → story → spec → test
    └── Tutorials/
        └── FirstScenario/       # Guided tutorial
            ├── FirstScenario.tutorial
            └── Resources/
```

### Source Comment Format
Every public API must have DocC comments. Format:

```swift
/// A step that sets up the context for a test scenario.
///
/// Create a `GivenStep` using the ``given(_:setup:)`` free function.
/// Chain it with ``when(_:action:)`` to describe the action,
/// then terminate with ``then(_:assertion:)`` to verify the result.
///
/// ## Example
///
/// ```swift
/// given("user has an economy ticket") {
///     User(ticketClass: .economy)
/// }
/// .when("they tap seat 1A") { user in
///     SeatMap().select(seat: "1A", for: user)
/// }
/// .then("selection fails") { result in
///     #expect(result == .failed(.classRestriction))
/// }
/// ```
public struct GivenStep<Context> { }
```

### Every Public Symbol Requires
- One line summary (appears in Xcode autocomplete)
- Parameters documented with `- Parameter name:`
- Returns documented with `- Returns:`
- At least one code example in a fenced code block
- Links to related symbols using double backtick syntax

### Documentation Site
Hosted via GitHub Pages. Built automatically on every release via GitHub Actions.

```yaml
# Add to ci.yml on release
- name: Build DocC
  run: |
    swift package generate-documentation \
      --product UserSpec \
      --hosting-base-path UserSpec

- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: .build/plugins/Swift-DocC/outputs/UserSpec.doccarchive
```

**Final URL:** `https://craigclayton.github.io/UserSpec/documentation/userspec`

### README Badge
Add to top of README once docs are live:
```markdown
[![Documentation](https://img.shields.io/badge/docs-DocC-blue)](https://craigclayton.github.io/UserSpec/documentation/userspec)
```

### Documentation Milestone Per Version
- **v0.1.0** — all public API symbols have DocC comments, README complete
- **v0.2.0** — @UIScenario documented, Getting Started guide written
- **v1.0.0** — full DocC site live on GitHub Pages, tutorial complete, book published

---

## VERSION ROADMAP

### v0.1.0 — Foundation
- @UserStory macro
- @Scenario macro
- given() / when() / then() sync chain
- Async/await support
- Failure output with full chain description
- Swift Package Manager
- GitHub Actions CI
- README with book link

### v0.2.0 — UI Testing
- @UIScenario macro
- givenApp / whenTap / thenSee
- XCUITest integration

### v1.0.0 — Stable
- API locked, no breaking changes without major version bump
- Full DocC documentation
- All platforms tested in CI
- Book published, framework battle-tested

---

## CLI DEVELOPMENT WORKFLOW

Built using Claude Code CLI. Each feature follows the spec-driven approach the book teaches.

### CLAUDE.md for the project
```markdown
# UserSpec — Claude Code Config

## Project
Swift Package — BDD testing framework on top of Swift Testing

## Key rules
- No external dependencies ever
- All public API must match the spec in SPEC.md
- Async variants required for every sync API
- Tests must use Swift Testing (@Test, #expect) not XCTest
- Follow Swift 6 strict concurrency

## Structure
Sources/UserSpec/ — framework code
Tests/UserSpecTests/ — framework tests

## Commands
swift build — build the package
swift test — run all tests
```

### Development Order
1. Package.swift setup
2. Core step types (GivenStep, WhenStep, sync chain)
3. given() free function
4. Failure output / StepContext
5. Async variants
6. @UserStory macro
7. @Scenario macro
8. Tests for all of the above
9. README
10. First GitHub release (v0.1.0)
11. @UIScenario macro (v0.2.0)

---

*Spec v1.0 — March 2026*
*Framework by Craig Clayton — mobiledesigndev.com*
*Companion to The Swift Testing Handbook*
