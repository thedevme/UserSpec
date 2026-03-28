import Testing
@testable import UserSpec

@Suite("Async Step Tests")
struct AsyncStepTests {

    @Test("async given awaits setup")
    func asyncGivenAwaitsSetup() async throws {
        // Verify async setup completes by checking result flows through
        try await given("async setup") {
            try await Task.sleep(nanoseconds: 1_000)
            return "setup-complete"
        }
        .when("action") { context in
            context + "-action"
        }
        .then("assertion") { result, _ in
            #expect(result == "setup-complete-action")
        }
    }

    @Test("async when awaits action")
    func asyncWhenAwaitsAction() async throws {
        try await given("setup") {
            "context"
        }
        .when("async action") { context in
            try await Task.sleep(nanoseconds: 1_000)
            return "action-complete"
        }
        .then("assertion") { result, _ in
            #expect(result == "action-complete")
        }
    }

    @Test("async then awaits assertion")
    func asyncThenAwaitsAssertion() async throws {
        try await given("setup") {
            "context"
        }
        .when("action") { context in
            "result"
        }
        .then("async assertion") { result, _ in
            try await Task.sleep(nanoseconds: 1_000)
            #expect(result == "result")
        }
    }

    @Test("mixed sync setup with async action works")
    func mixedSyncAsyncChain() async throws {
        // Track execution via string concatenation
        try await given("sync setup") {
            "given"
        }
        .when("async action") { order in
            try await Task.sleep(nanoseconds: 1_000)
            return order + ",when"
        }
        .then("result is correct") { order, _ in
            #expect(order == "given,when")
        }
    }

    @Test("async chain with throws propagates correctly")
    func asyncChainWithThrows() async {
        struct AsyncError: Error, Equatable {}

        await #expect(throws: AsyncError.self) {
            try await given("setup") {
                "context"
            }
            .when("throwing async action") { (_: String) async throws -> String in
                try await Task.sleep(nanoseconds: 1_000)
                throw AsyncError()
            }
            .then("assertion") { _, _ in }
        }
    }

    @Test("async given with throwing setup propagates error")
    func asyncGivenThrows() async {
        struct SetupError: Error, Equatable {}

        await #expect(throws: SetupError.self) {
            try await given("failing async setup") { () async throws -> String in
                try await Task.sleep(nanoseconds: 1_000)
                throw SetupError()
            }
            .when("action") { context in
                context
            }
            .then("assertion") { _, _ in }
        }
    }

    @Test("full async chain executes in order")
    func fullAsyncChainOrder() async throws {
        // Track order via string concatenation
        try await given("step 1") {
            try await Task.sleep(nanoseconds: 1_000)
            return "1"
        }
        .when("step 2") { order in
            try await Task.sleep(nanoseconds: 1_000)
            return order + ",2"
        }
        .then("step 3") { order, _ in
            try await Task.sleep(nanoseconds: 1_000)
            #expect(order == "1,2")
        }
    }

    @Test("async step stores description")
    func asyncStepStoresDescription() {
        let step = AsyncGivenStep("async operation") {
            return "value"
        }

        #expect(step.description == "async operation")
    }

    @Test("async when step preserves given description")
    func asyncWhenPreservesGivenDescription() {
        let whenStep = AsyncGivenStep("the given") {
            return "context"
        }
        .when("the when") { context in
            context
        }

        #expect(whenStep.givenDescription == "the given")
        #expect(whenStep.description == "the when")
    }
}
