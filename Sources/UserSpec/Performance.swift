import Foundation

// MARK: - Performance Testing
//
// Utilities for measuring and asserting performance in tests.

// MARK: - Benchmark

/// Measures execution time of a closure.
///
/// ## Example
///
/// ```swift
/// @Test
/// @Scenario("Search completes quickly")
/// func searchPerformance() throws {
///     try given("a large dataset") {
///         Dataset.generate(size: 10_000)
///     }
///     .when("performing search") { dataset in
///         Benchmark.measure {
///             dataset.search("query")
///         }
///     }
///     .then("completes under 100ms") { result, context in
///         #expect(result.duration < 0.1)
///     }
/// }
/// ```
public enum Benchmark {

    /// Result of a benchmark measurement.
    public struct Result<T>: Sendable where T: Sendable {
        /// The value returned by the measured closure.
        public let value: T

        /// The execution duration in seconds.
        public let duration: TimeInterval

        /// The execution duration in milliseconds.
        public var milliseconds: Double {
            duration * 1000
        }

        /// The execution duration in microseconds.
        public var microseconds: Double {
            duration * 1_000_000
        }
    }

    /// Measures execution time of a synchronous closure.
    ///
    /// - Parameter operation: The closure to measure.
    /// - Returns: A result containing the return value and duration.
    public static func measure<T: Sendable>(_ operation: () throws -> T) rethrows -> Result<T> {
        let start = CFAbsoluteTimeGetCurrent()
        let value = try operation()
        let end = CFAbsoluteTimeGetCurrent()
        return Result(value: value, duration: end - start)
    }

    /// Measures execution time of an async closure.
    ///
    /// - Parameter operation: The async closure to measure.
    /// - Returns: A result containing the return value and duration.
    public static func measure<T: Sendable>(_ operation: () async throws -> T) async rethrows -> Result<T> {
        let start = CFAbsoluteTimeGetCurrent()
        let value = try await operation()
        let end = CFAbsoluteTimeGetCurrent()
        return Result(value: value, duration: end - start)
    }

    /// Measures average execution time over multiple iterations.
    ///
    /// - Parameters:
    ///   - iterations: Number of times to run the operation.
    ///   - operation: The closure to measure.
    /// - Returns: A result containing the last value and average duration.
    public static func measureAverage<T: Sendable>(
        iterations: Int = 10,
        _ operation: () throws -> T
    ) rethrows -> Result<T> {
        var totalDuration: TimeInterval = 0
        var lastValue: T!

        for _ in 0..<iterations {
            let result = try measure(operation)
            totalDuration += result.duration
            lastValue = result.value
        }

        return Result(value: lastValue, duration: totalDuration / Double(iterations))
    }

    /// Measures average execution time over multiple async iterations.
    ///
    /// - Parameters:
    ///   - iterations: Number of times to run the operation.
    ///   - operation: The async closure to measure.
    /// - Returns: A result containing the last value and average duration.
    public static func measureAverage<T: Sendable>(
        iterations: Int = 10,
        _ operation: () async throws -> T
    ) async rethrows -> Result<T> {
        var totalDuration: TimeInterval = 0
        var lastValue: T!

        for _ in 0..<iterations {
            let result = try await measure(operation)
            totalDuration += result.duration
            lastValue = result.value
        }

        return Result(value: lastValue, duration: totalDuration / Double(iterations))
    }
}

// MARK: - Performance Assertions

/// Performance assertion utilities.
public enum PerformanceAssert {

    /// A performance assertion failure.
    public struct Failure: Error, CustomStringConvertible {
        public let message: String
        public let actual: TimeInterval
        public let threshold: TimeInterval

        public var description: String {
            "\(message) (actual: \(String(format: "%.3f", actual * 1000))ms, threshold: \(String(format: "%.3f", threshold * 1000))ms)"
        }
    }

    /// Asserts that an operation completes within a time threshold.
    ///
    /// - Parameters:
    ///   - seconds: Maximum allowed duration in seconds.
    ///   - message: Optional failure message.
    ///   - operation: The operation to measure.
    /// - Returns: The result of the operation.
    /// - Throws: `Failure` if the operation exceeds the threshold.
    @discardableResult
    public static func completes<T>(
        within seconds: TimeInterval,
        message: String = "Operation exceeded time threshold",
        _ operation: () throws -> T
    ) throws -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - start

        if duration > seconds {
            throw Failure(message: message, actual: duration, threshold: seconds)
        }

        return result
    }

    /// Asserts that an async operation completes within a time threshold.
    ///
    /// - Parameters:
    ///   - seconds: Maximum allowed duration in seconds.
    ///   - message: Optional failure message.
    ///   - operation: The async operation to measure.
    /// - Returns: The result of the operation.
    /// - Throws: `Failure` if the operation exceeds the threshold.
    @discardableResult
    public static func completes<T>(
        within seconds: TimeInterval,
        message: String = "Operation exceeded time threshold",
        _ operation: () async throws -> T
    ) async throws -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - start

        if duration > seconds {
            throw Failure(message: message, actual: duration, threshold: seconds)
        }

        return result
    }

    /// Asserts that an operation completes within milliseconds.
    ///
    /// - Parameters:
    ///   - milliseconds: Maximum allowed duration in milliseconds.
    ///   - message: Optional failure message.
    ///   - operation: The operation to measure.
    /// - Returns: The result of the operation.
    @discardableResult
    public static func completesInMilliseconds<T>(
        _ milliseconds: Double,
        message: String = "Operation exceeded time threshold",
        _ operation: () throws -> T
    ) throws -> T {
        try completes(within: milliseconds / 1000, message: message, operation)
    }

    /// Asserts that an async operation completes within milliseconds.
    @discardableResult
    public static func completesInMilliseconds<T>(
        _ milliseconds: Double,
        message: String = "Operation exceeded time threshold",
        _ operation: () async throws -> T
    ) async throws -> T {
        try await completes(within: milliseconds / 1000, message: message, operation)
    }
}

// MARK: - Performance Baseline

/// Stores and compares performance baselines.
public final class PerformanceBaseline: @unchecked Sendable {

    /// Shared baseline instance.
    public static let shared = PerformanceBaseline()

    private var baselines: [String: TimeInterval] = [:]
    private let lock = NSLock()

    private init() {}

    /// Sets a baseline for an operation.
    ///
    /// - Parameters:
    ///   - name: The operation name.
    ///   - duration: The baseline duration in seconds.
    public func setBaseline(_ name: String, duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        baselines[name] = duration
    }

    /// Gets the baseline for an operation.
    ///
    /// - Parameter name: The operation name.
    /// - Returns: The baseline duration, or nil if not set.
    public func baseline(for name: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        return baselines[name]
    }

    /// Clears all baselines.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        baselines.removeAll()
    }

    /// Compares an operation's performance against its baseline.
    ///
    /// - Parameters:
    ///   - name: The operation name.
    ///   - tolerance: Allowed percentage deviation (0.1 = 10%).
    ///   - operation: The operation to measure.
    /// - Returns: Comparison result.
    public func compare<T: Sendable>(
        _ name: String,
        tolerance: Double = 0.1,
        _ operation: () throws -> T
    ) rethrows -> ComparisonResult<T> {
        let result = try Benchmark.measure(operation)

        guard let baseline = baseline(for: name) else {
            return ComparisonResult(
                value: result.value,
                duration: result.duration,
                baseline: nil,
                deviation: nil,
                status: .noBaseline
            )
        }

        let deviation = (result.duration - baseline) / baseline

        let status: ComparisonStatus
        if deviation > tolerance {
            status = .regression
        } else if deviation < -tolerance {
            status = .improvement
        } else {
            status = .withinTolerance
        }

        return ComparisonResult(
            value: result.value,
            duration: result.duration,
            baseline: baseline,
            deviation: deviation,
            status: status
        )
    }

    /// Result of comparing performance against a baseline.
    public struct ComparisonResult<T> {
        public let value: T
        public let duration: TimeInterval
        public let baseline: TimeInterval?
        public let deviation: Double?
        public let status: ComparisonStatus

        /// Duration in milliseconds.
        public var milliseconds: Double { duration * 1000 }

        /// Deviation as a percentage string.
        public var deviationPercentage: String? {
            guard let deviation = deviation else { return nil }
            let sign = deviation >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", deviation * 100))%"
        }
    }

    /// Status of a performance comparison.
    public enum ComparisonStatus: Sendable {
        case noBaseline
        case withinTolerance
        case improvement
        case regression
    }
}

// MARK: - Memory Measurement

/// Utilities for measuring memory usage.
public enum MemoryMeasurement {

    /// Current memory usage in bytes.
    public static var currentUsage: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.resident_size : 0
    }

    /// Current memory usage in megabytes.
    public static var currentUsageMB: Double {
        Double(currentUsage) / 1_048_576
    }

    /// Measures memory delta during an operation.
    ///
    /// - Parameter operation: The operation to measure.
    /// - Returns: Result containing the value and memory delta.
    public static func measure<T>(_ operation: () throws -> T) rethrows -> Result<T> {
        let before = currentUsage
        let value = try operation()
        let after = currentUsage
        let delta = Int64(after) - Int64(before)
        return Result(value: value, bytesAllocated: delta)
    }

    /// Result of a memory measurement.
    public struct Result<T> {
        public let value: T
        public let bytesAllocated: Int64

        /// Memory delta in kilobytes.
        public var kilobytesAllocated: Double {
            Double(bytesAllocated) / 1024
        }

        /// Memory delta in megabytes.
        public var megabytesAllocated: Double {
            Double(bytesAllocated) / 1_048_576
        }
    }
}

// MARK: - Performance Reporter

/// Collects and reports performance metrics.
public final class PerformanceReporter: @unchecked Sendable {

    /// Shared reporter instance.
    public static let shared = PerformanceReporter()

    private var metrics: [PerformanceMetric] = []
    private let lock = NSLock()

    private init() {}

    /// A recorded performance metric.
    public struct PerformanceMetric: Sendable {
        public let name: String
        public let duration: TimeInterval
        public let memoryDelta: Int64?
        public let timestamp: Date
        public let tags: [String: String]

        public init(
            name: String,
            duration: TimeInterval,
            memoryDelta: Int64? = nil,
            timestamp: Date = Date(),
            tags: [String: String] = [:]
        ) {
            self.name = name
            self.duration = duration
            self.memoryDelta = memoryDelta
            self.timestamp = timestamp
            self.tags = tags
        }

        public var milliseconds: Double { duration * 1000 }
    }

    /// Records a performance metric.
    public func record(_ metric: PerformanceMetric) {
        lock.lock()
        defer { lock.unlock() }
        metrics.append(metric)
    }

    /// Records a named measurement.
    public func record(
        name: String,
        duration: TimeInterval,
        memoryDelta: Int64? = nil,
        tags: [String: String] = [:]
    ) {
        record(PerformanceMetric(
            name: name,
            duration: duration,
            memoryDelta: memoryDelta,
            tags: tags
        ))
    }

    /// Returns all recorded metrics.
    public func allMetrics() -> [PerformanceMetric] {
        lock.lock()
        defer { lock.unlock() }
        return metrics
    }

    /// Returns metrics for a specific name.
    public func metrics(named: String) -> [PerformanceMetric] {
        allMetrics().filter { $0.name == named }
    }

    /// Clears all metrics.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        metrics.removeAll()
    }

    /// Generates a summary report.
    public func generateReport() -> String {
        let all = allMetrics()
        guard !all.isEmpty else {
            return "No performance metrics recorded."
        }

        var report = """
        ═══════════════════════════════════════════════════════════════
                          PERFORMANCE REPORT
        ═══════════════════════════════════════════════════════════════

        """

        let grouped = Dictionary(grouping: all) { $0.name }

        for (name, metrics) in grouped.sorted(by: { $0.key < $1.key }) {
            let durations = metrics.map { $0.duration }
            let avg = durations.reduce(0, +) / Double(durations.count)
            let min = durations.min() ?? 0
            let max = durations.max() ?? 0

            report += """

            \(name)
            ────────────────────────────────────────────────────────────
              Samples: \(metrics.count)
              Average: \(String(format: "%.3f", avg * 1000)) ms
              Min:     \(String(format: "%.3f", min * 1000)) ms
              Max:     \(String(format: "%.3f", max * 1000)) ms

            """
        }

        report += """
        ═══════════════════════════════════════════════════════════════
        """

        return report
    }
}
