import Foundation
import Testing
@testable import UserSpec

/// Final demonstration of RSpec-style output for UserSpec.
///
/// Run with: USERSPEC_RSPEC_OUTPUT=1 swift test --filter RSpecFinalDemo
///
/// This demonstrates:
/// - ✓ Passing scenarios
/// - ✗ Failing scenarios (using expectRSpec)
/// - ✗ Incomplete scenarios (throw before .then())
/// - Story grouping (scenarios nested under user stories)
/// - Color output (when stdout is a TTY)
/// - Summary line with scenario and failure counts

@UserStory("As a traveler, I want to select my seat so I can sit comfortably")
struct SeatSelectionRSpecFinalDemo {

    @Test("Economy user can select an economy seat")
    func economySelectsEconomy() throws {
        try given("a flight with economy seats available") {
            ["12A", "12B", "12C"]
        }
        .when("economy user selects seat 12A") { seats in
            seats.first
        }
        .then("seat is selected") { seat, _ in
            try expectRSpec(seat == "12A")
        }
    }

    @Test("Economy user cannot select a business seat")
    func economyCannotSelectBusiness() throws {
        try given("a flight with business-only seats") {
            [] as [String]
        }
        .when("economy user attempts to select seat") { seats in
            seats.first
        }
        .then("selection is rejected") { seat, _ in
            try expectRSpec(seat == nil)
        }
    }

    @Test("Business user can select a business seat")
    func businessSelectsBusiness() throws {
        try given("a flight with business seats") {
            ["1A", "1B"]
        }
        .when("business user selects seat 1A") { seats in
            seats.first
        }
        .then("seat is selected") { seat, _ in
            // This will fail to demonstrate ✗ output
            try expectRSpec(seat == "1B")  // Wrong! Expected 1A
        }
    }

    @Test("Seat selection fails when flight is fully booked")
    func fullFlightScenario() throws {
        struct NoSeatsError: Error {}

        try given("a fully booked flight") {
            throw NoSeatsError()  // No seats available
        }
        .when("user attempts to select a seat") { _ in
            "unreachable"
        }
        .then("should never reach here") { _, _ in
            try expectRSpec(false)
        }
    }
}

@UserStory("As a user, I want to log in to access my account")
struct LoginRSpecFinalDemo {

    @Test("Valid credentials grant access")
    func validCredentials() throws {
        try given("a registered user") {
            ("user@example.com", "password123")
        }
        .when("they provide valid credentials") { creds in
            creds.0 == "user@example.com" && creds.1 == "password123"
        }
        .then("access is granted") { isValid, _ in
            try expectRSpec(isValid)
        }
    }

    @Test("Invalid credentials deny access")
    func invalidCredentials() throws {
        try given("a registered user") {
            ("user@example.com", "password123")
        }
        .when("they provide wrong password") { _ in
            false
        }
        .then("access is denied") { isValid, _ in
            try expectRSpec(isValid == false)
        }
    }
}
