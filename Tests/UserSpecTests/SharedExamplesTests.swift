import Testing
@testable import UserSpec

// MARK: - Shared Examples Tests

@Suite("Shared Examples Tests")
struct SharedExamplesTests {

    init() {
        SharedExamples.reset()
    }

    @Test("define() registers shared example")
    func defineRegisters() {
        SharedExamples.define("test example") { (_: String) in }

        #expect(SharedExamples.registeredNames.contains("test example"))
    }

    @Test("run() executes shared example")
    func runExecutes() throws {
        var executed = false

        SharedExamples.define("executes") { (_: Void) in
            executed = true
        }

        try SharedExamples.run("executes", with: ())

        #expect(executed == true)
    }

    @Test("run() passes context to behavior")
    func runPassesContext() throws {
        var receivedValue = 0

        SharedExamples.define("receives context") { (value: Int) in
            receivedValue = value
        }

        try SharedExamples.run("receives context", with: 42)

        #expect(receivedValue == 42)
    }

    @Test("run() throws for unknown example")
    func runThrowsForUnknown() {
        #expect(throws: SharedExampleError.self) {
            try SharedExamples.run("nonexistent", with: ())
        }
    }

    @Test("reset() clears all examples")
    func resetClears() {
        SharedExamples.define("to be cleared") { (_: Void) in }
        #expect(SharedExamples.registeredNames.contains("to be cleared"))

        SharedExamples.reset()

        #expect(SharedExamples.registeredNames.isEmpty)
    }

    @Test("itBehavesLike() runs shared example")
    func itBehavesLikeRuns() throws {
        var executed = false

        SharedExamples.define("behaves like") { (_: Void) in
            executed = true
        }

        try itBehavesLike("behaves like", context: ())

        #expect(executed == true)
    }
}

// MARK: - Async Shared Examples Tests

@Suite("Async Shared Examples Tests")
struct AsyncSharedExamplesTests {

    init() {
        SharedExamples.reset()
    }

    @Test("defineAsync() registers async example")
    func defineAsyncRegisters() {
        SharedExamples.defineAsync("async example") { (_: String) async in }

        #expect(SharedExamples.registeredNames.contains("async example"))
    }

    @Test("runAsync() executes async example")
    func runAsyncExecutes() async throws {
        var executed = false

        SharedExamples.defineAsync("async executes") { (_: Void) async in
            try? await Task.sleep(nanoseconds: 1_000)
            executed = true
        }

        try await SharedExamples.runAsync("async executes", with: ())

        #expect(executed == true)
    }

    @Test("itBehavesLikeAsync() runs async example")
    func itBehavesLikeAsyncRuns() async throws {
        var executed = false

        SharedExamples.defineAsync("async behaves") { (_: Void) async in
            executed = true
        }

        try await itBehavesLikeAsync("async behaves", context: ())

        #expect(executed == true)
    }
}

// MARK: - SharedBehavior Protocol Tests

struct TestBehavior: SharedBehavior {
    var executed: UnsafeMutablePointer<Bool>

    func execute() throws {
        executed.pointee = true
    }
}

@Suite("SharedBehavior Protocol Tests")
struct SharedBehaviorProtocolTests {

    @Test("SharedBehavior execute() is called")
    func behaviorExecutes() throws {
        var executed = false

        try withUnsafeMutablePointer(to: &executed) { ptr in
            try TestBehavior(executed: ptr).execute()
        }

        #expect(executed == true)
    }
}
