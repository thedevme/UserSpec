import Testing
@testable import UserSpec

@Suite("Integration Tests")
struct IntegrationTests {

    // MARK: - Real-world Seat Selection Scenario (from spec)

    @Test("real-world seat selection scenario")
    func realWorldSeatSelectionScenario() throws {
        // Domain types
        struct Flight: Sendable {
            let number: String
            var seats: [Seat]
        }

        struct Seat: Sendable, Equatable {
            let code: String
            var isSelected: Bool
            var isAvailable: Bool
        }

        struct SeatMap: Sendable {
            var flight: Flight
            var selectedSeat: Seat?

            mutating func selectSeat(_ code: String) -> Seat? {
                guard let index = flight.seats.firstIndex(where: { $0.code == code && $0.isAvailable }) else {
                    return nil
                }
                flight.seats[index].isSelected = true
                selectedSeat = flight.seats[index]
                return selectedSeat
            }
        }

        try given("a flight with available seats") {
            SeatMap(
                flight: Flight(
                    number: "UA123",
                    seats: [
                        Seat(code: "12A", isSelected: false, isAvailable: true),
                        Seat(code: "12B", isSelected: false, isAvailable: true),
                        Seat(code: "12C", isSelected: false, isAvailable: false)
                    ]
                )
            )
        }
        .when("user selects seat 12A") { seatMap in
            var mutableSeatMap = seatMap
            let selected = mutableSeatMap.selectSeat("12A")
            return (seatMap: mutableSeatMap, selected: selected)
        }
        .then("seat 12A is marked as selected") { result, context in
            #expect(result.selected != nil, "Seat should be selected")
            #expect(result.selected?.code == "12A")
            #expect(result.selected?.isSelected == true)
        }
    }

    // MARK: - Multiple Scenarios in Sequence

    @Test("multiple scenarios run sequentially")
    func multipleScenariosInSequence() throws {
        struct Counter: Sendable {
            var value: Int

            mutating func increment() -> Int {
                value += 1
                return value
            }

            mutating func decrement() -> Int {
                value -= 1
                return value
            }
        }

        // Scenario 1: Increment
        try given("a counter at 0") {
            Counter(value: 0)
        }
        .when("we increment") { counter in
            var c = counter
            return c.increment()
        }
        .then("value is 1") { result, _ in
            #expect(result == 1)
        }

        // Scenario 2: Decrement
        try given("a counter at 10") {
            Counter(value: 10)
        }
        .when("we decrement") { counter in
            var c = counter
            return c.decrement()
        }
        .then("value is 9") { result, _ in
            #expect(result == 9)
        }

        // Scenario 3: Multiple operations
        try given("a counter at 5") {
            Counter(value: 5)
        }
        .when("we increment twice") { counter in
            var c = counter
            _ = c.increment()
            return c.increment()
        }
        .then("value is 7") { result, _ in
            #expect(result == 7)
        }
    }

    // MARK: - #expect Macro Integration

    @Test("#expect macro works inside then")
    func expectMacroIntegration() throws {
        try given("a list of numbers") {
            [1, 2, 3, 4, 5]
        }
        .when("we filter even numbers") { numbers in
            numbers.filter { $0 % 2 == 0 }
        }
        .then("we get [2, 4]") { result, _ in
            #expect(result == [2, 4])
            #expect(result.count == 2)
            #expect(result.first == 2)
            #expect(result.last == 4)
        }
    }

    @Test("#expect with custom messages")
    func expectWithCustomMessages() throws {
        try given("a string") {
            "Hello, World!"
        }
        .when("we extract length") { string in
            string.count
        }
        .then("length is 13") { length, context in
            #expect(length == 13, "String 'Hello, World!' should have 13 characters")
        }
    }

    // MARK: - Edge Cases

    @Test("chain with void context")
    func chainWithVoidContext() throws {
        try given("no context needed") {
            ()
        }
        .when("we perform action") { _ in
            "done"
        }
        .then("action completed") { result, _ in
            #expect(result == "done")
        }
    }

    @Test("chain with optional result")
    func chainWithOptionalResult() throws {
        try given("a dictionary") {
            ["key": "value"]
        }
        .when("we lookup existing key") { dict in
            dict["key"]
        }
        .then("value is found") { result, _ in
            #expect(result == "value")
        }

        try given("a dictionary") {
            ["key": "value"]
        }
        .when("we lookup missing key") { dict in
            dict["missing"]
        }
        .then("value is nil") { result, _ in
            #expect(result == nil)
        }
    }

    @Test("chain with array transformations")
    func chainWithArrayTransformations() throws {
        struct Item: Sendable, Equatable {
            let id: Int
            let name: String
        }

        try given("a list of items") {
            [
                Item(id: 1, name: "Apple"),
                Item(id: 2, name: "Banana"),
                Item(id: 3, name: "Cherry")
            ]
        }
        .when("we map to names") { items in
            items.map(\.name)
        }
        .then("names are extracted") { names, _ in
            #expect(names == ["Apple", "Banana", "Cherry"])
        }
    }

    // MARK: - Async Integration

    @Test("async real-world scenario")
    func asyncRealWorldScenario() async throws {
        struct APIClient: Sendable {
            func fetchUser(id: Int) async -> (name: String, email: String) {
                // Simulate network delay
                try? await Task.sleep(nanoseconds: 1_000)
                return (name: "John Doe", email: "john@example.com")
            }
        }

        try await given("an API client") {
            APIClient()
        }
        .when("we fetch user 1") { client in
            await client.fetchUser(id: 1)
        }
        .then("user data is returned") { user, _ in
            #expect(user.name == "John Doe")
            #expect(user.email == "john@example.com")
        }
    }
}
