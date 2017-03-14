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
