import Foundation
import Testing

/// Extracts the user story description from the currently running test's containing type.
///
/// This function uses reflection to navigate from `Test.current` to the containing
/// test suite type, then looks up the story in the `UserStoryRegistry`.
///
/// - Returns: The user story description, or "Unknown Story" if extraction fails
func extractUserStoryDescription() -> String {
    guard let currentTest = Test.current else {
        return "Unknown Story"
    }

    // Navigate: Test → containingTypeInfo → some → _kind → type
    let testMirror = Mirror(reflecting: currentTest)
    guard let containingTypeInfo = testMirror.children.first(where: { $0.label == "containingTypeInfo" })?.value else {
        return "Unknown Story"
    }

    let typeInfoMirror = Mirror(reflecting: containingTypeInfo)
    guard let typeInfoValue = typeInfoMirror.children.first(where: { $0.label == "some" })?.value else {
        return "Unknown Story"
    }

    let tiMirror = Mirror(reflecting: typeInfoValue)
    guard let kindValue = tiMirror.children.first(where: { $0.label == "_kind" })?.value else {
        return "Unknown Story"
    }

    let kindMirror = Mirror(reflecting: kindValue)
    guard let typeValue = kindMirror.children.first(where: { $0.label == "type" })?.value else {
        return "Unknown Story"
    }

    // Cast to Any.Type to get the metatype
    guard let metatype = typeValue as? Any.Type else {
        return "Unknown Story"
    }

    // Look up the story in the registry using the type name
    let typeName = String(describing: metatype)
    return UserStoryRegistry.shared.getStory(forTypeName: typeName) ?? "Unknown Story"
}
