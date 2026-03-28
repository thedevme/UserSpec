# Getting Started

Add UserSpec to your project and write your first BDD test.

## Overview

UserSpec is a BDD (Behavior-Driven Development) testing framework that works with Apple's Swift Testing framework. It provides a fluent API for writing tests in Given/When/Then format.

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

Or in Xcode: **File → Add Package Dependencies** → paste the GitHub URL → Add to test target only.

## Writing Your First Test

### Step 1: Import the Framework

```swift
import Testing
import UserSpec
```

### Step 2: Create a User Story

Use the `@UserStory` macro to group related scenarios:

```swift
@UserStory("As a user, I want to login so I can access my account")
struct LoginSpec {
    // Scenarios go here
}
```

### Step 3: Add a Scenario

Use `@Test` and `@Scenario` to define individual test cases:

```swift
@UserStory("As a user, I want to login so I can access my account")
struct LoginSpec {

    @Test
    @Scenario("Valid credentials grant access")
    func validCredentialsGrantAccess() throws {
        // Test implementation
    }
}
```

### Step 4: Write the Given/When/Then Chain

```swift
@Test
@Scenario("Valid credentials grant access")
func validCredentialsGrantAccess() throws {
    try given("a registered user") {
        User(email: "test@example.com", password: "secret123")
    }
    .when("they submit valid credentials") { user in
        AuthService().login(email: user.email, password: user.password)
    }
    .then("access is granted") { result, context in
        #expect(result == .success)
    }
}
```

## Understanding the Chain

### given()

The `given()` function sets up the initial context. It takes:
- A description string
- A setup closure that returns the context

```swift
given("a shopping cart with items") {
    Cart(items: [Item(name: "Book", price: 10.99)])
}
```

### .when()

The `.when()` method chains from given and performs an action:
- A description string
- An action closure that receives the context and returns a result

```swift
.when("user applies discount code") { cart in
    cart.applyDiscount(code: "SAVE10")
}
```

### .then()

The `.then()` method executes the chain and asserts the outcome:
- A description string
- An assertion closure that receives the result and step context

```swift
.then("total is reduced by 10%") { result, context in
    #expect(result.discount == 0.10)
}
```

## Running Tests

Run your tests with:

```bash
swift test
```

Or use Xcode's Test Navigator (⌘6).

## Next Steps

- Learn about <doc:GivenWhenThen> in depth
- Explore <doc:UITesting> for XCUITest integration
- Read about async testing with ``AsyncGivenStep``
