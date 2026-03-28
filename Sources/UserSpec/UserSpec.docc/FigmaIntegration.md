# Figma Integration

Connect design prototypes to executable UI tests.

## Overview

UserSpec enables Design-Driven Development where Figma prototypes define the expected user experience. This guide shows how to translate Figma flows into UserSpec UI tests.

## Workflow Overview

```
Figma Prototype → User Flows → UI Scenarios → XCUITest
```

1. Designer creates interactive prototype in Figma
2. Prototype defines user flows with states and transitions
3. Developer writes UserSpec UI tests matching the flows
4. Tests validate that implementation matches design

## Reading Figma Prototypes

### Identify User Flows

In Figma, examine the prototype's flow connections:

- **Starting frame:** Initial state (maps to `Given`)
- **Interaction:** Tap, swipe, etc. (maps to `When`)
- **Destination frame:** Result state (maps to `Then`)

### Example: Login Flow

**Figma Prototype Structure:**
```
Frame: "Login Screen (Empty)"
  → [Tap "Login" button]
  → Frame: "Login Screen (Validation Error)"

Frame: "Login Screen (Filled)"
  → [Tap "Login" button]
  → Frame: "Home Screen"
```

### Corresponding UserSpec Test

```swift
import XCTest
import Testing
import UserSpec

@UserStory("As a user, I want to log in so that I can access my account")
struct LoginUISpec {

    // Figma: Login Screen (Empty) → Validation Error
    @Test
    @UIScenario("Empty form shows validation error")
    func emptyFormShowsValidation() throws {
        let app = XCUIApplication()

        try givenApp("login screen with empty fields") {
            app.launchArguments = ["--reset-state"]
            return app.launched()
        }
        .whenTap("Login button") { app in
            app.buttons["Login"].tap()
            return app
        }
        .thenSee("validation error message") { app, context in
            #expect(app.staticTexts["Please enter email and password"].exists)
        }
    }

    // Figma: Login Screen (Filled) → Home Screen
    @Test
    @UIScenario("Valid credentials navigate to home")
    func validCredentialsNavigateToHome() throws {
        let app = XCUIApplication()

        try givenApp("login screen") {
            app.launched()
        }
        .when("user enters valid credentials") { app in
            app.textFields["Email"].tap()
            app.textFields["Email"].typeText("user@example.com")
            app.secureTextFields["Password"].tap()
            app.secureTextFields["Password"].typeText("password123")
            return app
        }
        .whenTap("Login button") { app in
            app.buttons["Login"].tap()
            return app
        }
        .thenSee("home screen") { app, context in
            #expect(app.navigationBars["Home"].exists)
        }
    }
}
```

## Matching Figma Components

### Accessibility Identifiers

Set accessibility identifiers in your app to match Figma layer names:

**Figma Layer Names:**
```
- "Login Button"
- "Email Input"
- "Password Input"
- "Error Message"
```

**SwiftUI Implementation:**
```swift
Button("Login") { }
    .accessibilityIdentifier("Login Button")

TextField("Email", text: $email)
    .accessibilityIdentifier("Email Input")

SecureField("Password", text: $password)
    .accessibilityIdentifier("Password Input")
```

**UserSpec Test:**
```swift
try givenApp("login screen") {
    app.launched()
}
.whenTap("Login Button") { app in
    app.buttons["Login Button"].tap()
    return app
}
.thenSee("Error Message") { app, context in
    #expect(app.staticTexts["Error Message"].exists)
}
```

## Testing Design Variations

### Component States from Figma

Figma often shows multiple states of a component:

**Figma Variants:**
```
Button/Default
Button/Pressed
Button/Disabled
Button/Loading
```

**UserSpec Tests:**
```swift
@Suite("Button States")
struct ButtonStateSpec {

    @Test
    @UIScenario("Button disabled when form invalid")
    func buttonDisabledWhenInvalid() throws {
        try givenApp("empty form") {
            XCUIApplication().launched()
        }
        .thenSee("disabled submit button") { app, context in
            #expect(app.buttons["Submit"].isEnabled == false)
        }
    }

    @Test
    @UIScenario("Button enabled when form valid")
    func buttonEnabledWhenValid() throws {
        try givenApp("completed form") {
            let app = XCUIApplication()
            app.launchArguments = ["--prefill-form"]
            return app.launched()
        }
        .thenSee("enabled submit button") { app, context in
            #expect(app.buttons["Submit"].isEnabled == true)
        }
    }
}
```

## Design Tokens and Colors

While UserSpec doesn't test visual appearance directly, you can verify design system usage:

```swift
@Test
@UIScenario("Error state uses error color")
func errorStateUsesErrorColor() throws {
    // Test that error elements exist and are visible
    try givenApp("form with validation error") {
        let app = XCUIApplication()
        app.launchArguments = ["--show-validation-error"]
        return app.launched()
    }
    .thenSee("error indicator") { app, context in
        let errorLabel = app.staticTexts["Error Message"]
        #expect(errorLabel.exists)
        #expect(errorLabel.isHittable)
    }
}
```

## Responsive Design Testing

Test different device configurations that match Figma breakpoints:

```swift
@Suite("Responsive Layout")
struct ResponsiveLayoutSpec {

    @Test
    @UIScenario("Compact layout on iPhone SE")
    func compactLayoutOnSmallDevice() throws {
        // Configure for specific device in test plan
        try givenApp("app on small screen") {
            XCUIApplication().launched()
        }
        .thenSee("compact navigation") { app, context in
            #expect(app.tabBars.firstMatch.exists)
            #expect(app.navigationBars.firstMatch.exists)
        }
    }

    @Test
    @UIScenario("Sidebar layout on iPad")
    func sidebarLayoutOnIPad() throws {
        try givenApp("app on iPad") {
            XCUIApplication().launched()
        }
        .thenSee("sidebar navigation") { app, context in
            #expect(app.tables["Sidebar"].exists)
        }
    }
}
```

## Best Practices

| Practice | Description |
|----------|-------------|
| Match layer names | Use Figma layer names as accessibility identifiers |
| Test all states | Cover all component variants shown in Figma |
| Document flows | Add comments referencing Figma frame names |
| Screenshot comparison | Use XCTest attachments for visual validation |

## Workflow Tips

### Naming Convention

Match test scenario names to Figma flow descriptions:

```swift
// Figma flow: "Login" → "Home (Success)"
@Scenario("Login navigates to Home on success")

// Figma flow: "Login" → "Error Toast"
@Scenario("Login shows error toast on failure")
```

### Frame References

Add Figma frame references in comments:

```swift
// Figma: https://figma.com/file/abc123?node-id=10:20
@Test
@UIScenario("Cart shows empty state")
func cartShowsEmptyState() throws {
    // ...
}
```

## See Also

- <doc:UITesting>
- ``givenApp(_:setup:)``
- ``UIGivenStep``
