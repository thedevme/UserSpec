import Testing
@testable import UserSpec

// MARK: - Story Parser Tests

@Suite("Story Parser Tests")
struct StoryParserTests {

    // MARK: - Parsing User Story Line

    @Test("parse() extracts role, action, benefit")
    func parseExtractsComponents() {
        let text = """
        As a shopper, I want to add items to cart so that I can purchase later

        Scenario: Adding in-stock item
        Given an empty cart
        When user adds a product
        Then cart contains one item
        """

        let story = StoryParser.parse(text)

        #expect(story != nil)
        #expect(story?.role == "shopper")
        #expect(story?.action == "add items to cart")
        #expect(story?.benefit == "I can purchase later")
    }

    @Test("parse() handles 'As an' format")
    func parseHandlesAnFormat() {
        let text = """
        As an admin, I want to manage users so that I can control access

        Scenario: Test
        Given setup
        When action
        Then result
        """

        let story = StoryParser.parse(text)

        #expect(story?.role == "admin")
    }

    @Test("parse() returns nil for invalid format")
    func parseReturnsNilForInvalid() {
        let text = "This is not a user story"

        let story = StoryParser.parse(text)

        #expect(story == nil)
    }

    @Test("parse() handles 'I want to' format")
    func parseHandlesWantToFormat() {
        let text = """
        As a user, I want to login so that I access my account

        Scenario: Login
        Given logged out
        When enter credentials
        Then logged in
        """

        let story = StoryParser.parse(text)

        #expect(story?.action == "login")
    }

    // MARK: - Parsing Scenarios

    @Test("parse() extracts single scenario")
    func parseExtractsSingleScenario() {
        let text = """
        As a user, I want feature so that benefit

        Scenario: First scenario
        Given the setup
        When the action
        Then the result
        """

        let story = StoryParser.parse(text)

        #expect(story?.scenarios.count == 1)
        #expect(story?.scenarios[0].name == "First scenario")
        #expect(story?.scenarios[0].given == "the setup")
        #expect(story?.scenarios[0].when == "the action")
        #expect(story?.scenarios[0].then == "the result")
    }

    @Test("parse() extracts multiple scenarios")
    func parseExtractsMultipleScenarios() {
        let text = """
        As a user, I want feature so that benefit

        Scenario: First
        Given setup1
        When action1
        Then result1

        Scenario: Second
        Given setup2
        When action2
        Then result2
        """

        let story = StoryParser.parse(text)

        #expect(story?.scenarios.count == 2)
        #expect(story?.scenarios[0].name == "First")
        #expect(story?.scenarios[1].name == "Second")
    }

    @Test("parse() handles scenario without complete steps")
    func parseHandlesIncompleteScenario() {
        let text = """
        As a user, I want feature so that benefit

        Scenario: Incomplete
        Given only this
        """

        let story = StoryParser.parse(text)

        // Incomplete scenario should not be included
        #expect(story?.scenarios.isEmpty == true)
    }

    // MARK: - Multiple Stories

    @Test("parseMultiple() parses multiple stories")
    func parseMultipleParsesMultiple() {
        let text = """
        As a user, I want login so that security


        Scenario: Valid login
        Given credentials
        When login
        Then success



        As a admin, I want reports so that insights


        Scenario: Generate report
        Given data
        When generate
        Then report shown
        """

        let stories = StoryParser.parseMultiple(text)

        #expect(stories.count == 2)
        #expect(stories[0].role == "user")
        #expect(stories[1].role == "admin")
    }

    // MARK: - User Story Text

    @Test("userStoryText returns formatted string")
    func userStoryTextReturnsFormatted() {
        let text = """
        As a developer, I want tests so that confidence

        Scenario: Test
        Given code
        When test
        Then pass
        """

        let story = StoryParser.parse(text)

        #expect(story?.userStoryText == "As a developer, I want tests so that confidence")
    }
}

// MARK: - Code Generation Tests

@Suite("Code Generation Tests")
struct CodeGenerationTests {

    @Test("generateSwift() creates valid structure")
    func generateSwiftCreatesStructure() {
        let story = StoryParser.ParsedStory(
            role: "user",
            action: "add items",
            benefit: "purchase later",
            scenarios: [
                StoryParser.ParsedScenario(
                    name: "Adding item",
                    given: "empty cart",
                    when: "add product",
                    then: "cart has item"
                )
            ]
        )

        let code = StoryParser.generateSwift(from: story)

        #expect(code.contains("import Testing"))
        #expect(code.contains("import UserSpec"))
        #expect(code.contains("@UserStory"))
        #expect(code.contains("struct AddItemsSpec"))
        #expect(code.contains("@Scenario(\"Adding item\")"))
        #expect(code.contains("func addingItem()"))
    }

    @Test("generateSwift() includes module import when specified")
    func generateSwiftIncludesModule() {
        let story = StoryParser.ParsedStory(
            role: "user",
            action: "test",
            benefit: "quality",
            scenarios: []
        )

        let code = StoryParser.generateSwift(from: story, moduleName: "MyApp")

        #expect(code.contains("@testable import MyApp"))
    }

    @Test("generateSwift() creates multiple test functions")
    func generateSwiftMultipleFunctions() {
        let story = StoryParser.ParsedStory(
            role: "user",
            action: "feature",
            benefit: "value",
            scenarios: [
                StoryParser.ParsedScenario(name: "First", given: "a", when: "b", then: "c"),
                StoryParser.ParsedScenario(name: "Second", given: "d", when: "e", then: "f"),
            ]
        )

        let code = StoryParser.generateSwift(from: story)

        #expect(code.contains("func first()"))
        #expect(code.contains("func second()"))
    }

    @Test("generateGherkin() creates valid format")
    func generateGherkinCreatesFormat() {
        let story = StoryParser.ParsedStory(
            role: "user",
            action: "login",
            benefit: "access account",
            scenarios: [
                StoryParser.ParsedScenario(
                    name: "Valid credentials",
                    given: "a registered user",
                    when: "entering valid credentials",
                    then: "user is logged in"
                )
            ]
        )

        let gherkin = StoryParser.generateGherkin(from: story)

        #expect(gherkin.contains("Feature: Login"))
        #expect(gherkin.contains("As a user, I want login so that access account"))
        #expect(gherkin.contains("Scenario: Valid credentials"))
        #expect(gherkin.contains("Given a registered user"))
        #expect(gherkin.contains("When entering valid credentials"))
        #expect(gherkin.contains("Then user is logged in"))
    }
}
