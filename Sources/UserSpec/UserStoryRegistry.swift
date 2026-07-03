import Foundation
import os.lock

/// Thread-safe registry for user story descriptions keyed by type name.
///
/// The `@UserStory` macro automatically registers stories in this registry,
/// allowing the RSpec reporter to group scenarios by their containing story.
public final class UserStoryRegistry: Sendable {
    public static let shared = UserStoryRegistry()

    private let lock: OSAllocatedUnfairLock<[String: String]>

    private init() {
        lock = OSAllocatedUnfairLock(initialState: [:])
    }

    /// Registers a user story description for a given type.
    ///
    /// - Parameters:
    ///   - typeName: The fully-qualified type name (e.g., "SeatSelectionTests")
    ///   - story: The user story description
    public func register(typeName: String, story: String) {
        lock.withLock { stories in
            stories[typeName] = story
        }
    }

    /// Retrieves the user story description for a given type.
    ///
    /// - Parameter typeName: The fully-qualified type name
    /// - Returns: The story description, or nil if not registered
    public func getStory(forTypeName typeName: String) -> String? {
        lock.withLock { stories in
            stories[typeName]
        }
    }
}
