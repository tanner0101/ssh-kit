import XCTest

import SSHKitTests

var tests = [XCTestCaseEntry]()
tests += SSHKitTests.allTests()
XCTMain(tests)
