import Foundation
import Darwin
import os.lock

/// RSpec-style documentation format reporter for UserSpec scenarios.
///
/// This reporter automatically prints scenarios in RSpec documentation format
/// at the end of test execution.
///
/// Output format:
/// ```
/// As a traveler, I want to select my seat so I can sit comfortably
///   ✓ Economy user can select an economy seat
///   ✓ Economy user cannot select a business seat
///   ✗ Business user can select a business seat
///
/// 3 scenarios, 1 failure
/// ```
public final class RSpecReporter: Sendable {
    public static let shared = RSpecReporter()

    public static var isEnabled: Bool {
        true
    }

    private let lock: OSAllocatedUnfairLock<State>

    private struct State {
        var scenarios: [String: ScenarioState] = [:]
    }

    private struct ScenarioState {
        let story: String
        let name: String
        var status: Status
        var errorMessage: String?

        enum Status {
            case inProgress
            case completed(passed: Bool)
        }
    }

    private init() {
        lock = OSAllocatedUnfairLock(initialState: State())
    }

    /// Registers the start of a scenario.
    ///
    /// This is called when `given()` executes, ensuring scenarios that fail
    /// before reaching `.then()` still appear in the output as incomplete.
    ///
    /// - Parameters:
    ///   - name: The scenario name (from @Test display name)
    ///   - story: The user story description
    public func registerScenarioStart(_ name: String, story: String) {
        lock.withLock { state in
            state.scenarios[name] = ScenarioState(
                story: story,
                name: name,
                status: .inProgress,
                errorMessage: nil
            )
        }
    }

    /// Marks a scenario as complete.
    ///
    /// This is called when `.then()` finishes, whether it passes or fails.
    ///
    /// - Parameters:
    ///   - name: The scenario name
    ///   - passed: Whether the scenario passed
    ///   - error: The error message if it failed
    public func markScenarioComplete(_ name: String, passed: Bool, error: String?) {
        lock.withLock { state in
            state.scenarios[name]?.status = .completed(passed: passed)
            state.scenarios[name]?.errorMessage = error
        }
    }

    /// Prints the RSpec-format report.
    ///
    /// Called automatically at process exit via atexit handler.
    /// Groups scenarios by story, prints ✓/✗ with color (if TTY),
    /// and shows a summary line.
    public func printReport() {
        let scenarios = lock.withLock { $0.scenarios }

        guard !scenarios.isEmpty else { return }

        // Group by story
        var storiesMap: [String: [ScenarioState]] = [:]
        for scenario in scenarios.values {
            storiesMap[scenario.story, default: []].append(scenario)
        }

        // Print each story
        var totalScenarios = 0
        var totalFailures = 0

        for (story, storyScenarios) in storiesMap.sorted(by: { $0.key < $1.key }) {
            print("\n\(story)")

            for scenario in storyScenarios.sorted(by: { $0.name < $1.name }) {
                totalScenarios += 1

                switch scenario.status {
                case .completed(let passed):
                    if passed {
                        print("  \(colorize("✓", color: .green)) \(scenario.name)")
                    } else {
                        print("  \(colorize("✗", color: .red)) \(scenario.name)")
                        totalFailures += 1
                    }
                case .inProgress:
                    print("  \(colorize("✗", color: .red)) \(scenario.name) (incomplete)")
                    totalFailures += 1
                }
            }
        }

        // Summary
        let failureText = totalFailures == 1 ? "1 failure" : "\(totalFailures) failures"
        print("\n\(totalScenarios) scenarios, \(failureText)\n")
    }

    private func isTTY() -> Bool {
        isatty(STDOUT_FILENO) != 0
    }

    private func colorize(_ text: String, color: ANSIColor) -> String {
        guard isTTY() else { return text }
        return "\(color.code)\(text)\(ANSIColor.reset)"
    }

    private enum ANSIColor {
        case green, red

        var code: String {
            switch self {
            case .green: return "\u{001B}[32m"
            case .red: return "\u{001B}[31m"
            }
        }

        static let reset = "\u{001B}[0m"
    }
}

// MARK: - Bootstrap

/// Ensures atexit handler is registered when RSpec reporting is enabled.
/// This is called from given() on first use.
func ensureRSpecReporterBootstrapped() {
    _ = RSpecReporterBootstrap.shared
}

/// Bootstrap class that registers the atexit handler.
private final class RSpecReporterBootstrap: @unchecked Sendable {
    static let shared = RSpecReporterBootstrap()

    init() {
        guard RSpecReporter.isEnabled else { return }
        Darwin.atexit {
            RSpecReporter.shared.printReport()
        }
    }
}
