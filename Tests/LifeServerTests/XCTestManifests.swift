import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LifeServerCoreTests.allTests),
        testCase(DatabaseManagerTests.allTests),
    ]
}
#endif

