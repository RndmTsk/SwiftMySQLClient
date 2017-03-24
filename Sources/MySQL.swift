//
//  MySQL.swift
//  MySQLDriver
//
//  Created by Terry Latanville on 2017-03-08.
//
//

import Foundation

/// Reserve the MySQL "namespace" (similar to the Postgres client)
public class MySQL {
    // MARK: - MySQL.Constants
    public final class Constants {
        public static let maxPacketsAllowed  = 16777215
        public static let ok: UInt8          = 0x00
        public static let localInFile: UInt8 = 0xfb
        public static let eof: UInt8         = 0xfe
        public static let err: UInt8         = 0xff

        public static let okResponseMinLength  = 7
        public static let eofResponseMaxLength = 9

        public static let lenenc2ByteInt: UInt8 = 0xfc
        public static let lenenc3ByteInt: UInt8 = 0xfd
        public static let lenenc8ByteInt: UInt8 = 0xfe
    }

    public static func lsbEncoded(_ uint32: UInt32, to length: Int = MemoryLayout<UInt32>.size) -> [UInt8] {
        return lsbEncoded(UInt(uint32), to: length)
    }

    public static func lsbEncoded(_ int: Int, to length: Int = MemoryLayout<Int>.size) -> [UInt8] {
        // TODO: (TL) Sign bit??
        return lsbEncoded(UInt(int), to: length)
    }
 
    public static func lsbEncoded(_ uint: UInt, to length: Int = MemoryLayout<UInt>.size) -> [UInt8] {
        var result = [UInt8]()
        for index in 0..<length {
            let position = UInt(index) * 8 // Chunk in 8 byte segments
            // Mask the last 8 bytes to avoid overflow (= crash)
            let value = UInt8((uint >> position) & 0xff)
            result.append(value)
        }
        return result
    }

    // https://dev.mysql.com/doc/internals/en/integer.html#packet-Protocol::LengthEncodedInteger
    public static func lenenc(_ int: Int) -> [UInt8] {
        var result = [UInt8]()
        if int < 251 {
            result.append(UInt8(int & 0xff))
        } else if int <= Int.uInt16Max { // 2^16
            result.append(Constants.lenenc2ByteInt)
            result.append(contentsOf: MySQL.lsbEncoded(int, to: 2))
        } else if int <= Int.uInt24Max { // 2^24
            result.append(Constants.lenenc3ByteInt)
            result.append(contentsOf: MySQL.lsbEncoded(int, to: 3))
        } else {
            result.append(Constants.lenenc8ByteInt)
            result.append(contentsOf: MySQL.lsbEncoded(int, to: 8))
        }
        return result
    }


    public static func lenenc(_ uint: UInt) -> [UInt8] {
        guard uint <= UInt.int64Max else {
            return lenenc(Int(uint))
        }
        var result = [UInt8]()
        result.append(Constants.lenenc8ByteInt)
        result.append(contentsOf: MySQL.lsbEncoded(uint, to: 8))

        return result
    }
}
