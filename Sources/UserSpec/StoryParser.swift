import Foundation

// MARK: - Story Parser
//
// Converts plain text user stories and scenarios into Swift test stubs.

/// Parses plain text user stories into structured data and Swift code.
///
/// ## Supported Formats
///
/// ```
/// As a [role], I want [action] so that [benefit]
///
/// Scenario: [description]
/// Given [context]
/// When [action]
/// Then [expected outcome]
/// ```
///
/// ## Example
///
/// ```swift
/// let text = """
/// As a shopper, I want to add items to cart so that I can purchase later
///
/// Scenario: Adding in-stock item
/// Given an empty cart
/// When user adds a product
/// Then cart contains one item
/// """
///
/// let story = StoryParser.parse(text)
/// let code = StoryParser.generateSwift(from: story)
/// ```
public enum StoryParser {

    // MARK: - Parsed Types

    /// A parsed user story with scenarios.
    public struct ParsedStory: Sendable, Equatable {
        public let role: String
        public let action: String
        public let benefit: String
        public let scenarios: [ParsedScenario]

        public var userStoryText: String {
            "As a \(role), I want \(action) so that \(benefit)"
        }
    }

    /// A parsed scenario with Given/When/Then steps.
    public struct ParsedScenario: Sendable, Equatable {
        public let name: String
        public let given: String
        public let when: String
        public let then: String
    }

    // MARK: - Parsing

    /// Parses a plain text story into structured data.
    ///
    /// - Parameter text: The plain text user story.
    /// - Returns: A parsed story, or nil if parsing fails.
    public static func parse(_ text: String) -> ParsedStory? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let storyLine = lines.first(where: { $0.lowercased().hasPrefix("as a") }) else {
            return nil
        }

        guard let (role, action, benefit) = parseUserStoryLine(storyLine) else {
            return nil
        }

        let scenarios = parseScenarios(from: lines)

        return ParsedStory(
            role: role,
            action: action,
            benefit: benefit,
            scenarios: scenarios
        )
    }

    /// Parses multiple stories from text (separated by blank lines).
    public static func parseMultiple(_ text: String) -> [ParsedStory] {
        let blocks = text.components(separatedBy: "\n\n\n")
        return blocks.compactMap { parse($0) }
    }

    // MARK: - Code Generation

    /// Generates Swift test code from a parsed story.
    ///
    /// - Parameters:
    ///   - story: The parsed story.
    ///   - moduleName: Optional module name to import.
    /// - Returns: Swift source code as a string.
    public static func generateSwift(
        from story: ParsedStory,
        moduleName: String? = nil
    ) -> String {
        var code = """
        import Testing
        import UserSpec
        """

        if let module = moduleName {
            code += "\n@testable import \(module)"
        }

        let structName = generateStructName(from: story)

        code += """


        @UserStory("\(story.userStoryText)")
        struct \(structName)Spec {
        """

        for scenario in story.scenarios {
            let funcName = generateFunctionName(from: scenario.name)
            code += """


            @Test
            @Scenario("\(scenario.name)")
            func \(funcName)() throws {
                try given("\(scenario.given)") {
                    // TODO: Setup context
                    <#Context#>()
                }
                .when("\(scenario.when)") { context in
                    // TODO: Perform action
                    <#Result#>
                }
                .then("\(scenario.then)") { result, stepContext in
                    // TODO: Assert expectations
                    #expect(<#condition#>)
                }
            }
        """
        }

        code += "\n}\n"

        return code
    }

    /// Generates a Gherkin-formatted string from a parsed story.
    public static func generateGherkin(from story: ParsedStory) -> String {
        var gherkin = "Feature: \(story.action.capitalized)\n"
        gherkin += "  \(story.userStoryText)\n"

        for scenario in story.scenarios {
            gherkin += "\n  Scenario: \(scenario.name)\n"
            gherkin += "    Given \(scenario.given)\n"
            gherkin += "    When \(scenario.when)\n"
            gherkin += "    Then \(scenario.then)\n"
        }

        return gherkin
    }

    // MARK: - Private Helpers

    private static func parseUserStoryLine(_ line: String) -> (role: String, action: String, benefit: String)? {
        // Pattern: "As a [role], I want [action] so that [benefit]"
        let pattern = #"[Aa]s an? (.+?),? [Ii] want(?: to)? (.+?) so that (.+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        guard let roleRange = Range(match.range(at: 1), in: line),
              let actionRange = Range(match.range(at: 2), in: line),
              let benefitRange = Range(match.range(at: 3), in: line) else {
            return nil
        }

        return (
            role: String(line[roleRange]).trimmingCharacters(in: .whitespaces),
            action: String(line[actionRange]).trimmingCharacters(in: .whitespaces),
            benefit: String(line[benefitRange]).trimmingCharacters(in: .whitespaces)
        )
    }

    private static func parseScenarios(from lines: [String]) -> [ParsedScenario] {
        var scenarios: [ParsedScenario] = []
        var currentScenario: (name: String, given: String?, when: String?, then: String?)?

        for line in lines {
            let lower = line.lowercased()

            if lower.hasPrefix("scenario:") {
                // Save previous scenario if complete
                if let scenario = currentScenario,
                   let given = scenario.given,
                   let when = scenario.when,
                   let then = scenario.then {
                    scenarios.append(ParsedScenario(
                        name: scenario.name,
                        given: given,
                        when: when,
                        then: then
                    ))
                }

                let name = String(line.dropFirst("scenario:".count)).trimmingCharacters(in: .whitespaces)
                currentScenario = (name: name, given: nil, when: nil, then: nil)

            } else if lower.hasPrefix("given ") {
                currentScenario?.given = String(line.dropFirst("given ".count))

            } else if lower.hasPrefix("when ") {
                currentScenario?.when = String(line.dropFirst("when ".count))

            } else if lower.hasPrefix("then ") {
                currentScenario?.then = String(line.dropFirst("then ".count))
            }
        }

        // Save last scenario
        if let scenario = currentScenario,
           let given = scenario.given,
           let when = scenario.when,
           let then = scenario.then {
            scenarios.append(ParsedScenario(
                name: scenario.name,
                given: given,
                when: when,
                then: then
            ))
        }

        return scenarios
    }

    private static func generateStructName(from story: ParsedStory) -> String {
        let words = story.action
            .replacingOccurrences(of: "to ", with: "")
            .components(separatedBy: .whitespaces)
            .map { $0.capitalized }
            .joined()

        return words.isEmpty ? "UserStory" : words
    }

    private static func generateFunctionName(from scenarioName: String) -> String {
        let words = scenarioName
            .components(separatedBy: .whitespaces)
            .enumerated()
            .map { index, word in
                index == 0 ? word.lowercased() : word.capitalized
            }
            .joined()
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)

        return words.isEmpty ? "testScenario" : words
    }
}
