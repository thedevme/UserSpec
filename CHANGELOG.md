# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.6.3] - 2026-07-06

### Changed
- RSpec output now prints after **each test completes** for immediate visibility
- No longer requires `@Suite(.rspecReporting)` trait (was unreliable in Xcode)
- Report will print multiple times (once per test) but is always visible

### Fixed
- RSpec output not appearing in Xcode console
- Test Scoping Trait approach was unreliable across different Xcode/Swift versions

## [1.6.2] - 2026-07-06

### Added
- `RSpecReportingTrait` for reliable RSpec output in Xcode/iOS Simulator tests
- `@Suite(.rspecReporting)` trait for iOS 18.0+ to ensure reports print in Xcode
- Documentation guide for RSpec output setup (`docs/RSpec-Output.md`)

### Changed
- RSpec output now requires `@Suite(.rspecReporting)` for Xcode/iOS Simulator tests
- Command-line `swift test` continues to work automatically via `atexit`

### Fixed
- RSpec output not appearing in Xcode iOS Simulator tests (atexit doesn't fire)

### Technical Notes
- Test Scoping Traits (Swift 6.1+) enable reliable reporting in Xcode
- `atexit` handlers don't fire in iOS Simulator tests, hence the need for the trait

## [1.6.1] - 2026-07-06

### Changed
- RSpec output is now enabled by default (previously required `USERSPEC_RSPEC_OUTPUT=1`)
- Environment variable `USERSPEC_RSPEC_OUTPUT` is no longer required

## [1.6.0] - 2026-07-03

### Added
- RSpec-style documentation output for test scenarios
- `RSpecReporter` for printing scenarios in RSpec format
- `expectRSpec()` throwing assertion function for accurate failure detection
- `UserStoryRegistry` for type-based user story lookup
- Automatic story grouping with nested scenario display
- Color-coded pass/fail indicators (✓ green, ✗ red) with TTY detection
- Incomplete scenario detection (scenarios that fail before `.then()`)
- Reflection-based story extraction from `Test.current`
- Synchronous lock-based reporter implementation (race-free)
- Support for both `@Scenario` and `@UIScenario` in RSpec output
- Demo test file showing all RSpec output features

### Changed
- `@UserStory` macro now generates `init()` for automatic story registration
- `given()` and `givenApp()` functions now register scenarios when RSpec output is enabled
- `.then()` and `.thenSee()` functions now track scenario completion for reporting

### Technical Notes
- Standard `#expect` failures cannot be detected due to Swift Testing API limitations
- Use `expectRSpec()` instead of `#expect` for accurate failure reporting in RSpec output
- Output prints at process exit via `atexit` handler
- Story grouping uses macro-generated initialization and global registry

## [1.5.0] - 2026-03-28

### Added
- `SnapshotManager` for recording and comparing snapshots
- `SnapshotConfig` for customizing snapshot directory and file extension
- `SnapshotResult` enum for match/mismatch/noReference states
- `SnapshotRepresentable` protocol for types convertible to snapshot data
- Built-in conformances for String, Data, Array, Dictionary, and Encodable
- `assertSnapshot()` function for snapshot assertions
- `InlineSnapshot<T>` for in-code expected values
- `JSONSnapshot` helper for JSON-encodable types
- `TextSnapshot` helper for text content
- `SnapshotError` with descriptive diff output
- 24 new tests for snapshot testing

## [1.4.0] - 2026-03-28

### Added
- `Benchmark` for measuring execution time of operations
- `Benchmark.measure()` returns value with duration (sync and async)
- `Benchmark.measureAverage()` runs multiple iterations
- `PerformanceAssert.completes(within:)` asserts time thresholds
- `PerformanceAssert.completesInMilliseconds()` convenience method
- `PerformanceBaseline` for storing and comparing performance baselines
- `PerformanceBaseline.compare()` detects regressions vs improvements
- `MemoryMeasurement` for tracking memory allocation
- `MemoryMeasurement.currentUsage` and `currentUsageMB`
- `PerformanceReporter` for collecting and reporting performance metrics
- `PerformanceReporter.generateReport()` creates summary reports
- 31 new tests for performance features

## [1.3.0] - 2026-03-28

### Added
- `Mockable` protocol for creating mock objects with call recording
- `CallRecorder` for tracking method invocations and arguments
- `Spy<T>` wrapper for recording calls on real objects
- `Stub<T>` fluent builder for setting up stub return values
- Argument matchers: `AnyMatcher`, `EqualMatcher`, `PredicateMatcher`, `NilMatcher`, `NotNilMatcher`
- `Verify` helpers for mock verification assertions
- `verifyMock()` throwing functions for test assertions
- Jira integration guide with workflow and StoryParser examples
- Figma integration guide for design-driven UI testing
- 36 new tests for mocking framework

## [1.2.0] - 2026-03-28

### Added
- `StoryParser` for converting plain text user stories to Swift test stubs
- `StoryParser.parse()` extracts role, action, benefit, and scenarios from text
- `StoryParser.generateSwift()` generates Swift test code from parsed stories
- `StoryParser.generateGherkin()` exports stories in Gherkin format
- `TestReporter` singleton for recording test results
- `ReportGenerator.generateHTML()` creates interactive HTML test reports
- `ReportGenerator.generateGherkin()` exports results in Gherkin format
- `ReportGenerator.generateConsole()` creates terminal-friendly reports
- `ReportGenerator.writeHTML()` and `writeGherkin()` file output helpers
- 21 new tests for StoryParser and Reporter

## [1.1.0] - 2026-03-28

### Added
- `Buildable` protocol for test data builders with `build()` closure API
- `Builder<T>` fluent builder with `.with()` and `.configured()` chaining
- `FixtureProviding` protocol for named test fixtures
- Array builders with `[T].build(count:configure:)`
- `SharedExamples` registry for reusable test behaviors
- `SharedBehavior` protocol for type-safe shared behaviors
- `itBehavesLike()` convenience function
- Async shared examples support
- Xcode templates for UserStory and Scenario
- Examples folder with e-commerce sample project
- 22 new tests for builders and shared examples

## [1.0.0] - 2026-03-28

### Added
- Full DocC documentation for all public APIs
- DocC catalog with Getting Started guide
- DocC articles for Given/When/Then and UI Testing
- GitHub Actions CI for all platforms (macOS, iOS, watchOS, tvOS, visionOS)
- Documentation build workflow

### Changed
- API is now stable — no breaking changes without major version bump

## [0.2.0] - 2026-03-28

### Added
- `@UIScenario` macro for UI test scenarios
- `givenApp()` function for XCUITest integration
- `UIGivenStep` and `UIWhenStep` types for UI test chains
- `.whenTap()` action for tap interactions
- `.thenSee()` assertion for visual verification
- `AsyncUIGivenStep` and `AsyncUIWhenStep` for async UI tests
- `XCUIApplication` extensions: `launched()`, `launched(with:)`, `launched(environment:)`
- Comprehensive UI testing test suite (15 tests)

## [0.1.0] - 2026-03-28

### Added
- `@UserStory` macro for marking test structs with user story descriptions
- `@Scenario` macro for marking test functions with scenario descriptions
- `given()` / `when()` / `then()` chain for BDD-style tests
- Async support with `AsyncGivenStep` and `AsyncWhenStep`
- `StepContext` for failure message formatting
- Swift Package Manager distribution
- Comprehensive test suite (41 tests)
