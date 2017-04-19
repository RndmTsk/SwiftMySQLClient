//
//  UInt8Mappable.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-19.
//
//

import Foundation

public protocol UInt8LSBArrayMappable {
    var asUInt8Array: [UInt8] { get }
}

extension UInt8: UInt8LSBArrayMappable {
    public var asUInt8Array: [UInt8] {
        return [self]
    }
}

extension UInt16: UInt8LSBArrayMappable {
    public var asUInt8Array: [UInt8] {
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff)]
    }
}

extension UInt32: UInt8LSBArrayMappable {
    public var asUInt8Array: [UInt8] {
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff), UInt8((self >> 16) & 0xff)]
    }
}

extension UInt64: UInt8LSBArrayMappable {
    public var asUInt8Array: [UInt8] {
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff), UInt8((self >> 16) & 0xff), UInt8((self >> 24) & 0xff)]
    }
}

extension Int: UInt8LSBArrayMappable {
    public var asUInt8Array: [UInt8] {
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff), UInt8((self >> 16) & 0xff), UInt8((self >> 24) & 0xff)]
    }
}

extension UInt: UInt8LSBArrayMappable {
    public var asUInt8Array: [UInt8] {
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff), UInt8((self >> 16) & 0xff), UInt8((self >> 24) & 0xff)]
    }
}

extension String: UInt8LSBArrayMappable {
    public var asUInt8Array: [UInt8] {
        return [UInt8](self.utf8)
    }
}
