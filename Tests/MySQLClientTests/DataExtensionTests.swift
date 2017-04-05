//
//  DataExtensionTests.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-21.
//
//

import XCTest
@testable import SwiftMySQLClient

class DataExtensionTests: XCTestCase {
    static let testBytes: [UInt8] = [
        56, 46, 48, 46, 48, 45, 100, 109, 114, 0, 56
        // 8.0.0-dmr = \0 terminated
        // 8.0.0-dmr\08 = EOF terminated
    ]
    static let expectedNullEncodedString = String(bytes: testBytes[0..<9], encoding: .utf8)!
    static let expectedNullEncodedStringLength = expectedNullEncodedString.utf8.count
    static let expectedEOFEncodedString = String(bytes: testBytes[0..<11], encoding: .utf8)!
    static let expectedEOFEncodedStringLength = expectedNullEncodedString.utf8.count

    static let substringOffset = 6
    // Just the dmr portion
    static let expectedNullEncodedSubstring = String(bytes: testBytes[substringOffset..<9], encoding: .utf8)!
    static let expectedNullEncodedSubstringLength = expectedNullEncodedSubstring.utf8.count
    // Just the dmr8 portion
    static let expectedEOFEncodedSubstring = String(bytes: testBytes[substringOffset..<11], encoding: .utf8)!
    static let expectedEOFEncodedSubstringLength = expectedNullEncodedSubstring.utf8.count
    let data: Data = Data(bytes: DataExtensionTests.testBytes)

    func test01NullEncodedString() {
        let string = data.nullEncodedString()
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: \(string).")
        }
    }

    func test02RemoveNullEncodedString() {
        let (string, remaining) = data.removeNullEncodedString()
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - string.utf8.count - 1 // null terminator
        if remaining.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(remaining.count)")
            return
        }
        if remaining.count > 0 && remaining[0] == 0 {
            XCTFail("Failed to remove null character after string.")
        }
    }

    func test03RemovingNullEncodedString() {
        var mutableData = data
        let string = mutableData.removingNullEncodedString()
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - string.utf8.count - 1 // null terminator
        if mutableData.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(mutableData.count)")
            return
        }
        if mutableData.count > 0 && mutableData[0] == 0 {
            XCTFail("Failed to remove null character after string.")
        }
    }

    func test04NullEncodedStringAtOffset() {
        let string = data.nullEncodedString(at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: \(string).")
        }
    }
    
    func test05RemoveNullEncodedStringAtOffset() {
        let (string, remaining) = data.removeNullEncodedString(at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - DataExtensionTests.substringOffset - string.utf8.count - 1 // null terminator
        if remaining.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(remaining.count)")
            return
        }
        if remaining.count > 0 && remaining[0] == 0 {
            XCTFail("Failed to remove null character after string.")
        }
    }
    
    func test06RemovingNullEncodedStringAtOffset() {
        var mutableData = data
        let string = mutableData.removingNullEncodedString(at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - DataExtensionTests.substringOffset - string.utf8.count - 1 // null terminator
        if mutableData.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(mutableData.count)")
            return
        }
        if mutableData.count > 0 && mutableData[0] == 0 {
            XCTFail("Failed to remove null character after string.")
        }
    }

    func test07EOFEncodedString() {
        let string = data.eofEncodedString()
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedEOFEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedString), received: \(string).")
        }
    }
    
    func test08RemoveEOFEncodedString() {
        let (string, remaining) = data.removeEOFEncodedString()
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedEOFEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedString), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - string.utf8.count
        if remaining.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(remaining.count)")
            return
        }
        if remaining.count > 0 && remaining[0] == MySQL.Constants.eof {
            XCTFail("Failed to remove EOF character after string.")
        }
    }
    
    func test09RemovingEOFEncodedString() {
        var mutableData = data
        let string = mutableData.removingEOFEncodedString()
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedEOFEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedString), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - string.utf8.count
        if mutableData.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(mutableData.count)")
            return
        }
        if mutableData.count > 0 && mutableData[0] == MySQL.Constants.eof {
            XCTFail("Failed to remove EOF character after string.")
        }
    }

    func test10EOFEncodedStringAtOffset() {
        let string = data.eofEncodedString(at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedEOFEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedSubstring), received: \(string).")
        }
    }
    
    func test11RemoveEOFEncodedStringAtOffset() {
        let (string, remaining) = data.removeEOFEncodedString(at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedEOFEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedSubstring), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - DataExtensionTests.substringOffset - string.utf8.count
        if remaining.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(remaining.count)")
            return
        }
        if remaining.count > 0 && remaining[0] == MySQL.Constants.eof {
            XCTFail("Failed to remove EOF character after string.")
        }
    }
    
    func test12RemovingEOFEncodedStringAtOffset() {
        var mutableData = data
        let string = mutableData.removingEOFEncodedString(at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedEOFEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedEOFEncodedSubstring), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - DataExtensionTests.substringOffset - string.utf8.count
        if mutableData.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(mutableData.count)")
            return
        }
        if mutableData.count > 0 && mutableData[0] == MySQL.Constants.eof {
            XCTFail("Failed to remove EOF character after string.")
        }
    }

    func test13StringOfLength() {
        let string = data.string(of: DataExtensionTests.expectedNullEncodedStringLength)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: \(string).")
        }
    }
    
    func test14RemoveStringOfLength() {
        let (string, remaining) = data.removeString(of: DataExtensionTests.expectedNullEncodedStringLength)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - string.utf8.count
        if remaining.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(remaining.count)")
            return
        }
        if remaining.count > 0 && remaining[0] != data[DataExtensionTests.expectedNullEncodedStringLength] {
            XCTFail("Remaining data is at incorrect string index.")
        }
    }
    
    func test15RemovingStringOfLength() {
        var mutableData = data
        let string = mutableData.removingString(of: DataExtensionTests.expectedNullEncodedStringLength)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedString {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedString), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - string.utf8.count
        if mutableData.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(mutableData.count)")
            return
        }
        if mutableData.count > 0 && mutableData[0] != data[DataExtensionTests.expectedNullEncodedStringLength] {
            XCTFail("Remaining data is at incorrect string index.")
        }
    }

    func test16StringOfLengthAtOffset() {
        let string = data.string(of: DataExtensionTests.expectedNullEncodedSubstringLength, at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: \(string).")
        }
    }
    
    func test17RemoveStringOfLengthAtOffset() {
        let (string, remaining) = data.removeString(of: DataExtensionTests.expectedNullEncodedSubstringLength, at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - DataExtensionTests.substringOffset - string.utf8.count
        if remaining.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(remaining.count)")
            return
        }
        let index = DataExtensionTests.substringOffset + DataExtensionTests.expectedNullEncodedSubstringLength
        if remaining.count > 0 && remaining[0] != data[index] {
            XCTFail("Remaining data is at incorrect string index.")
        }
    }
    
    func test18RemovingStringOfLengthAtOffset() {
        var mutableData = data
        let string = mutableData.removingString(of: DataExtensionTests.expectedNullEncodedSubstringLength, at: DataExtensionTests.substringOffset)
        if string.isEmpty {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: empty string.")
            return
        }
        if string != DataExtensionTests.expectedNullEncodedSubstring {
            XCTFail("Expected: \(DataExtensionTests.expectedNullEncodedSubstring), received: \(string).")
            return
        }
        let expectedRemainingBytes = data.count - DataExtensionTests.substringOffset - string.utf8.count
        if mutableData.count != expectedRemainingBytes {
            XCTFail("Length of remaining data is incorrect, expected: \(expectedRemainingBytes), received: \(mutableData.count)")
            return
        }
        let index = DataExtensionTests.substringOffset + DataExtensionTests.expectedNullEncodedSubstringLength
        if mutableData.count > 0 && mutableData[0] != data[index] {
            XCTFail("Remaining data is at incorrect string index.")
        }
    }

    func test19IntOfLength1() {
        let int = data.int(of: 1)
        let expectedValue = Int(data[0])
        guard int == expectedValue else {
            XCTFail("Value is incorrect, expected \(expectedValue), received: \(int)")
            return
        }
    }

    func test20IntOfLength2() {
        let int = data.int(of: 2)
        let firstByte = Int(data[0])
        let secondByte = Int(data[1]) << 8
        let expectedValue = firstByte | secondByte
        guard int == expectedValue else {
            XCTFail("Value is incorrect, expected \(expectedValue), received: \(int)")
            return
        }
    }

    func test21IntOfLength3() {
        let int = data.int(of: 3)
        let firstByte = Int(data[0])
        let secondByte = Int(data[1]) << 8
        let thirdByte = Int(data[2]) << 16
        let expectedValue = firstByte | secondByte | thirdByte
        guard int == expectedValue else {
            XCTFail("Value is incorrect, expected \(expectedValue), received: \(int)")
            return
        }
    }

    func test22IntOfLength4() {
        let int = data.int(of: 4)
        let firstByte = Int(data[0])
        let secondByte = Int(data[1]) << 8
        let thirdByte = Int(data[2]) << 16
        let fourthByte = Int(data[3]) << 24
        let expectedValue = firstByte | secondByte | thirdByte | fourthByte
        guard int == expectedValue else {
            XCTFail("Value is incorrect, expected \(expectedValue), received: \(int)")
            return
        }
    }
}
