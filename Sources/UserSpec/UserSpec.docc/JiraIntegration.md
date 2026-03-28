# Jira Integration

Connect your Jira tickets to executable UserSpec tests.

## Overview

UserSpec bridges the gap between product requirements in Jira and executable Swift tests. This guide shows how to structure your workflow so that Jira stories become UserSpec scenarios.

## Workflow Overview

```
Jira Story → Acceptance Criteria → UserSpec Scenarios → Swift Tests
```

1. Product defines user story in Jira
2. Story includes acceptance criteria in Given/When/Then format
3. Developer copies criteria into UserSpec test
4. Test drives implementation

## Jira Story Format

Structure your Jira stories with testable acceptance criteria:

**Title:** As a [role], I want [action] so that [benefit]

**Acceptance Criteria:**
```
Scenario: [Happy path]
Given [context]
When [action]
Then [expected outcome]

Scenario: [Edge case]
Given [different context]
When [action]
Then [different outcome]
```

## Example: Feature Ticket

### Jira Ticket SHOP-123

**Title:** As a shopper, I want to add items to my cart so that I can purchase them later

**Acceptance Criteria:**

```
Scenario: Adding in-stock item
Given an empty cart
When user adds an in-stock product
Then cart contains one item
And cart total reflects item price

Scenario: Adding out-of-stock item
Given an empty cart
When user adds an out-of-stock product
Then cart remains empty
And user sees "Out of stock" message

Scenario: Adding duplicate item
Given a cart with one item
When user adds the same item again
Then cart shows quantity of 2
```

### Corresponding UserSpec Test

```swift
import Testing
import UserSpec

@UserStory("As a shopper, I want to add items to my cart so that I can purchase them later")
struct CartSpec {

    // JIRA: SHOP-123 - Scenario 1
    @Test
    @Scenario("Adding in-stock item")
    func addingInStockItem() throws {
        try given("an empty cart") {
            Cart()
        }
        .when("user adds an in-stock product") { cart in
            cart.add(Product(name: "Widget", price: 9.99, inStock: true))
            return cart
        }
        .then("cart contains one item and total reflects price") { cart, context in
            #expect(cart.items.count == 1)
            #expect(cart.total == 9.99)
        }
    }

    // JIRA: SHOP-123 - Scenario 2
    @Test
    @Scenario("Adding out-of-stock item")
    func addingOutOfStockItem() throws {
        try given("an empty cart") {
            Cart()
        }
        .when("user adds an out-of-stock product") { cart in
            cart.add(Product(name: "Rare Item", price: 99.99, inStock: false))
            return cart
        }
        .then("cart remains empty") { cart, context in
            #expect(cart.items.isEmpty)
        }
    }

    // JIRA: SHOP-123 - Scenario 3
    @Test
    @Scenario("Adding duplicate item")
    func addingDuplicateItem() throws {
        let widget = Product(name: "Widget", price: 9.99, inStock: true)

        try given("a cart with one item") {
            var cart = Cart()
            cart.add(widget)
            return cart
        }
        .when("user adds the same item again") { cart in
            cart.add(widget)
            return cart
        }
        .then("cart shows quantity of 2") { cart, context in
            #expect(cart.quantity(of: widget) == 2)
        }
    }
}
```

## Using StoryParser with Jira Export

Export acceptance criteria from Jira and convert directly to test stubs:

```swift
// Copy-paste from Jira
let jiraText = """
As a shopper, I want to add items to cart so that I can purchase later

Scenario: Adding in-stock item
Given an empty cart
When user adds a product
Then cart contains one item
"""

// Parse and generate Swift code
if let story = StoryParser.parse(jiraText) {
    let code = StoryParser.generateSwift(from: story, moduleName: "ShoppingCart")
    print(code)
}
```

## Linking Tests to Jira

Use test tags or comments to maintain traceability:

```swift
// JIRA: SHOP-123
@Test
@Scenario("Adding in-stock item")
func addingInStockItem() throws {
    // ...
}
```

Or use Swift Testing's tag system:

```swift
extension Tag {
    @Tag static var shop123: Self
}

@Test(.tags(.shop123))
@Scenario("Adding in-stock item")
func addingInStockItem() throws {
    // ...
}
```

## Reporting Back to Jira

Generate Gherkin reports that can be attached to Jira tickets:

```swift
// After test run
let results = TestReporter.shared.allResults()
let gherkin = ReportGenerator.generateGherkin(from: results)
try gherkin.write(toFile: "test-results.feature", atomically: true, encoding: .utf8)
```

## Best Practices

| Practice | Description |
|----------|-------------|
| One story, one spec | Each Jira user story maps to one `@UserStory` struct |
| Match scenario names | Use exact scenario names from Jira acceptance criteria |
| Link with comments | Add `// JIRA: TICKET-123` comments for traceability |
| Export results | Generate Gherkin reports to attach to completed tickets |

## See Also

- ``StoryParser``
- ``ReportGenerator``
- <doc:GettingStarted>
