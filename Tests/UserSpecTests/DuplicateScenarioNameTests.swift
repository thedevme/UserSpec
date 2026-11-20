//
//  DuplicateScenarioNameTests.swift
//  UserSpec
//
//  Created by Craig Clayton on 11/20/26.
//



import Testing
@testable import UserSpec

@Suite("Duplicate Scenario Name Tests")
struct DuplicateScenarioNameTests {

    @UserStory("As a shopper, I want to see my cart")
    struct ShoppingCart {

        @Test("The value is correct")
        @Scenario("The value is correct")
        func showsItemCount() throws {
            try given("a cart with two items") {
                2
            }
            .when("the item count is checked") { count in
                count
            }
            .then("two items are displayed") { count, _ in
                try expectRSpec(count == 2)
            }
        }
    }

    @UserStory("As a traveler, I want to see my booking")
    struct FlightBooking {

        @Test("The value is correct")
        @Scenario("The value is correct")
        func showsPassengerCount() throws {
            try given("a booking for three passengers") {
                3
            }
            .when("the passenger count is checked") { count in
                count
            }
            .then("three passengers are displayed") { count, _ in
                try expectRSpec(count == 3)
            }
        }
    }
}
