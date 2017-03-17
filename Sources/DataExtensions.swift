//
//  Extensions.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-14.
//
//

import Foundation

public extension Data {
    public func nullEncodedString(at offset: Int) -> String? {
        let stringStart = startIndex.advanced(by: offset)
        var stringEnd = stringStart
        repeat {
            stringEnd += 1
        } while stringEnd < endIndex && self[stringEnd] != 0
        
        return String(data: subdata(in: stringStart..<stringEnd), encoding: .utf8)
    }

    public func removeNullEncodedString(at offset: Int) -> (value: String?, remaining: Data) {
        let string = nullEncodedString(at: offset)
        let stringLength = string?.utf8.count ?? 0
        let remainingData = subdata(in: stringLength..<count)
        return (string, remainingData)
    }

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
    public func int(of length: Int) -> Int {
        guard length > 0 else {
            return 0
        }
        guard length < MemoryLayout<Int>.size else {
            return 0 // TODO: (TL) error? (too long)
        }
        var result = 0
        for offset in 1..<length {
            result |= Int(self[offset]) << powi(2, offset - 1)
        }
        return result | Int(self[0]) // Last byte doesn't need to be shifted
    }

    public func int(of length: Int, at offsetStart: Int) -> Int {
        let offsetEnd = length + offsetStart
        guard offsetEnd < count else {
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

    public mutating func droppingFirst(_ n: Int) {
        if n < count {
            self = subdata(in: n..<count)
        } else {
            self = subdata(in: count..<count)
        }
    }

    public mutating func droppingLast(_ n: Int) {
        if n < count {
            self = subdata(in: 0..<(count - n))
        } else {
            self = subdata(in: count..<count)
        }
    }
}
