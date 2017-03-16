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
    }
}

public func powi(_ base: Int, _ exponent: Int) -> Int {
    // Using pow this way is stupid ...
    return Int(pow(Float(base), Float(exponent)))
}
