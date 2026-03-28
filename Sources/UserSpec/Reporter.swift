import Foundation

// MARK: - Test Reporter
//
// Generates test reports in various formats (HTML, Gherkin, Console).

/// Records test results for report generation.
public final class TestReporter: @unchecked Sendable {

    /// Shared reporter instance.
    public static let shared = TestReporter()

    /// Recorded test results.
    private var results: [TestResult] = []
    private let lock = NSLock()

    private init() {}

    /// A recorded test result.
    public struct TestResult: Sendable {
        public let userStory: String
        public let scenario: String
        public let given: String
        public let when: String
        public let then: String
        public let passed: Bool
        public let duration: TimeInterval
        public let errorMessage: String?
        public let timestamp: Date

        public init(
            userStory: String,
            scenario: String,
            given: String,
            when: String,
            then: String,
            passed: Bool,
            duration: TimeInterval,
            errorMessage: String? = nil,
            timestamp: Date = Date()
        ) {
            self.userStory = userStory
            self.scenario = scenario
            self.given = given
            self.when = when
            self.then = then
            self.passed = passed
            self.duration = duration
            self.errorMessage = errorMessage
            self.timestamp = timestamp
        }
    }

    // MARK: - Recording

    /// Records a test result.
    public func record(_ result: TestResult) {
        lock.lock()
        defer { lock.unlock() }
        results.append(result)
    }

    /// Records a test result from step context.
    public func record(
        userStory: String = "",
        scenario: String = "",
        context: StepContext,
        passed: Bool,
        duration: TimeInterval,
        errorMessage: String? = nil
    ) {
        record(TestResult(
            userStory: userStory,
            scenario: scenario,
            given: context.givenDescription,
            when: context.whenDescription,
            then: context.thenDescription,
            passed: passed,
            duration: duration,
            errorMessage: errorMessage
        ))
    }

    /// Clears all recorded results.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        results.removeAll()
    }

    /// Returns all recorded results.
    public func allResults() -> [TestResult] {
        lock.lock()
        defer { lock.unlock() }
        return results
    }

    // MARK: - Statistics

    /// Summary statistics for recorded tests.
    public struct Statistics: Sendable {
        public let total: Int
        public let passed: Int
        public let failed: Int
        public let duration: TimeInterval

        public var passRate: Double {
            total > 0 ? Double(passed) / Double(total) * 100 : 0
        }
    }

    /// Returns statistics for recorded tests.
    public func statistics() -> Statistics {
        let all = allResults()
        return Statistics(
            total: all.count,
            passed: all.filter(\.passed).count,
            failed: all.filter { !$0.passed }.count,
            duration: all.reduce(0) { $0 + $1.duration }
        )
    }
}

// MARK: - Report Generators

/// Generates test reports in various formats.
public enum ReportGenerator {

    // MARK: - HTML Report

    /// Generates an HTML report from test results.
    public static func generateHTML(
        from results: [TestReporter.TestResult],
        title: String = "UserSpec Test Report"
    ) -> String {
        let stats = calculateStats(results)
        let groupedByStory = Dictionary(grouping: results) { $0.userStory }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(title)</title>
            <style>
                * { box-sizing: border-box; margin: 0; padding: 0; }
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; padding: 20px; background: #f5f5f5; }
                .container { max-width: 1200px; margin: 0 auto; }
                h1 { color: #333; margin-bottom: 20px; }
                .summary { display: flex; gap: 20px; margin-bottom: 30px; }
                .stat-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); flex: 1; text-align: center; }
                .stat-card.passed { border-left: 4px solid #4CAF50; }
                .stat-card.failed { border-left: 4px solid #f44336; }
                .stat-card.total { border-left: 4px solid #2196F3; }
                .stat-number { font-size: 2em; font-weight: bold; }
                .stat-label { color: #666; }
                .story { background: white; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); overflow: hidden; }
                .story-header { background: #333; color: white; padding: 15px 20px; font-weight: 500; }
                .scenario { border-bottom: 1px solid #eee; }
                .scenario:last-child { border-bottom: none; }
                .scenario-header { padding: 15px 20px; display: flex; align-items: center; gap: 10px; cursor: pointer; }
                .scenario-header:hover { background: #f9f9f9; }
                .status { width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px; }
                .status.passed { background: #4CAF50; color: white; }
                .status.failed { background: #f44336; color: white; }
                .scenario-name { flex: 1; font-weight: 500; }
                .duration { color: #999; font-size: 0.9em; }
                .steps { padding: 0 20px 20px 54px; display: none; }
                .scenario.expanded .steps { display: block; }
                .step { margin: 8px 0; padding: 8px 12px; background: #f9f9f9; border-radius: 4px; }
                .step-type { font-weight: 600; color: #666; margin-right: 8px; }
                .step-type.given { color: #2196F3; }
                .step-type.when { color: #FF9800; }
                .step-type.then { color: #4CAF50; }
                .error { background: #ffebee; color: #c62828; padding: 10px; border-radius: 4px; margin-top: 10px; font-family: monospace; font-size: 0.9em; }
                .timestamp { color: #999; font-size: 0.8em; margin-top: 20px; text-align: center; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>\(title)</h1>
                <div class="summary">
                    <div class="stat-card total">
                        <div class="stat-number">\(stats.total)</div>
                        <div class="stat-label">Total Tests</div>
                    </div>
                    <div class="stat-card passed">
                        <div class="stat-number">\(stats.passed)</div>
                        <div class="stat-label">Passed</div>
                    </div>
                    <div class="stat-card failed">
                        <div class="stat-number">\(stats.failed)</div>
                        <div class="stat-label">Failed</div>
                    </div>
                </div>
                \(generateStoriesHTML(groupedByStory))
                <p class="timestamp">Generated on \(ISO8601DateFormatter().string(from: Date()))</p>
            </div>
            <script>
                document.querySelectorAll('.scenario-header').forEach(header => {
                    header.addEventListener('click', () => {
                        header.parentElement.classList.toggle('expanded');
                    });
                });
            </script>
        </body>
        </html>
        """
    }

    private static func generateStoriesHTML(_ grouped: [String: [TestReporter.TestResult]]) -> String {
        var html = ""
        for (story, results) in grouped.sorted(by: { $0.key < $1.key }) {
            let storyTitle = story.isEmpty ? "Uncategorized" : story
            html += """
            <div class="story">
                <div class="story-header">\(escapeHTML(storyTitle))</div>
                \(results.map { generateScenarioHTML($0) }.joined())
            </div>
            """
        }
        return html
    }

    private static func generateScenarioHTML(_ result: TestReporter.TestResult) -> String {
        let statusIcon = result.passed ? "✓" : "✗"
        let statusClass = result.passed ? "passed" : "failed"
        let durationStr = String(format: "%.2fs", result.duration)
        let errorHTML = result.errorMessage.map { "<div class=\"error\">\(escapeHTML($0))</div>" } ?? ""

        return """
        <div class="scenario">
            <div class="scenario-header">
                <span class="status \(statusClass)">\(statusIcon)</span>
                <span class="scenario-name">\(escapeHTML(result.scenario.isEmpty ? "Test" : result.scenario))</span>
                <span class="duration">\(durationStr)</span>
            </div>
            <div class="steps">
                <div class="step"><span class="step-type given">Given</span>\(escapeHTML(result.given))</div>
                <div class="step"><span class="step-type when">When</span>\(escapeHTML(result.when))</div>
                <div class="step"><span class="step-type then">Then</span>\(escapeHTML(result.then))</div>
                \(errorHTML)
            </div>
        </div>
        """
    }

    // MARK: - Gherkin Report

    /// Generates a Gherkin-formatted report from test results.
    public static func generateGherkin(from results: [TestReporter.TestResult]) -> String {
        let grouped = Dictionary(grouping: results) { $0.userStory }
        var gherkin = ""

        for (story, scenarios) in grouped.sorted(by: { $0.key < $1.key }) {
            gherkin += "Feature: \(story.isEmpty ? "Tests" : story)\n\n"

            for result in scenarios {
                let status = result.passed ? "✓" : "✗"
                gherkin += "  \(status) Scenario: \(result.scenario.isEmpty ? "Test" : result.scenario)\n"
                gherkin += "    Given \(result.given)\n"
                gherkin += "    When \(result.when)\n"
                gherkin += "    Then \(result.then)\n"
                if let error = result.errorMessage {
                    gherkin += "    # Error: \(error)\n"
                }
                gherkin += "\n"
            }
        }

        return gherkin
    }

    // MARK: - Console Report

    /// Generates a console-formatted report from test results.
    public static func generateConsole(from results: [TestReporter.TestResult]) -> String {
        let stats = calculateStats(results)
        var output = "\n"
        output += "═══════════════════════════════════════════════════════════════\n"
        output += "                     USERSPEC TEST REPORT                      \n"
        output += "═══════════════════════════════════════════════════════════════\n\n"

        let grouped = Dictionary(grouping: results) { $0.userStory }

        for (story, scenarios) in grouped.sorted(by: { $0.key < $1.key }) {
            output += "📖 \(story.isEmpty ? "Tests" : story)\n"
            output += String(repeating: "─", count: 60) + "\n"

            for result in scenarios {
                let icon = result.passed ? "✅" : "❌"
                output += "\n  \(icon) \(result.scenario.isEmpty ? "Test" : result.scenario)\n"
                output += "     Given: \(result.given)\n"
                output += "     When:  \(result.when)\n"
                output += "     Then:  \(result.then)\n"
                if let error = result.errorMessage {
                    output += "     ⚠️  \(error)\n"
                }
            }
            output += "\n"
        }

        output += "═══════════════════════════════════════════════════════════════\n"
        output += "  Total: \(stats.total) | Passed: \(stats.passed) | Failed: \(stats.failed) | "
        output += String(format: "%.1f%%", stats.passRate) + " pass rate\n"
        output += "═══════════════════════════════════════════════════════════════\n"

        return output
    }

    // MARK: - Helpers

    private static func calculateStats(_ results: [TestReporter.TestResult]) -> (total: Int, passed: Int, failed: Int, passRate: Double) {
        let total = results.count
        let passed = results.filter(\.passed).count
        let failed = total - passed
        let passRate = total > 0 ? Double(passed) / Double(total) * 100 : 0
        return (total, passed, failed, passRate)
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - File Writing

extension ReportGenerator {

    /// Writes an HTML report to a file.
    public static func writeHTML(
        from results: [TestReporter.TestResult],
        to path: String,
        title: String = "UserSpec Test Report"
    ) throws {
        let html = generateHTML(from: results, title: title)
        try html.write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// Writes a Gherkin report to a file.
    public static func writeGherkin(
        from results: [TestReporter.TestResult],
        to path: String
    ) throws {
        let gherkin = generateGherkin(from: results)
        try gherkin.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
