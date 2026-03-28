import Testing
@testable import UserSpec

// MARK: - Test Mocks

protocol PaymentServiceProtocol {
    func charge(amount: Double) -> String
    func refund(id: String) -> Bool
}

class MockPaymentService: PaymentServiceProtocol, Mockable {
    let recorder = CallRecorder()

    func charge(amount: Double) -> String {
        recorder.record(#function, args: [amount])
        return recorder.stub(for: #function) ?? "success"
    }

    func refund(id: String) -> Bool {
        recorder.record(#function, args: [id])
        return recorder.stub(for: #function) ?? true
    }
}

// MARK: - Call Recorder Tests

@Suite("Call Recorder Tests")
struct CallRecorderTests {

    @Test("record() stores method call")
    func recordStoresCall() {
        let recorder = CallRecorder()

        recorder.record("doSomething", args: [])

        #expect(recorder.allCalls().count == 1)
        #expect(recorder.allCalls()[0].method == "doSomething")
    }

    @Test("record() stores arguments")
    func recordStoresArguments() {
        let recorder = CallRecorder()

        recorder.record("calculate", args: [42, "test"])

        let call = recorder.allCalls()[0]
        #expect(call.arguments.count == 2)
        #expect(call.arguments[0] as? Int == 42)
        #expect(call.arguments[1] as? String == "test")
    }

    @Test("calls(for:) filters by method name")
    func callsForFilters() {
        let recorder = CallRecorder()

        recorder.record("methodA", args: [])
        recorder.record("methodB", args: [])
        recorder.record("methodA", args: [])

        #expect(recorder.calls(for: "methodA").count == 2)
        #expect(recorder.calls(for: "methodB").count == 1)
    }

    @Test("reset() clears all calls")
    func resetClears() {
        let recorder = CallRecorder()
        recorder.record("test", args: [])

        recorder.reset()

        #expect(recorder.allCalls().isEmpty)
    }

    @Test("wasCalled() returns true when called")
    func wasCalledReturnsTrue() {
        let recorder = CallRecorder()
        recorder.record("myMethod", args: [])

        #expect(recorder.wasCalled("myMethod") == true)
        #expect(recorder.wasCalled("otherMethod") == false)
    }

    @Test("callCount(for:) returns correct count")
    func callCountReturns() {
        let recorder = CallRecorder()
        recorder.record("test", args: [])
        recorder.record("test", args: [])
        recorder.record("test", args: [])

        #expect(recorder.callCount(for: "test") == 3)
    }

    @Test("wasCalled(_:times:) verifies exact count")
    func wasCalledTimesVerifies() {
        let recorder = CallRecorder()
        recorder.record("test", args: [])
        recorder.record("test", args: [])

        #expect(recorder.wasCalled("test", times: 2) == true)
        #expect(recorder.wasCalled("test", times: 1) == false)
    }

    @Test("wasNotCalled() returns true when not called")
    func wasNotCalledReturns() {
        let recorder = CallRecorder()

        #expect(recorder.wasNotCalled("uncalled") == true)

        recorder.record("uncalled", args: [])

        #expect(recorder.wasNotCalled("uncalled") == false)
    }

    @Test("lastArguments(for:) returns last call args")
    func lastArgumentsReturns() {
        let recorder = CallRecorder()
        recorder.record("test", args: [1])
        recorder.record("test", args: [2])
        recorder.record("test", args: [3])

        let args = recorder.lastArguments(for: "test")

        #expect(args?.first as? Int == 3)
    }

    @Test("arguments(for:callIndex:) returns specific call args")
    func argumentsForCallIndex() {
        let recorder = CallRecorder()
        recorder.record("test", args: ["first"])
        recorder.record("test", args: ["second"])

        #expect(recorder.arguments(for: "test", callIndex: 0)?.first as? String == "first")
        #expect(recorder.arguments(for: "test", callIndex: 1)?.first as? String == "second")
        #expect(recorder.arguments(for: "test", callIndex: 2) == nil)
    }
}

// MARK: - Stubbing Tests

@Suite("Stubbing Tests")
struct StubbingTests {

    @Test("stub(for:return:) sets return value")
    func stubSetsReturnValue() {
        let recorder = CallRecorder()

        recorder.stub(for: "getValue", return: 42)

        let value: Int? = recorder.stub(for: "getValue")
        #expect(value == 42)
    }

    @Test("stub returns nil when not set")
    func stubReturnsNilWhenNotSet() {
        let recorder = CallRecorder()

        let value: Int? = recorder.stub(for: "notStubbed")

        #expect(value == nil)
    }

    @Test("stub with handler computes value")
    func stubWithHandlerComputes() {
        let recorder = CallRecorder()
        var counter = 0

        recorder.stub(for: "increment") { () -> Int in
            counter += 1
            return counter
        }

        let first: Int? = recorder.invokeStub(for: "increment")
        let second: Int? = recorder.invokeStub(for: "increment")

        #expect(first == 1)
        #expect(second == 2)
    }

    @Test("reset() clears stubs")
    func resetClearsStubs() {
        let recorder = CallRecorder()
        recorder.stub(for: "test", return: "value")

        recorder.reset()

        let value: String? = recorder.stub(for: "test")
        #expect(value == nil)
    }
}

// MARK: - Mockable Protocol Tests

@Suite("Mockable Protocol Tests")
struct MockableProtocolTests {

    @Test("mock records method calls")
    func mockRecordsCalls() {
        let mock = MockPaymentService()

        _ = mock.charge(amount: 99.99)

        #expect(mock.recorder.wasCalled("charge(amount:)"))
    }

    @Test("mock uses stubbed values")
    func mockUsesStubs() {
        let mock = MockPaymentService()
        mock.recorder.stub(for: "charge(amount:)", return: "declined")

        let result = mock.charge(amount: 100)

        #expect(result == "declined")
    }

    @Test("mock returns default when not stubbed")
    func mockReturnsDefault() {
        let mock = MockPaymentService()

        let result = mock.charge(amount: 50)

        #expect(result == "success")
    }

    @Test("mock captures arguments")
    func mockCapturesArguments() {
        let mock = MockPaymentService()

        _ = mock.charge(amount: 123.45)

        let args = mock.recorder.lastArguments(for: "charge(amount:)")
        #expect(args?.first as? Double == 123.45)
    }
}

// MARK: - Spy Tests

@Suite("Spy Tests")
struct SpyTests {

    @Test("spy wraps subject")
    func spyWrapsSubject() {
        let original = "test string"
        let spy = Spy(original)

        #expect(spy.subject == original)
    }

    @Test("spy records calls")
    func spyRecordsCalls() {
        let spy = Spy("test")

        spy.record("someMethod", args: [1, 2, 3])

        #expect(spy.recorder.wasCalled("someMethod"))
        #expect(spy.recorder.lastArguments(for: "someMethod")?.count == 3)
    }

    @Test("spy record returns subject for chaining")
    func spyRecordReturnsSubject() {
        let spy = Spy(42)

        let result = spy.record("test")

        #expect(result == 42)
    }
}

// MARK: - Stub Builder Tests

@Suite("Stub Builder Tests")
struct StubBuilderTests {

    @Test("Stub builds with multiple methods")
    func stubBuildsMultiple() {
        let stub = Stub<MockPaymentService>()
            .when("charge(amount:)", return: "pending")
            .when("refund(id:)", return: false)

        let chargeResult: String? = stub.recorder.stub(for: "charge(amount:)")
        let refundResult: Bool? = stub.recorder.stub(for: "refund(id:)")

        #expect(chargeResult == "pending")
        #expect(refundResult == false)
    }

    @Test("Stub with handler")
    func stubWithHandler() {
        var callCount = 0
        let stub = Stub<MockPaymentService>()
            .when("dynamicMethod") { () -> String in
                callCount += 1
                return "call \(callCount)"
            }

        let first: String? = stub.recorder.invokeStub(for: "dynamicMethod")
        let second: String? = stub.recorder.invokeStub(for: "dynamicMethod")

        #expect(first == "call 1")
        #expect(second == "call 2")
    }
}

// MARK: - Argument Matcher Tests

@Suite("Argument Matcher Tests")
struct ArgumentMatcherTests {

    @Test("any() matches any value")
    func anyMatches() {
        let matcher: AnyMatcher<Int> = ArgumentMatcher.any()

        #expect(matcher.matches(42) == true)
        #expect(matcher.matches(0) == true)
        #expect(matcher.matches("string") == false)
    }

    @Test("equal(to:) matches equal values")
    func equalMatches() {
        let matcher = ArgumentMatcher.equal(to: "expected")

        #expect(matcher.matches("expected") == true)
        #expect(matcher.matches("different") == false)
    }

    @Test("matching() uses predicate")
    func matchingUsesPredicate() {
        let matcher = ArgumentMatcher.matching { (value: Int) in value > 10 }

        #expect(matcher.matches(15) == true)
        #expect(matcher.matches(5) == false)
    }

    @Test("isNil() matches Optional.none")
    func isNilMatches() {
        let matcher: NilMatcher<String> = ArgumentMatcher.isNil()

        let nilValue: String? = nil
        #expect(matcher.matches(nilValue as Any) == true)

        let nonNilValue: String? = "hello"
        #expect(matcher.matches(nonNilValue as Any) == false)
    }

    @Test("isNotNil() matches non-nil")
    func isNotNilMatches() {
        let matcher: NotNilMatcher<String> = ArgumentMatcher.isNotNil()

        #expect(matcher.matches("value") == true)
    }
}

// MARK: - Verify Helper Tests

@Suite("Verify Helper Tests")
struct VerifyHelperTests {

    @Test("Verify.called() checks mock")
    func verifyCalledChecks() {
        let mock = MockPaymentService()
        _ = mock.charge(amount: 10)

        #expect(Verify.called(mock, "charge(amount:)") == true)
        #expect(Verify.called(mock, "refund(id:)") == false)
    }

    @Test("Verify.called(_:times:) checks count")
    func verifyCalledTimesChecks() {
        let mock = MockPaymentService()
        _ = mock.charge(amount: 10)
        _ = mock.charge(amount: 20)

        #expect(Verify.called(mock, "charge(amount:)", times: 2) == true)
        #expect(Verify.called(mock, "charge(amount:)", times: 1) == false)
    }

    @Test("Verify.notCalled() checks absence")
    func verifyNotCalledChecks() {
        let mock = MockPaymentService()

        #expect(Verify.notCalled(mock, "charge(amount:)") == true)

        _ = mock.charge(amount: 10)

        #expect(Verify.notCalled(mock, "charge(amount:)") == false)
    }

    @Test("Verify.calledWith() checks arguments")
    func verifyCalledWithChecks() {
        let mock = MockPaymentService()
        _ = mock.charge(amount: 99.99)

        let matches = Verify.calledWith(
            mock,
            "charge(amount:)",
            matchers: [ArgumentMatcher.equal(to: 99.99)]
        )

        #expect(matches == true)
    }
}

// MARK: - Mock Verification Function Tests

@Suite("Mock Verification Function Tests")
struct MockVerificationFunctionTests {

    @Test("verifyMock throws when not called")
    func verifyMockThrowsWhenNotCalled() {
        let mock = MockPaymentService()

        #expect(throws: MockVerificationFailure.self) {
            try verifyMock(mock, called: "charge(amount:)")
        }
    }

    @Test("verifyMock succeeds when called")
    func verifyMockSucceedsWhenCalled() throws {
        let mock = MockPaymentService()
        _ = mock.charge(amount: 10)

        try verifyMock(mock, called: "charge(amount:)")
    }

    @Test("verifyMock times throws on mismatch")
    func verifyMockTimesThrows() {
        let mock = MockPaymentService()
        _ = mock.charge(amount: 10)

        #expect(throws: MockVerificationFailure.self) {
            try verifyMock(mock, called: "charge(amount:)", times: 2)
        }
    }

    @Test("verifyMock notCalled throws when called")
    func verifyMockNotCalledThrows() {
        let mock = MockPaymentService()
        _ = mock.charge(amount: 10)

        #expect(throws: MockVerificationFailure.self) {
            try verifyMock(mock, notCalled: "charge(amount:)")
        }
    }
}
