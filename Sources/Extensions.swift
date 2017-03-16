//
//  Extensions.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-14.
//
//

import Foundation

public extension UInt32 {
    public func uint8Value(at position: UInt32) -> UInt8 {
        return UInt8((self >> position) & 0xff)
    }

    public var uint8Array: [UInt8] {
        return [
            self.uint8Value(at: 24),
            self.uint8Value(at: 16),
            self.uint8Value(at: 8),
            self.uint8Value(at: 0)
        ]
    }
}

public extension Data {
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

    public func int(of length: Int) -> Int {
        guard length < 8 else { // TODO: (TL) Sizeof(Int)
            return 0 // TODO: (TL) error? (too long)
        }
        var result = 0
        for offset in 1..<length {
            let shiftAmount = Int(pow(2, Float(offset - 1)))
            result |= Int(self[offset]) << shiftAmount // Using pow this way is stupid ...
        }
        return result | Int(self[0]) // Last byte doesn't need to be shifted
    }
}
