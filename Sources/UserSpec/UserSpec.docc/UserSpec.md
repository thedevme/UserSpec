# ``UserSpec``

A BDD testing framework for Swift, built natively on Swift Testing.

## Overview

UserSpec brings the London School (outside-in) testing approach to iOS development. Write user stories, break them into Given/When/Then scenarios, and let them drive your implementation.

```swift
@UserStory("As a traveler, I want to select my seat")
struct SeatSelectionSpec {

    @Test
    @Scenario("Economy user can select an economy seat")
    func economyCanSelectEconomySeat() throws {
        try given("user has an economy ticket") {
            User(ticketClass: .economy)
        }
        .when("they tap seat 22B") { user in
            SeatMap().select(seat: "22B", for: user)
        }
        .then("seat is confirmed") { result, context in
            #expect(result == .confirmed)
        }
    }
}
```

## The Full Chain

UserSpec connects your design requirements to executable tests:

```
Design → User Story → @Scenario → Given/When/Then → #expect
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:GivenWhenThen>

### Macros

- ``UserStory(_:)``
- ``Scenario(_:)``
- ``UIScenario(_:)``

### Unit Testing

- ``given(_:setup:)-4l5wm``
- ``GivenStep``
- ``WhenStep``
- ``StepContext``

### Async Testing

- ``given(_:setup:)-68bc2``
- ``AsyncGivenStep``
- ``AsyncWhenStep``

### UI Testing

- <doc:UITesting>
- ``givenApp(_:setup:)-1lpqv``
- ``UIGivenStep``
- ``UIWhenStep``
