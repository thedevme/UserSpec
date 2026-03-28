import Testing
import Foundation
@testable import UserSpec

// MARK: - Benchmark Tests

@Suite("Benchmark Tests")
struct BenchmarkTests {

    @Test("measure() returns value and duration")
    func measureReturnsValueAndDuration() {
        let result = Benchmark.measure {
            Thread.sleep(forTimeInterval: 0.01)
            return 42
        }

        #expect(result.value == 42)
        #expect(result.duration >= 0.01)
        #expect(result.duration < 0.1)
    }

    @Test("measure() milliseconds conversion")
    func measureMillisecondsConversion() {
        let result = Benchmark.measure {
            Thread.sleep(forTimeInterval: 0.01)
            return "test"
        }

        #expect(result.milliseconds >= 10)
        #expect(result.milliseconds < 100)
    }

    @Test("measure() microseconds conversion")
    func measureMicrosecondsConversion() {
        let result = Benchmark.measure {
            Thread.sleep(forTimeInterval: 0.001)
            return true
        }

        #expect(result.microseconds >= 1000)
    }

    @Test("measureAverage() calculates average duration")
    func measureAverageCalculates() {
        let result = Benchmark.measureAverage(iterations: 5) {
            Thread.sleep(forTimeInterval: 0.005)
            return 1
        }

        #expect(result.value == 1)
        #expect(result.duration >= 0.005)
        #expect(result.duration < 0.02)
    }

    @Test("measure() async works")
    func measureAsyncWorks() async {
        let result = await Benchmark.measure {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return "async result"
        }

        #expect(result.value == "async result")
        #expect(result.duration >= 0.01)
    }
}

// MARK: - Performance Assert Tests

@Suite("Performance Assert Tests")
struct PerformanceAssertTests {

    @Test("completes(within:) passes when fast enough")
    func completesWithinPasses() throws {
        let result = try PerformanceAssert.completes(within: 1.0) {
            Thread.sleep(forTimeInterval: 0.01)
            return "fast"
        }

        #expect(result == "fast")
    }

    @Test("completes(within:) throws when too slow")
    func completesWithinThrows() {
        #expect(throws: PerformanceAssert.Failure.self) {
            try PerformanceAssert.completes(within: 0.001) {
                Thread.sleep(forTimeInterval: 0.01)
                return "slow"
            }
        }
    }

    @Test("completesInMilliseconds() passes when fast")
    func completesInMillisecondsPasses() throws {
        let result = try PerformanceAssert.completesInMilliseconds(500) {
            Thread.sleep(forTimeInterval: 0.01)
            return 42
        }

        #expect(result == 42)
    }

    @Test("completesInMilliseconds() throws when slow")
    func completesInMillisecondsThrows() {
        #expect(throws: PerformanceAssert.Failure.self) {
            try PerformanceAssert.completesInMilliseconds(5) {
                Thread.sleep(forTimeInterval: 0.02)
                return "too slow"
            }
        }
    }

    @Test("Failure description includes details")
    func failureDescriptionIncludesDetails() {
        let failure = PerformanceAssert.Failure(
            message: "Test failed",
            actual: 0.150,
            threshold: 0.100
        )

        #expect(failure.description.contains("Test failed"))
        #expect(failure.description.contains("150"))
        #expect(failure.description.contains("100"))
    }
}

// MARK: - Performance Baseline Tests

@Suite("Performance Baseline Tests", .serialized)
struct PerformanceBaselineTests {

    init() {
        PerformanceBaseline.shared.reset()
    }

    @Test("setBaseline and baseline(for:) work")
    func setAndGetBaseline() {
        let uniqueName = "operation_\(UUID().uuidString)"
        PerformanceBaseline.shared.setBaseline(uniqueName, duration: 0.1)

        let baseline = PerformanceBaseline.shared.baseline(for: uniqueName)

        #expect(baseline == 0.1)
    }

    @Test("baseline(for:) returns nil when not set")
    func baselineReturnsNilWhenNotSet() {
        let baseline = PerformanceBaseline.shared.baseline(for: "unknown_\(UUID().uuidString)")

        #expect(baseline == nil)
    }

    @Test("reset() clears baselines")
    func resetClearsBaselines() {
        let uniqueName = "reset_test_\(UUID().uuidString)"
        PerformanceBaseline.shared.setBaseline(uniqueName, duration: 0.5)
        PerformanceBaseline.shared.reset()

        #expect(PerformanceBaseline.shared.baseline(for: uniqueName) == nil)
    }

    @Test("compare() returns noBaseline when no baseline exists")
    func compareReturnsNoBaseline() {
        let result = PerformanceBaseline.shared.compare("unset_\(UUID().uuidString)") {
            "value"
        }

        #expect(result.status == .noBaseline)
        #expect(result.baseline == nil)
    }

    @Test("compare() returns withinTolerance for similar performance")
    func compareReturnsWithinTolerance() {
        let uniqueName = "stable_\(UUID().uuidString)"
        PerformanceBaseline.shared.setBaseline(uniqueName, duration: 0.001)

        let result = PerformanceBaseline.shared.compare(uniqueName, tolerance: 5.0) {
            // Fast operation
            1 + 1
        }

        // Either within tolerance or improvement (faster) is acceptable
        #expect(result.status == .withinTolerance || result.status == .improvement)
    }

    @Test("compare() returns regression when slower")
    func compareReturnsRegression() {
        let uniqueName = "slow_\(UUID().uuidString)"
        // Set a very fast baseline
        PerformanceBaseline.shared.setBaseline(uniqueName, duration: 0.0001)

        let result = PerformanceBaseline.shared.compare(uniqueName, tolerance: 0.1) {
            Thread.sleep(forTimeInterval: 0.02)
            return "slower"
        }

        #expect(result.status == .regression)
    }

    @Test("deviationPercentage formats correctly")
    func deviationPercentageFormats() {
        let uniqueName = "deviation_\(UUID().uuidString)"
        PerformanceBaseline.shared.setBaseline(uniqueName, duration: 0.001)

        let result = PerformanceBaseline.shared.compare(uniqueName) {
            Thread.sleep(forTimeInterval: 0.01)
            return 1
        }

        #expect(result.deviationPercentage != nil)
        #expect(result.deviationPercentage?.contains("%") == true)
    }
}

// MARK: - Memory Measurement Tests

@Suite("Memory Measurement Tests")
struct MemoryMeasurementTests {

    @Test("currentUsage returns non-zero value")
    func currentUsageReturnsNonZero() {
        let usage = MemoryMeasurement.currentUsage

        #expect(usage > 0)
    }

    @Test("currentUsageMB returns reasonable value")
    func currentUsageMBReturnsReasonable() {
        let usageMB = MemoryMeasurement.currentUsageMB

        #expect(usageMB > 0)
        #expect(usageMB < 10000) // Less than 10 GB
    }

    @Test("measure() returns value and memory delta")
    func measureReturnsValueAndDelta() {
        let result = MemoryMeasurement.measure {
            // Allocate some memory
            var array: [Int] = []
            for i in 0..<1000 {
                array.append(i)
            }
            return array.count
        }

        #expect(result.value == 1000)
        // Memory delta can be positive, negative, or zero due to GC
    }

    @Test("kilobytesAllocated conversion works")
    func kilobytesConversionWorks() {
        let result = MemoryMeasurement.Result(value: 1, bytesAllocated: 2048)

        #expect(result.kilobytesAllocated == 2.0)
    }

    @Test("megabytesAllocated conversion works")
    func megabytesConversionWorks() {
        let result = MemoryMeasurement.Result(value: 1, bytesAllocated: 1_048_576)

        #expect(result.megabytesAllocated == 1.0)
    }
}

// MARK: - Performance Reporter Tests

@Suite("Performance Reporter Tests")
struct PerformanceReporterTests {

    init() {
        PerformanceReporter.shared.reset()
    }

    @Test("record() stores metric")
    func recordStoresMetric() {
        PerformanceReporter.shared.record(
            name: "test_operation",
            duration: 0.1
        )

        let metrics = PerformanceReporter.shared.allMetrics()

        #expect(metrics.count == 1)
        #expect(metrics[0].name == "test_operation")
        #expect(metrics[0].duration == 0.1)
    }

    @Test("record() with tags stores tags")
    func recordWithTagsStoresTags() {
        let uniqueName = "tagged_\(UUID().uuidString)"
        PerformanceReporter.shared.record(
            name: uniqueName,
            duration: 0.05,
            tags: ["env": "test", "version": "1.0"]
        )

        let metrics = PerformanceReporter.shared.metrics(named: uniqueName)
        #expect(metrics.count >= 1)

        let metric = metrics.first!
        #expect(metric.tags["env"] == "test")
        #expect(metric.tags["version"] == "1.0")
    }

    @Test("metrics(named:) filters by name")
    func metricsNamedFilters() {
        PerformanceReporter.shared.record(name: "op1", duration: 0.1)
        PerformanceReporter.shared.record(name: "op2", duration: 0.2)
        PerformanceReporter.shared.record(name: "op1", duration: 0.15)

        let op1Metrics = PerformanceReporter.shared.metrics(named: "op1")

        #expect(op1Metrics.count == 2)
    }

    @Test("reset() clears all metrics")
    func resetClearsMetrics() {
        PerformanceReporter.shared.record(name: "test", duration: 0.1)
        PerformanceReporter.shared.reset()

        #expect(PerformanceReporter.shared.allMetrics().isEmpty)
    }

    @Test("generateReport() creates summary")
    func generateReportCreatesSummary() {
        PerformanceReporter.shared.record(name: "operation", duration: 0.1)
        PerformanceReporter.shared.record(name: "operation", duration: 0.15)
        PerformanceReporter.shared.record(name: "operation", duration: 0.12)

        let report = PerformanceReporter.shared.generateReport()

        #expect(report.contains("PERFORMANCE REPORT"))
        #expect(report.contains("operation"))
        #expect(report.contains("Samples: 3"))
        #expect(report.contains("Average:"))
    }

    @Test("generateReport() with no metrics shows message")
    func generateReportEmptyShowsMessage() {
        let report = PerformanceReporter.shared.generateReport()

        #expect(report.contains("No performance metrics recorded"))
    }

    @Test("PerformanceMetric milliseconds conversion")
    func metricMillisecondsConversion() {
        let metric = PerformanceReporter.PerformanceMetric(
            name: "test",
            duration: 0.1
        )

        #expect(metric.milliseconds == 100)
    }
}

// MARK: - Integration Tests

@Suite("Performance Integration Tests")
struct PerformanceIntegrationTests {

    @Test("Benchmark with Given/When/Then")
    func benchmarkWithGivenWhenThen() throws {
        try given("data to process") {
            [1, 2, 3, 4, 5]
        }
        .when("benchmarked") { data in
            Benchmark.measure {
                data.reduce(0, +)
            }
        }
        .then("completes with measured duration") { result, context in
            #expect(result.value == 15)
            #expect(result.duration >= 0)
        }
    }

    @Test("Performance assertion in test chain")
    func performanceAssertionInChain() throws {
        try given("a value") {
            42
        }
        .when("processed with time constraint") { value in
            try PerformanceAssert.completes(within: 1.0) {
                value * 2
            }
        }
        .then("returns expected result") { result, context in
            #expect(result == 84)
        }
    }
}
