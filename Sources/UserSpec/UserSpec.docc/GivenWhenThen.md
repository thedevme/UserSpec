# Given/When/Then Chains

Write expressive BDD tests using the Given/When/Then pattern.

## Overview

The Given/When/Then pattern is the core of UserSpec. It provides a fluent API for writing tests that read like specifications:

- **Given** — Set up the initial state
- **When** — Perform an action
- **Then** — Assert the expected outcome

## Basic Usage

```swift
try given("initial state") {
    // Setup code, returns context
    MyContext()
}
.when("action occurs") { context in
    // Action code, returns result
    context.performAction()
}
.then("expected outcome") { result, stepContext in
    // Assertions
    #expect(result == expectedValue)
}
```

## The Setup Closure

The `given()` setup closure creates the test context:

```swift
given("a user with premium subscription") {
    User(
        name: "Alice",
        subscription: .premium,
        credits: 100
    )
}
```

The closure is **not executed immediately** — it runs when `.then()` is called.

## The Action Closure

The `.when()` action closure receives the context and returns a result:

```swift
.when("user purchases an item") { user in
    let store = Store()
    return store.purchase(item: "Widget", for: user)
}
```

The result can be any type — structs, enums, tuples, or primitives.

## The Assertion Closure

The `.then()` assertion closure receives both the result and a ``StepContext``:

```swift
.then("purchase succeeds") { result, context in
    #expect(result.status == .completed)
    #expect(result.remainingCredits == 90)
}
```

The `StepContext` contains all step descriptions for failure reporting.

## Type Safety

UserSpec is fully generic. The context and result types flow through the chain:

```swift
// Context: User, Result: PurchaseResult
given("a user") { User() }                    // GivenStep<User>
.when("purchasing") { user in purchase(user) } // WhenStep<User, PurchaseResult>
.then("succeeds") { result, ctx in ... }       // Executes chain
```

## Error Handling

All closures can throw errors:

```swift
try given("setup that might fail") {
    try loadTestData()
}
.when("action that might fail") { data in
    try processData(data)
}
.then("assertion") { result, _ in
    #expect(result.isValid)
}
```

Errors propagate naturally — no special handling needed.

## Async Support

Use async closures for asynchronous operations:

```swift
try await given("async setup") {
    await fetchInitialState()
}
.when("async action") { state in
    await performAsyncOperation(state)
}
.then("async assertion") { result, _ in
    #expect(result.completed)
}
```

See ``AsyncGivenStep`` and ``AsyncWhenStep`` for details.

## Multiple Chains

Each chain is independent — no shared state:

```swift
@Test
func testMultipleScenarios() throws {
    // First scenario
    try given("state A") { StateA() }
        .when("action A") { s in s.actionA() }
        .then("result A") { r, _ in #expect(r.isA) }

    // Second scenario — completely independent
    try given("state B") { StateB() }
        .when("action B") { s in s.actionB() }
        .then("result B") { r, _ in #expect(r.isB) }
}
```

## Failure Messages

When a test fails, UserSpec shows the full chain:

```
❌ Test failed

  Given: a user with premium subscription
  When: user purchases an item
  Then: purchase succeeds

  Expectation failed: result.status == .completed
```

## Best Practices

### Keep Descriptions Clear

Write descriptions that read like documentation:

```swift
// Good
given("a registered user with verified email")
.when("they request password reset")
.then("reset email is sent")

// Avoid
given("user")
.when("reset")
.then("email")
```

### One Assertion Per Then

Focus each scenario on one behavior:

```swift
// Good — focused scenario
.then("email is sent to user") { result, _ in
    #expect(result.emailSent)
}

// Avoid — testing multiple things
.then("everything works") { result, _ in
    #expect(result.emailSent)
    #expect(result.loggedEvent)
    #expect(result.updatedDatabase)
}
```

### Use Descriptive Types

Create domain types for better readability:

```swift
struct PurchaseResult {
    let status: Status
    let receipt: Receipt?

    enum Status { case completed, failed, pending }
}
```
