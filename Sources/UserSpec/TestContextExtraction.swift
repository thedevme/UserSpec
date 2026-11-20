import Foundation
import Testing


func extractUserStoryDescription() -> String {
    guard let currentTest = Test.current else {
        return "Unknown Story"
    }

    let suiteNames = Array(
        currentTest.id.nameComponents.dropLast()
    )

    for start in suiteNames.indices {
        let typeName = suiteNames[start...]
            .joined(separator: ".")

        if let story = UserStoryRegistry.shared
            .getStory(forTypeName: typeName) {
            return story
        }
    }

    return "Unknown Story"
}
