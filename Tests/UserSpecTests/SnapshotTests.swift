import Testing
import Foundation
@testable import UserSpec

// MARK: - Test Types

struct TestModel: Codable, Equatable, Sendable, SnapshotRepresentable {
    var name: String
    var value: Int
}

// MARK: - Snapshot Config Tests

@Suite("Snapshot Config Tests")
struct SnapshotConfigTests {

    @Test("default config has expected values")
    func defaultConfig() {
        let config = SnapshotConfig.default

        #expect(config.snapshotDirectory == "__Snapshots__")
        #expect(config.recordMode == false)
        #expect(config.fileExtension == "snap")
    }

    @Test("record config enables record mode")
    func recordConfig() {
        let config = SnapshotConfig.record

        #expect(config.recordMode == true)
    }

    @Test("custom config stores values")
    func customConfig() {
        let config = SnapshotConfig(
            snapshotDirectory: "CustomSnapshots",
            recordMode: true,
            fileExtension: "json"
        )

        #expect(config.snapshotDirectory == "CustomSnapshots")
        #expect(config.recordMode == true)
        #expect(config.fileExtension == "json")
    }
}

// MARK: - Snapshot Result Tests

@Suite("Snapshot Result Tests")
struct SnapshotResultTests {

    @Test("recorded is success")
    func recordedIsSuccess() {
        let result = SnapshotResult.recorded(path: "/path")

        #expect(result.isSuccess == true)
    }

    @Test("matched is success")
    func matchedIsSuccess() {
        let result = SnapshotResult.matched

        #expect(result.isSuccess == true)
    }

    @Test("noReference is not success")
    func noReferenceIsNotSuccess() {
        let result = SnapshotResult.noReference(path: "/path")

        #expect(result.isSuccess == false)
    }

    @Test("mismatch is not success")
    func mismatchIsNotSuccess() {
        let result = SnapshotResult.mismatch(
            expected: Data(),
            actual: Data(),
            path: "/path"
        )

        #expect(result.isSuccess == false)
    }
}

// MARK: - Snapshot Representable Tests

@Suite("Snapshot Representable Tests")
struct SnapshotRepresentableTests {

    @Test("String converts to UTF8 data")
    func stringConverts() {
        let text = "Hello, World!"

        let data = text.snapshotData

        #expect(String(data: data, encoding: .utf8) == text)
    }

    @Test("Data returns itself")
    func dataReturnsItself() {
        let original = Data([1, 2, 3, 4])

        let data = original.snapshotData

        #expect(data == original)
    }

    @Test("Array encodes to JSON")
    func arrayEncodesToJSON() {
        let array = ["a", "b", "c"]

        let data = array.snapshotData

        #expect(data.count > 0)
        #expect(String(data: data, encoding: .utf8)?.contains("a") == true)
    }

    @Test("Dictionary encodes to sorted JSON")
    func dictionaryEncodesToJSON() {
        let dict = ["b": 2, "a": 1]

        let data = dict.snapshotData
        let json = String(data: data, encoding: .utf8) ?? ""

        // Should be sorted, so "a" appears before "b"
        let aIndex = json.range(of: "\"a\"")?.lowerBound
        let bIndex = json.range(of: "\"b\"")?.lowerBound
        #expect(aIndex != nil)
        #expect(bIndex != nil)
        if let a = aIndex, let b = bIndex {
            #expect(a < b)
        }
    }

    @Test("Encodable type converts to JSON")
    func encodableConverts() {
        let model = TestModel(name: "Test", value: 42)

        let data = model.snapshotData

        #expect(data.count > 0)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("Test"))
        #expect(json.contains("42"))
    }
}

// MARK: - Snapshot Manager Tests

@Suite("Snapshot Manager Tests")
struct SnapshotManagerTests {

    init() {
        SnapshotManager.shared.config = .default
    }

    @Test("manager uses shared instance")
    func managerUsesSharedInstance() {
        let manager1 = SnapshotManager.shared
        let manager2 = SnapshotManager.shared

        #expect(manager1 === manager2)
    }

    @Test("config can be changed")
    func configCanBeChanged() {
        SnapshotManager.shared.config = SnapshotConfig(snapshotDirectory: "Custom")

        #expect(SnapshotManager.shared.config.snapshotDirectory == "Custom")

        // Reset
        SnapshotManager.shared.config = .default
    }
}

// MARK: - Inline Snapshot Tests

@Suite("Inline Snapshot Tests")
struct InlineSnapshotTests {

    @Test("inline snapshot matches equal value")
    func inlineSnapshotMatches() throws {
        let snapshot = inlineSnapshot("expected value")

        try snapshot.assert("expected value")
    }

    @Test("inline snapshot throws on mismatch")
    func inlineSnapshotThrowsOnMismatch() {
        let snapshot = inlineSnapshot("expected")

        #expect(throws: SnapshotError.self) {
            try snapshot.assert("actual")
        }
    }

    @Test("inline snapshot works with strings")
    func inlineSnapshotWithStrings() throws {
        let snapshot = inlineSnapshot("test value")

        try snapshot.assert("test value")
    }
}

// MARK: - Snapshot Error Tests

@Suite("Snapshot Error Tests")
struct SnapshotErrorTests {

    @Test("noReferenceSnapshot has descriptive message")
    func noReferenceMessage() {
        let error = SnapshotError.noReferenceSnapshot(path: "/path/to/snapshot")

        #expect(error.description.contains("/path/to/snapshot"))
        #expect(error.description.contains("record mode"))
    }

    @Test("mismatch has descriptive message")
    func mismatchMessage() {
        let error = SnapshotError.mismatch(path: "/path/to/snapshot", diff: "- old\n+ new")

        #expect(error.description.contains("/path/to/snapshot"))
        #expect(error.description.contains("- old"))
        #expect(error.description.contains("+ new"))
    }

    @Test("mismatch without diff shows path only")
    func mismatchWithoutDiff() {
        let error = SnapshotError.mismatch(path: "/path", diff: nil)

        #expect(error.description.contains("/path"))
        #expect(!error.description.contains("Diff:"))
    }
}

// MARK: - JSON Snapshot Tests

@Suite("JSON Snapshot Tests")
struct JSONSnapshotTests {

    @Test("JSONSnapshot encodes with pretty printing")
    func jsonSnapshotPrettyPrints() {
        let model = TestModel(name: "Test", value: 100)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try! encoder.encode(model)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\n"))
        #expect(json.contains("  "))
    }
}

// MARK: - Text Snapshot Tests

@Suite("Text Snapshot Tests")
struct TextSnapshotTests {

    @Test("text snapshot uses string data")
    func textSnapshotUsesString() {
        let text = "Hello\nWorld"
        let data = text.snapshotData

        #expect(String(data: data, encoding: .utf8) == text)
    }
}

// MARK: - Integration Tests

@Suite("Snapshot Integration Tests")
struct SnapshotIntegrationTests {

    @Test("snapshot with Given/When/Then")
    func snapshotWithGivenWhenThen() throws {
        try given("a model to snapshot") {
            TestModel(name: "Integration", value: 99)
        }
        .when("converted to snapshot data") { model in
            model.snapshotData
        }
        .then("produces valid JSON") { data, context in
            let json = String(data: data, encoding: .utf8)
            #expect(json?.contains("Integration") == true)
            #expect(json?.contains("99") == true)
        }
    }

    @Test("inline snapshot in assertion")
    func inlineSnapshotInAssertion() throws {
        let snapshot = inlineSnapshot("doubled: 2, 4, 6")

        try given("a computed value") {
            [1, 2, 3].map { $0 * 2 }
        }
        .when("formatted as string") { values in
            "doubled: \(values.map(String.init).joined(separator: ", "))"
        }
        .then("matches inline snapshot") { result, context in
            try snapshot.assert(result)
        }
    }
}
