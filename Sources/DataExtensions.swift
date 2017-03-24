//
//  Extensions.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-14.
//
//

import Foundation

public extension Data {
    // MARK: - String Functions
    public func nullEncodedString(at offset: Int = 0, with encoding: String.Encoding = .utf8) -> String {
        return encodedString(at: offset, terminator: 0, with: encoding)
    }

    public func removeNullEncodedString(at offset: Int = 0, with encoding: String.Encoding = .utf8) -> (value: String, remaining: Data) {
        let string = nullEncodedString(at: offset, with: encoding)
        let stringEndIndex = remainingLength(after: string, at: offset)
        let remainingData = subdata(in: stringEndIndex..<count)
        return (string, remainingData)
    }

    public mutating func removingNullEncodedString(at offset: Int = 0, with encoding: String.Encoding = .utf8) -> String {
        let (string, data) = removeNullEncodedString(at: offset, with: encoding)
        self = data
        return string
    }

    public func eofEncodedString(at offset: Int = 0, with encoding: String.Encoding = .utf8) -> String {
        return encodedString(at: offset, terminator: MySQL.Constants.eof)
    }

    public func removeEOFEncodedString(at offset: Int = 0, with encoding: String.Encoding = .utf8) -> (value: String, remaining: Data) {
        let string = eofEncodedString(at: offset, with: encoding)
        let stringEndIndex = remainingLength(after: string, at: offset)
        let remainingData = subdata(in: stringEndIndex..<count)
        return (string, remainingData)
    }

    public mutating func removingEOFEncodedString(at offset: Int = 0, with encoding: String.Encoding = .utf8) -> String {
        let (string, data) = removeEOFEncodedString(at: offset, with: encoding)
        self = data
        return string
    }

    public func string(of length: Int, at offset: Int = 0, with encoding: String.Encoding = .utf8) -> String {
        // Using `min` throws a compiler error ...
        let stringStart = startIndex + offset < count ? startIndex.advanced(by: offset) : count
        let stringEnd = offset + length < count ? offset.advanced(by: length) :  count
        return String(data: subdata(in: stringStart..<stringEnd), encoding: encoding) ?? ""
    }

    public func removeString(of length: Int, at offset: Int = 0, with encoding: String.Encoding = .utf8) -> (value: String, remaining: Data) {
        let fixedLengthString = string(of: length, at: offset, with: encoding)
        let stringEndIndex = remainingLength(after: fixedLengthString, at: offset, 0)
        return (fixedLengthString, subdata(in: stringEndIndex..<count))
    }

    public mutating func removingString(of length: Int, at offset: Int = 0, with encoding: String.Encoding = .utf8) -> String {
        let (string, data) = removeString(of: length, at: offset, with: encoding)
        self = data
        return string
    }

    public func encodedString(at offset: Int = 0, terminator value: UInt8 = 0, with encoding: String.Encoding = .utf8) -> String {
        let stringStart = startIndex.advanced(by: offset)
        var stringEnd = stringStart
        repeat {
            stringEnd += 1
        } while stringEnd < endIndex && self[stringEnd] != value
        
        return String(data: subdata(in: stringStart..<stringEnd), encoding: encoding) ?? ""
    }

    // MARK: - String Helper Functions
    private func remainingLength(after string: String, at offset: Int = 0, _ terminatorLength: Int = 1) -> Int {
        let index: Int
        if string.isEmpty {
            index = offset + terminatorLength
        } else {
            index = offset + string.utf8.count + terminatorLength
        }
        return count < index ? count : index
    }

    // MARK: - [UInt8] Functions
    public func removeFirstBytes(_ n: Int) -> (value: [UInt8] , remaining: Data) {
        var data = self
        let length = n < count ? n : count
        let value = Array(data[0..<length])
        var startIndex = length + 1
        if count < startIndex {
            startIndex = count
        }
        let remaining = data.subdata(in: startIndex..<count)
        return (value, remaining)
    }

    public mutating func removingFirstBytes(_ n: Int) -> [UInt8] {
        let (result, data) = removeFirstBytes(n)
        self = data
        return result
    }

    // MARK: - Int Functions
    public var lenencInt: (value: Int, remaining: Data) {
        guard let typeFlag = self.first else {
            return (0, self)
        }
        let length: Int
        if typeFlag < 0xfb { // 1-byte integer
            length = 1
        } else if typeFlag == 0xfc { // 2-byte integer
            length = 2
        } else if typeFlag == 0xfd { // 3-byte integer
            length = 3
        } else if typeFlag == 0xfe { // 8-byte integer
            length = 8
        } else {
            length = 0
        }
        // TODO: (TL) handle 0xfb (NULL) and 0xff (ERROR)
        
        return (int(of: length), subdata(in: length..<count))
    }

    // TODO: (TL) uint of length
    // TODO: (TL) uint8
    public func removedInt(of length: Int) -> (value: Int, remaining: Data) {
        let value = int(of: length)
        let end = length < count ? length : count // Why doesn't min(length, count) compile?
        return (value, subdata(in: 0..<end))
    }

    public mutating func removingInt(of length: Int) -> Int {
        let value = int(of: length)
        droppingFirst(length)

        return value
    }

    public func int(of length: Int) -> Int {
        guard length > 0 else {
            return 0
        }
        guard length < MemoryLayout<Int>.size else {
            return 0 // TODO: (TL) error? (too long)
        }
        var result = 0
        for offset in 0..<length {
            result |= Int(self[offset]) << (8 * offset)
        }
        return result
    }

    public func int(of length: Int, at offsetStart: Int) -> Int {
        let offsetEnd = length + offsetStart
        guard offsetStart < count,
            offsetEnd < count,
            offsetStart < offsetEnd else {
            return 0 // TODO: (TL) error? (too long)
        }
        return subdata(in: offsetStart..<offsetEnd).int(of: length)
    }

    public var uInt16: UInt16 {
        guard let firstByte = self.first else {
            return 0 // TODO: (TL) Throw?
        }
        if count == 1 {
            return UInt16(firstByte)
        }
        return UInt16(self[1]) << 8 | UInt16(firstByte)
    }

    public mutating func droppingFirst(_ n: Int = 1) {
        if n < count {
            self = subdata(in: n..<count)
        } else {
            self = subdata(in: count..<count)
        }
    }

    public mutating func droppingLast(_ n: Int = 1) {
        if n < count {
            self = subdata(in: 0..<(count - n))
        } else {
            self = subdata(in: count..<count)
        }
    }
}
