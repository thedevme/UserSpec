# UI Testing

Write BDD-style UI tests with XCUITest integration.

## Overview

UserSpec provides a dedicated API for UI testing that integrates seamlessly with XCUITest. Use `givenApp`, `whenTap`, and `thenSee` to write expressive UI tests.

## Basic Usage

```swift
import XCTest
import Testing
import UserSpec

@UserStory("As a user, I want to login")
struct LoginUISpec {

    @Test
    @UIScenario("User can login with valid credentials")
    func validLogin() throws {
        let app = XCUIApplication()

        try givenApp("app is launched on login screen") {
            app.launched()
        }
        .whenTap("login button") { app in
            app.textFields["Email"].tap()
            app.textFields["Email"].typeText("test@example.com")
            app.secureTextFields["Password"].tap()
            app.secureTextFields["Password"].typeText("password123")
            app.buttons["Login"].tap()
            return app
        }
        .thenSee("home screen") { app, context in
            #expect(app.navigationBars["Home"].exists)
        }
    }
}
```

## The givenApp Function

Use ``givenApp(_:setup:)-1lpqv`` to set up your app:

```swift
givenApp("user is logged in") {
    let app = XCUIApplication()
    app.launchArguments = ["--logged-in"]
    return app.launched()
}
```

### XCUIApplication Extensions

UserSpec adds convenient chaining methods:

```swift
// Launch and return for chaining
app.launched()

// Launch with arguments
app.launched(with: ["--reset-state", "--test-mode"])

// Launch with environment variables
app.launched(environment: [
    "API_URL": "https://test.api.com",
    "MOCK_DATA": "true"
])
```

## The whenTap Method

Use `.whenTap()` for tap interactions:

```swift
.whenTap("add to cart button") { app in
    app.buttons["Add to Cart"].tap()
    return app
}
```

For other interactions, use `.when()`:

```swift
.when("user swipes to delete") { app in
    app.cells.firstMatch.swipeLeft()
    app.buttons["Delete"].tap()
    return app
}
```

## The thenSee Method

Use `.thenSee()` for visual assertions:

```swift
.thenSee("success message") { app, context in
    #expect(app.staticTexts["Item added!"].exists)
    #expect(app.images["checkmark"].exists)
}
```

The `context` parameter contains step descriptions for debugging.

## Async UI Tests

All UI testing types support async operations:

```swift
try await givenApp("app loads data") {
    let app = XCUIApplication()
    app.launch()
    // Wait for async loading
    try await Task.sleep(nanoseconds: 1_000_000_000)
    return app
}
.whenTap("refresh button") { app in
    app.buttons["Refresh"].tap()
    return app
}
.thenSee("updated content") { app, _ in
    #expect(app.staticTexts["Updated"].exists)
}
```

## Complete Example

```swift
import XCTest
import Testing
import UserSpec

@UserStory("As a shopper, I want to add items to my cart")
struct ShoppingCartUISpec {

    @Test
    @UIScenario("Adding item shows confirmation")
    func addItemShowsConfirmation() throws {
        let app = XCUIApplication()

        try givenApp("app shows product list") {
            app.launched(with: ["--show-products"])
        }
        .whenTap("first product's add button") { app in
            let addButton = app.cells.firstMatch.buttons["Add"]
            addButton.tap()
            return app
        }
        .thenSee("cart badge shows 1 item") { app, _ in
            let badge = app.buttons["Cart"].staticTexts["1"]
            #expect(badge.exists)
        }
    }

    @Test
    @UIScenario("Empty cart shows message")
    func emptyCartShowsMessage() throws {
        let app = XCUIApplication()

        try givenApp("app launches with empty cart") {
            app.launched(with: ["--empty-cart"])
        }
        .whenTap("cart tab") { app in
            app.tabBars.buttons["Cart"].tap()
            return app
        }
        .thenSee("empty cart message") { app, _ in
            #expect(app.staticTexts["Your cart is empty"].exists)
            #expect(app.buttons["Start Shopping"].exists)
        }
    }
}
```

## Best Practices

### Use Accessibility Identifiers

Set accessibility identifiers in your app for reliable element selection:

```swift
// In your app
button.accessibilityIdentifier = "add-to-cart-button"

// In your test
app.buttons["add-to-cart-button"].tap()
```

### Handle Loading States

Wait for elements to appear:

```swift
.thenSee("content loads") { app, _ in
    let content = app.staticTexts["Welcome"]
    #expect(content.waitForExistence(timeout: 5))
}
```

### Use Launch Arguments

Configure app state via launch arguments:

```swift
givenApp("user is premium member") {
    XCUIApplication().launched(with: [
        "--premium-user",
        "--skip-onboarding"
    ])
}
```

### Keep UI Tests Focused

Test one user flow per scenario:

```swift
// Good — focused on login
@UIScenario("User can login")
func testLogin() { ... }

// Good — focused on logout
@UIScenario("User can logout")
func testLogout() { ... }
```
