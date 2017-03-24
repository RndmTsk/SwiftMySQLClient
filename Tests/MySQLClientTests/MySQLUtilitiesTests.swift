//
//  MySQLUtilitiesTests.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-24.
//
//

import XCTest
@testable import SwiftMySQLClient

class MySQLUtilitiesTests: XCTestCase {
    let testData: [UInt8] = [
         1, // 1
        61, // 15617
        12, // 802049
    ]
    func test01LSBEncoded1Byte() {
        let expectedResult = [testData[0]]
        let testValue = Int(expectedResult[0])
        let lsbEncoded = MySQL.lsbEncoded(testValue, to: 1)
        XCTAssert(lsbEncoded == expectedResult, "Data not encoded properly, expected: \(expectedResult), received: \(lsbEncoded)")
    }

    func test02LSBEncoded2Bytes() {
        let expectedResult = [testData[0], testData[1]]
        let testValue = Int(expectedResult[0]) | Int(expectedResult[1]) << 8
        let lsbEncoded = MySQL.lsbEncoded(testValue, to: 2)
        XCTAssert(lsbEncoded == expectedResult, "Data not encoded properly, expected: \(expectedResult), received: \(lsbEncoded)")
    }

    func test03LSBEncoded3Bytes() {
        let expectedResult = [testData[0], testData[1], testData[2]]
        let testValue = Int(expectedResult[0]) | Int(expectedResult[1]) << 8 | Int(expectedResult[2]) << 16
        let lsbEncoded = MySQL.lsbEncoded(testValue, to: 3)
        XCTAssert(lsbEncoded == expectedResult, "Data not encoded properly, expected: \(expectedResult), received: \(lsbEncoded)")
    }
}
