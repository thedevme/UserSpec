import Testing
@testable import UserSpec

#if canImport(XCTest)

@Suite("UI Testing Tests")
struct UITestingTests {

    // MARK: - Mock App for Testing

    struct MockApp: Sendable {
        var isLaunched: Bool = false
        var tappedButtons: [String] = []
        var visibleElements: [String] = []

        mutating func launch() {
            isLaunched = true
            visibleElements = ["LoginButton", "WelcomeText"]
        }

        mutating func tap(_ button: String) {
            tappedButtons.append(button)
            if button == "LoginButton" {
                visibleElements = ["HomeScreen", "LogoutButton"]
            }
        }

        func elementExists(_ identifier: String) -> Bool {
            visibleElements.contains(identifier)
        }
    }

    // MARK: - UIGivenStep Tests

    @Test("givenApp creates step with description")
    func givenAppCreatesStepWithDescription() {
        let step = givenApp("app is launched") {
            MockApp()
        }

        #expect(step.description == "app is launched")
    }

    @Test("givenApp captures setup closure")
    func givenAppCapturesSetupClosure() throws {
        var app = MockApp()

        try givenApp("app is launched") {
            app.launch()
            return app
        }
        .whenTap("login button") { app in
            app
        }
        .thenSee("home screen") { _, _ in }

        #expect(app.isLaunched == true)
    }

    // MARK: - UIWhenStep Tests

    @Test("whenTap stores description")
    func whenTapStoresDescription() {
        let whenStep = givenApp("setup") { MockApp() }
            .whenTap("login button") { app in app }

        #expect(whenStep.description == "login button")
        #expect(whenStep.givenDescription == "setup")
    }

    @Test("when (generic) stores description")
    func whenGenericStoresDescription() {
        let whenStep = givenApp("setup") { MockApp() }
            .when("user scrolls down") { app in app }

        #expect(whenStep.description == "user scrolls down")
    }

    // MARK: - Full Chain Tests

    @Test("full UI chain executes in order")
    func fullUIChainExecutesInOrder() throws {
        var executionOrder: [String] = []

        try givenApp("app is launched") {
            executionOrder.append("given")
            return MockApp()
        }
        .whenTap("login button") { app in
            executionOrder.append("when")
            return app
        }
        .thenSee("home screen") { _, _ in
            executionOrder.append("then")
        }

        #expect(executionOrder == ["given", "when", "then"])
    }

    @Test("thenSee receives result from action")
    func thenSeeReceivesResultFromAction() throws {
        try givenApp("app is launched") {
            var app = MockApp()
            app.launch()
            return app
        }
        .whenTap("login button") { app in
            var mutableApp = app
            mutableApp.tap("LoginButton")
            return mutableApp
        }
        .thenSee("home screen is visible") { app, _ in
            #expect(app.elementExists("HomeScreen"))
            #expect(app.tappedButtons.contains("LoginButton"))
        }
    }

    @Test("then works as alias for thenSee")
    func thenWorksAsAliasForThenSee() throws {
        try givenApp("app setup") {
            MockApp()
        }
        .whenTap("some button") { app in
            app
        }
        .then("expected state") { _, context in
            #expect(context.givenDescription == "app setup")
            #expect(context.whenDescription == "some button")
            #expect(context.thenDescription == "expected state")
        }
    }

    @Test("context is passed to thenSee")
    func contextIsPassedToThenSee() throws {
        try givenApp("the given description") {
            MockApp()
        }
        .whenTap("the when description") { app in
            app
        }
        .thenSee("the then description") { _, context in
            #expect(context.givenDescription == "the given description")
            #expect(context.whenDescription == "the when description")
            #expect(context.thenDescription == "the then description")
        }
    }

    // MARK: - Error Propagation Tests

    @Test("givenApp propagates setup errors")
    func givenAppPropagatesSetupErrors() {
        struct SetupError: Error, Equatable {}

        #expect(throws: SetupError.self) {
            try givenApp("failing setup") { () throws -> MockApp in
                throw SetupError()
            }
            .whenTap("button") { app in app }
            .thenSee("result") { _, _ in }
        }
    }

    @Test("whenTap propagates action errors")
    func whenTapPropagatesActionErrors() {
        struct ActionError: Error, Equatable {}

        #expect(throws: ActionError.self) {
            try givenApp("setup") {
                MockApp()
            }
            .whenTap("failing action") { (_: MockApp) throws -> MockApp in
                throw ActionError()
            }
            .thenSee("result") { _, _ in }
        }
    }

    // MARK: - Multiple Chains Tests

    @Test("multiple UI chains are independent")
    func multipleUIChainsAreIndependent() throws {
        // First chain
        try givenApp("first app state") {
            var app = MockApp()
            app.visibleElements = ["Screen1"]
            return app
        }
        .whenTap("button 1") { app in
            app
        }
        .thenSee("screen 1") { app, _ in
            #expect(app.elementExists("Screen1"))
        }

        // Second chain - completely independent
        try givenApp("second app state") {
            var app = MockApp()
            app.visibleElements = ["Screen2"]
            return app
        }
        .whenTap("button 2") { app in
            app
        }
        .thenSee("screen 2") { app, _ in
            #expect(app.elementExists("Screen2"))
        }
    }

    // MARK: - Async UI Tests

    @Test("async givenApp awaits setup")
    func asyncGivenAppAwaitsSetup() async throws {
        try await givenApp("async app launch") {
            try await Task.sleep(nanoseconds: 1_000)
            var app = MockApp()
            app.launch()
            return app
        }
        .whenTap("button") { app in
            app
        }
        .thenSee("launched state") { app, _ in
            #expect(app.isLaunched == true)
        }
    }

    @Test("async whenTap awaits action")
    func asyncWhenTapAwaitsAction() async throws {
        try await givenApp("setup") {
            MockApp()
        }
        .whenTap("async tap") { app in
            try await Task.sleep(nanoseconds: 1_000)
            var mutableApp = app
            mutableApp.tap("Button")
            return mutableApp
        }
        .thenSee("tapped") { app, _ in
            #expect(app.tappedButtons.contains("Button"))
        }
    }

    @Test("async thenSee awaits assertion")
    func asyncThenSeeAwaitsAssertion() async throws {
        try await givenApp("setup") {
            MockApp()
        }
        .whenTap("tap") { app in
            app
        }
        .thenSee("async assertion") { _, _ in
            try await Task.sleep(nanoseconds: 1_000)
            // Assertion completed successfully
        }
    }

    @Test("full async UI chain executes in order")
    func fullAsyncUIChainExecutesInOrder() async throws {
        try await givenApp("step 1") {
            try await Task.sleep(nanoseconds: 1_000)
            return "1"
        }
        .whenTap("step 2") { order in
            try await Task.sleep(nanoseconds: 1_000)
            return order + ",2"
        }
        .thenSee("step 3") { order, _ in
            try await Task.sleep(nanoseconds: 1_000)
            #expect(order == "1,2")
        }
    }
}

#endif
