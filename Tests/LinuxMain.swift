import XCTest

import tddTests

var tests = [XCTestCaseEntry]()
tests += tddTests.allTests()
XCTMain(tests)