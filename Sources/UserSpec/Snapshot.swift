import Foundation

// MARK: - Snapshot Testing
//
// Capture and compare snapshots for regression testing.

// MARK: - Snapshot Configuration

/// Configuration for snapshot testing.
public struct SnapshotConfig: Sendable {
    /// Directory where snapshots are stored.
    public var snapshotDirectory: String

    /// Whether to record new snapshots instead of comparing.
    public var recordMode: Bool

    /// File extension for snapshots.
    public var fileExtension: String

    /// Creates a snapshot configuration.
    public init(
        snapshotDirectory: String = "__Snapshots__",
        recordMode: Bool = false,
        fileExtension: String = "snap"
    ) {
        self.snapshotDirectory = snapshotDirectory
        self.recordMode = recordMode
        self.fileExtension = fileExtension
    }

    /// Default configuration.
    public static let `default` = SnapshotConfig()

    /// Record mode configuration.
    public static let record = SnapshotConfig(recordMode: true)
}

// MARK: - Snapshot Manager

/// Manages snapshot storage and comparison.
public final class SnapshotManager: @unchecked Sendable {

    /// Shared manager instance.
    public static let shared = SnapshotManager()

    /// Current configuration.
    public var config: SnapshotConfig = .default

    private let lock = NSLock()
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Snapshot Operations

    /// Records or compares a snapshot.
    ///
    /// - Parameters:
    ///   - value: The value to snapshot.
    ///   - name: Unique name for this snapshot.
    ///   - file: Source file (auto-captured).
    ///   - function: Function name (auto-captured).
    /// - Returns: Comparison result.
    public func snapshot<T: SnapshotRepresentable>(
        _ value: T,
        named name: String,
        file: StaticString = #file,
        function: StaticString = #function
    ) throws -> SnapshotResult {
        let snapshotPath = buildSnapshotPath(name: name, file: file, function: function)
        let snapshotData = value.snapshotData

        if config.recordMode {
            try recordSnapshot(data: snapshotData, at: snapshotPath)
            return .recorded(path: snapshotPath)
        } else {
            return try compareSnapshot(data: snapshotData, at: snapshotPath)
        }
    }

    /// Records a snapshot without comparison.
    public func record<T: SnapshotRepresentable>(
        _ value: T,
        named name: String,
        file: StaticString = #file,
        function: StaticString = #function
    ) throws {
        let snapshotPath = buildSnapshotPath(name: name, file: file, function: function)
        try recordSnapshot(data: value.snapshotData, at: snapshotPath)
    }

    /// Compares a value against an existing snapshot.
    public func compare<T: SnapshotRepresentable>(
        _ value: T,
        named name: String,
        file: StaticString = #file,
        function: StaticString = #function
    ) throws -> SnapshotResult {
        let snapshotPath = buildSnapshotPath(name: name, file: file, function: function)
        return try compareSnapshot(data: value.snapshotData, at: snapshotPath)
    }

    // MARK: - Private Helpers

    private func buildSnapshotPath(
        name: String,
        file: StaticString,
        function: StaticString
    ) -> String {
        let fileName = URL(fileURLWithPath: "\(file)").deletingPathExtension().lastPathComponent
        let funcName = "\(function)".replacingOccurrences(of: "()", with: "")
        let directory = URL(fileURLWithPath: "\(file)")
            .deletingLastPathComponent()
            .appendingPathComponent(config.snapshotDirectory)
            .appendingPathComponent(fileName)
            .path

        return "\(directory)/\(funcName)_\(name).\(config.fileExtension)"
    }

    private func recordSnapshot(data: Data, at path: String) throws {
        let directory = URL(fileURLWithPath: path).deletingLastPathComponent().path

        if !fileManager.fileExists(atPath: directory) {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        try data.write(to: URL(fileURLWithPath: path))
    }

    private func compareSnapshot(data: Data, at path: String) throws -> SnapshotResult {
        guard fileManager.fileExists(atPath: path) else {
            return .noReference(path: path)
        }

        let referenceData = try Data(contentsOf: URL(fileURLWithPath: path))

        if data == referenceData {
            return .matched
        } else {
            return .mismatch(
                expected: referenceData,
                actual: data,
                path: path
            )
        }
    }
}

// MARK: - Snapshot Result

/// Result of a snapshot comparison.
public enum SnapshotResult: Sendable, Equatable {
    /// Snapshot was recorded (record mode).
    case recorded(path: String)

    /// Snapshot matched the reference.
    case matched

    /// No reference snapshot exists.
    case noReference(path: String)

    /// Snapshot did not match the reference.
    case mismatch(expected: Data, actual: Data, path: String)

    /// Whether the result indicates success.
    public var isSuccess: Bool {
        switch self {
        case .recorded, .matched:
            return true
        case .noReference, .mismatch:
            return false
        }
    }
}

// MARK: - Snapshot Representable

/// A type that can be converted to snapshot data.
public protocol SnapshotRepresentable {
    /// Converts the value to snapshot data.
    var snapshotData: Data { get }
}

// MARK: - Built-in Conformances

extension String: SnapshotRepresentable {
    public var snapshotData: Data {
        data(using: .utf8) ?? Data()
    }
}

extension Data: SnapshotRepresentable {
    public var snapshotData: Data { self }
}

extension Array: SnapshotRepresentable where Element: Encodable {
    public var snapshotData: Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }
}

extension Dictionary: SnapshotRepresentable where Key: Encodable, Value: Encodable {
    public var snapshotData: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(self)) ?? Data()
    }
}

// MARK: - Encodable Extension

extension SnapshotRepresentable where Self: Encodable {
    public var snapshotData: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(self)) ?? Data()
    }
}

// MARK: - Snapshot Assertions

/// Snapshot testing assertion errors.
public enum SnapshotError: Error, CustomStringConvertible {
    case noReferenceSnapshot(path: String)
    case mismatch(path: String, diff: String?)

    public var description: String {
        switch self {
        case .noReferenceSnapshot(let path):
            return "No reference snapshot at: \(path). Run in record mode to create."
        case .mismatch(let path, let diff):
            var message = "Snapshot mismatch at: \(path)"
            if let diff = diff {
                message += "\nDiff:\n\(diff)"
            }
            return message
        }
    }
}

/// Asserts that a value matches its snapshot.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - name: Unique name for this snapshot.
///   - file: Source file.
///   - function: Function name.
/// - Throws: `SnapshotError` if comparison fails.
public func assertSnapshot<T: SnapshotRepresentable>(
    _ value: T,
    named name: String,
    file: StaticString = #file,
    function: StaticString = #function
) throws {
    let result = try SnapshotManager.shared.snapshot(value, named: name, file: file, function: function)

    switch result {
    case .recorded, .matched:
        break
    case .noReference(let path):
        throw SnapshotError.noReferenceSnapshot(path: path)
    case .mismatch(let expected, let actual, let path):
        let diff = generateTextDiff(expected: expected, actual: actual)
        throw SnapshotError.mismatch(path: path, diff: diff)
    }
}

/// Generates a text diff between two data values.
private func generateTextDiff(expected: Data, actual: Data) -> String? {
    guard let expectedString = String(data: expected, encoding: .utf8),
          let actualString = String(data: actual, encoding: .utf8) else {
        return "Binary data differs (\(expected.count) bytes vs \(actual.count) bytes)"
    }

    let expectedLines = expectedString.components(separatedBy: .newlines)
    let actualLines = actualString.components(separatedBy: .newlines)

    var diff: [String] = []

    let maxLines = max(expectedLines.count, actualLines.count)
    for i in 0..<maxLines {
        let expectedLine = i < expectedLines.count ? expectedLines[i] : ""
        let actualLine = i < actualLines.count ? actualLines[i] : ""

        if expectedLine != actualLine {
            if !expectedLine.isEmpty {
                diff.append("- \(expectedLine)")
            }
            if !actualLine.isEmpty {
                diff.append("+ \(actualLine)")
            }
        }
    }

    return diff.isEmpty ? nil : diff.joined(separator: "\n")
}

// MARK: - Inline Snapshot

/// An inline snapshot that stores the expected value in code.
public struct InlineSnapshot<T: SnapshotRepresentable & Equatable>: Sendable where T: Sendable {
    public let expected: T

    public init(_ expected: T) {
        self.expected = expected
    }

    /// Asserts that the actual value matches the expected.
    public func assert(_ actual: T) throws {
        if actual != expected {
            throw SnapshotError.mismatch(
                path: "inline",
                diff: "Expected: \(expected)\nActual: \(actual)"
            )
        }
    }
}

/// Creates an inline snapshot assertion.
public func inlineSnapshot<T: SnapshotRepresentable & Equatable & Sendable>(
    _ expected: T
) -> InlineSnapshot<T> {
    InlineSnapshot(expected)
}

// MARK: - JSON Snapshot

/// Snapshot helper for JSON-encodable types.
public enum JSONSnapshot {

    /// Asserts a JSON snapshot match.
    public static func assert<T: Encodable>(
        _ value: T,
        named name: String,
        file: StaticString = #file,
        function: StaticString = #function
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        let wrapper = JSONSnapshotWrapper(data: data)
        try assertSnapshot(wrapper, named: name, file: file, function: function)
    }
}

/// Wrapper to make JSON data snapshot-representable.
private struct JSONSnapshotWrapper: SnapshotRepresentable {
    let data: Data
    var snapshotData: Data { data }
}

// MARK: - Text Snapshot

/// Snapshot helper for text content.
public enum TextSnapshot {

    /// Asserts a text snapshot match.
    public static func assert(
        _ text: String,
        named name: String,
        file: StaticString = #file,
        function: StaticString = #function
    ) throws {
        try assertSnapshot(text, named: name, file: file, function: function)
    }

    /// Asserts multiline text matches, with trimming options.
    public static func assertTrimmed(
        _ text: String,
        named name: String,
        file: StaticString = #file,
        function: StaticString = #function
    ) throws {
        let trimmed = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        try assertSnapshot(trimmed, named: name, file: file, function: function)
    }
}

// MARK: - Snapshot Test Helpers

/// Convenience functions for snapshot testing in Given/When/Then chains.
public extension SnapshotManager {

    /// Creates a snapshot assertion closure for use in then blocks.
    func snapshotAssertion<T: SnapshotRepresentable>(
        named name: String,
        file: StaticString = #file,
        function: StaticString = #function
    ) -> (T) throws -> Void {
        return { value in
            let result = try self.snapshot(value, named: name, file: file, function: function)
            switch result {
            case .recorded, .matched:
                break
            case .noReference(let path):
                throw SnapshotError.noReferenceSnapshot(path: path)
            case .mismatch(_, _, let path):
                throw SnapshotError.mismatch(path: path, diff: nil)
            }
        }
    }
}
