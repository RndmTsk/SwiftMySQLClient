//
//  ColumnType.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-08.
//
//

import Foundation

/// Namespace everything with MySQL - the PostgreSQL driver does this.
public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/com-query-response.html#packet-Protocol::ColumnType

    /// A structure representing the various column types available in MySQL.
    public struct ColumnType: OptionSet { // TODO: (TL) Should this be an OptionSet or an enum?

        // MARK: - Convenience Constants
        public static let decimal     = ColumnType(rawValue: 0x00)
        public static let tiny        = ColumnType(rawValue: 0x01)
        public static let short       = ColumnType(rawValue: 0x02)
        public static let long        = ColumnType(rawValue: 0x03)
        public static let float       = ColumnType(rawValue: 0x04)
        public static let double      = ColumnType(rawValue: 0x05)
        public static let null        = ColumnType(rawValue: 0x06)
        public static let timestamp   = ColumnType(rawValue: 0x07)
        public static let longLong    = ColumnType(rawValue: 0x08)
        public static let int24       = ColumnType(rawValue: 0x09)
        public static let date        = ColumnType(rawValue: 0x0a)
        public static let time        = ColumnType(rawValue: 0x0b)
        public static let dateTime    = ColumnType(rawValue: 0x0c)
        public static let year        = ColumnType(rawValue: 0x0d)
        public static let newDate     = ColumnType(rawValue: 0x0e)
        public static let varchar     = ColumnType(rawValue: 0x0f)
        public static let bit         = ColumnType(rawValue: 0x10)
        public static let timestamp2  = ColumnType(rawValue: 0x11)
        public static let dateTime2   = ColumnType(rawValue: 0x12)
        public static let time2       = ColumnType(rawValue: 0x13)
        // JSON 0xf5?
        public static let newDecimal  = ColumnType(rawValue: 0xf6)
        public static let enumeration = ColumnType(rawValue: 0xf7)
        public static let set         = ColumnType(rawValue: 0xf8)
        public static let tinyBlob    = ColumnType(rawValue: 0xf9)
        public static let mediumBlob  = ColumnType(rawValue: 0xfa)
        public static let longBLob    = ColumnType(rawValue: 0xfb)
        public static let blob        = ColumnType(rawValue: 0xfc)
        public static let var_string  = ColumnType(rawValue: 0xfd)
        public static let string      = ColumnType(rawValue: 0xfe)
        public static let geometry    = ColumnType(rawValue: 0xff)

        // MARK: - Properties

        /// The raw `UInt8` value of the column type.
        public let rawValue: UInt8

        /**
         Constructs a `ColumnType` with the given `UInt8` value.

         - parameter rawValue: The raw `UInt8` value of the column type (bitwise OR'ed) - TODO: (TL) Do we need this type of support - NO?
         */
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
}
