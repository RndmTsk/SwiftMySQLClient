//
//  IntExtensions.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-17.
//
//

import Foundation

public extension Int {
    public static var int8Max: Int {
        return Int(Int8.max)
    }
    public static var uInt8Max: Int {
        return Int(UInt8.max)
    }
    
    public static var int16Max: Int {
        return Int(Int16.max)
    }
    public static var uInt16Max: Int {
        return Int(UInt16.max)
    }
    
    public static var int24Max: Int {
        return Int(Int32.max & 0xffffff) // Mask to 24 bits
    }
    public static var uInt24Max: Int {
        return Int(UInt32.max & 0xffffff)
    }
    
    public static var int32Max: Int {
        return Int(Int32.max)
    }
    public static var uInt32Max: Int {
        return Int(UInt32.max)
    }
    
    public static var int64Max: Int {
        return Int(Int64.max)
    }
}

public extension UInt {
    public static var int8Max: UInt {
        return UInt(Int8.max)
    }
    public static var uInt8Max: UInt {
        return UInt(UInt8.max)
    }

    public static var int16Max: UInt {
        return UInt(Int16.max)
    }
    public static var uInt16Max: UInt {
        return UInt(UInt16.max)
    }

    public static var int24Max: UInt {
        return UInt(Int32.max & 0xffffff) // Mask to 24 bits
    }
    public static var uInt24Max: UInt {
        return UInt(UInt32.max & 0xffffff)
    }

    public static var int32Max: UInt {
        return UInt(Int32.max)
    }
    public static var uInt32Max: UInt {
        return UInt(UInt32.max)
    }

    public static var int64Max: UInt {
        return UInt(Int64.max)
    }

    public static var uInt64Max: UInt {
        return UInt(UInt64.max)
    }
}
