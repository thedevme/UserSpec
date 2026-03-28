import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - UserStory Macro

/// Macro that marks a struct as a collection of scenarios for a user story.
/// Generates a @Suite annotation under the hood.
public struct UserStoryMacro: MemberMacro, PeerMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract the user story description
        guard let description = extractDescription(from: node) else {
            throw MacroError.missingDescription("@UserStory requires a description string")
        }

        // Add a static property to store the user story description
        let propertyDecl: DeclSyntax = """
            static let userStoryDescription: String = \(literal: description)
            """

        return [propertyDecl]
    }

    // MARK: - PeerMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // We don't generate peer declarations, the @Suite attribute is added via extension
        return []
    }

    // MARK: - Helpers

    private static func extractDescription(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArg = arguments.first,
              let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
              let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) else {
            return nil
        }
        return segment.content.text
    }
}

// MARK: - Scenario Macro

/// Macro that marks a function as a test scenario within a @UserStory.
/// Works with @Test from Swift Testing.
public struct ScenarioMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Scenario doesn't generate peers - it's primarily for documentation
        // The actual test behavior comes from @Test
        return []
    }
}

// MARK: - UIScenario Macro (for v0.2.0)

/// Macro for UI testing scenarios. Provides integration with XCUITest.
public struct UIScenarioMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Reserved for v0.2.0
        return []
    }
}

// MARK: - Errors

enum MacroError: Error, CustomStringConvertible {
    case missingDescription(String)
    case invalidApplication(String)

    var description: String {
        switch self {
        case .missingDescription(let message):
            return message
        case .invalidApplication(let message):
            return message
        }
    }
}

// MARK: - Plugin

@main
struct UserSpecPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UserStoryMacro.self,
        ScenarioMacro.self,
        UIScenarioMacro.self,
    ]
}
