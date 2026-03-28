import Testing
import Foundation
@testable import UserSpec

// MARK: - Test Reporter Tests

@Suite("Test Reporter Tests")
struct TestReporterTests {

    init() {
        TestReporter.shared.reset()
    }

    @Test("record() stores test result")
    func recordStoresResult() {
        let result = TestReporter.TestResult(
            userStory: "User Story",
            scenario: "Scenario",
            given: "given",
            when: "when",
            then: "then",
            passed: true,
            duration: 0.5
        )

        TestReporter.shared.record(result)
        let all = TestReporter.shared.allResults()

        #expect(all.count == 1)
        #expect(all[0].userStory == "User Story")
    }

    @Test("reset() clears all results")
    func resetClearsResults() {
        let result = TestReporter.TestResult(
            userStory: "Story",
            scenario: "Scenario",
            given: "g",
            when: "w",
            then: "t",
            passed: true,
            duration: 0.1
        )

        TestReporter.shared.record(result)
        TestReporter.shared.reset()

        #expect(TestReporter.shared.allResults().isEmpty)
    }

    @Test("statistics() calculates correctly")
    func statisticsCalculates() {
        TestReporter.shared.record(TestReporter.TestResult(
            userStory: "", scenario: "", given: "", when: "", then: "",
            passed: true, duration: 1.0
        ))
        TestReporter.shared.record(TestReporter.TestResult(
            userStory: "", scenario: "", given: "", when: "", then: "",
            passed: true, duration: 2.0
        ))
        TestReporter.shared.record(TestReporter.TestResult(
            userStory: "", scenario: "", given: "", when: "", then: "",
            passed: false, duration: 0.5
        ))

        let stats = TestReporter.shared.statistics()

        #expect(stats.total == 3)
        #expect(stats.passed == 2)
        #expect(stats.failed == 1)
        #expect(stats.duration == 3.5)
    }

    @Test("passRate calculates percentage")
    func passRateCalculates() {
        TestReporter.shared.record(TestReporter.TestResult(
            userStory: "", scenario: "", given: "", when: "", then: "",
            passed: true, duration: 0.1
        ))
        TestReporter.shared.record(TestReporter.TestResult(
            userStory: "", scenario: "", given: "", when: "", then: "",
            passed: false, duration: 0.1
        ))

        let stats = TestReporter.shared.statistics()

        #expect(stats.passRate == 50.0)
    }

    @Test("passRate is zero when no tests")
    func passRateZeroWhenEmpty() {
        let stats = TestReporter.shared.statistics()

        #expect(stats.passRate == 0.0)
    }
}

// MARK: - HTML Report Generator Tests

@Suite("HTML Report Generator Tests")
struct HTMLReportGeneratorTests {

    @Test("generateHTML() includes title")
    func generateHTMLIncludesTitle() {
        let results: [TestReporter.TestResult] = []

        let html = ReportGenerator.generateHTML(from: results, title: "My Test Report")

        #expect(html.contains("<title>My Test Report</title>"))
        #expect(html.contains("<h1>My Test Report</h1>"))
    }

    @Test("generateHTML() includes statistics")
    func generateHTMLIncludesStatistics() {
        let results = [
            TestReporter.TestResult(
                userStory: "Story", scenario: "Test", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
            TestReporter.TestResult(
                userStory: "Story", scenario: "Test 2", given: "g", when: "w", then: "t",
                passed: false, duration: 0.2, errorMessage: "Failed"
            ),
        ]

        let html = ReportGenerator.generateHTML(from: results)

        #expect(html.contains("2</div>")) // Total
        #expect(html.contains("1</div>")) // Passed/Failed counts
    }

    @Test("generateHTML() groups by user story")
    func generateHTMLGroupsByStory() {
        let results = [
            TestReporter.TestResult(
                userStory: "Cart", scenario: "Add item", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
            TestReporter.TestResult(
                userStory: "Checkout", scenario: "Pay", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
        ]

        let html = ReportGenerator.generateHTML(from: results)

        #expect(html.contains("Cart"))
        #expect(html.contains("Checkout"))
    }

    @Test("generateHTML() escapes HTML in content")
    func generateHTMLEscapesContent() {
        let results = [
            TestReporter.TestResult(
                userStory: "Test <script>", scenario: "XSS & Test", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
        ]

        let html = ReportGenerator.generateHTML(from: results)

        #expect(html.contains("&lt;script&gt;"))
        #expect(html.contains("XSS &amp; Test"))
    }

    @Test("generateHTML() shows error messages for failed tests")
    func generateHTMLShowsErrors() {
        let results = [
            TestReporter.TestResult(
                userStory: "Story", scenario: "Failed test", given: "g", when: "w", then: "t",
                passed: false, duration: 0.1, errorMessage: "Expected 1 but got 2"
            ),
        ]

        let html = ReportGenerator.generateHTML(from: results)

        #expect(html.contains("Expected 1 but got 2"))
        #expect(html.contains("class=\"error\""))
    }
}

// MARK: - Gherkin Report Generator Tests

@Suite("Gherkin Report Generator Tests")
struct GherkinReportGeneratorTests {

    @Test("generateGherkin() creates feature per story")
    func generateGherkinCreatesFeatures() {
        let results = [
            TestReporter.TestResult(
                userStory: "Shopping Cart", scenario: "Add item", given: "empty cart", when: "add product", then: "cart has item",
                passed: true, duration: 0.1
            ),
        ]

        let gherkin = ReportGenerator.generateGherkin(from: results)

        #expect(gherkin.contains("Feature: Shopping Cart"))
        #expect(gherkin.contains("Scenario: Add item"))
        #expect(gherkin.contains("Given empty cart"))
        #expect(gherkin.contains("When add product"))
        #expect(gherkin.contains("Then cart has item"))
    }

    @Test("generateGherkin() shows pass/fail status")
    func generateGherkinShowsStatus() {
        let results = [
            TestReporter.TestResult(
                userStory: "Test", scenario: "Passing", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
            TestReporter.TestResult(
                userStory: "Test", scenario: "Failing", given: "g", when: "w", then: "t",
                passed: false, duration: 0.1
            ),
        ]

        let gherkin = ReportGenerator.generateGherkin(from: results)

        #expect(gherkin.contains("✓ Scenario: Passing"))
        #expect(gherkin.contains("✗ Scenario: Failing"))
    }

    @Test("generateGherkin() includes error as comment")
    func generateGherkinIncludesError() {
        let results = [
            TestReporter.TestResult(
                userStory: "Test", scenario: "Failed", given: "g", when: "w", then: "t",
                passed: false, duration: 0.1, errorMessage: "Assertion failed"
            ),
        ]

        let gherkin = ReportGenerator.generateGherkin(from: results)

        #expect(gherkin.contains("# Error: Assertion failed"))
    }
}

// MARK: - Console Report Generator Tests

@Suite("Console Report Generator Tests")
struct ConsoleReportGeneratorTests {

    @Test("generateConsole() includes header")
    func generateConsoleIncludesHeader() {
        let results: [TestReporter.TestResult] = []

        let console = ReportGenerator.generateConsole(from: results)

        #expect(console.contains("USERSPEC TEST REPORT"))
    }

    @Test("generateConsole() shows pass/fail icons")
    func generateConsoleShowsIcons() {
        let results = [
            TestReporter.TestResult(
                userStory: "Test", scenario: "Pass", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
            TestReporter.TestResult(
                userStory: "Test", scenario: "Fail", given: "g", when: "w", then: "t",
                passed: false, duration: 0.1
            ),
        ]

        let console = ReportGenerator.generateConsole(from: results)

        #expect(console.contains("✅"))
        #expect(console.contains("❌"))
    }

    @Test("generateConsole() shows statistics summary")
    func generateConsoleShowsStats() {
        let results = [
            TestReporter.TestResult(
                userStory: "Test", scenario: "Test 1", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
            TestReporter.TestResult(
                userStory: "Test", scenario: "Test 2", given: "g", when: "w", then: "t",
                passed: true, duration: 0.1
            ),
        ]

        let console = ReportGenerator.generateConsole(from: results)

        #expect(console.contains("Total: 2"))
        #expect(console.contains("Passed: 2"))
        #expect(console.contains("Failed: 0"))
        #expect(console.contains("100.0%"))
    }
}
