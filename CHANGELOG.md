# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
