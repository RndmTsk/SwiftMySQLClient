import XCTest
@testable import MySQLClient

class MySQLClientTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(MySQLClient().text, "Hello, World!")
    }


    static var allTests : [(String, (MySQLClientTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
