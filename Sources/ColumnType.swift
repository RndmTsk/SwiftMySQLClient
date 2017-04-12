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
    public struct ColumnType: RawRepresentable, CustomStringConvertible {
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
        public let rawValue: UInt8

        public var description: String {
            if rawValue == ColumnType.decimal.rawValue {
                return "Decimal"
            } else if rawValue == ColumnType.tiny.rawValue {
                return "Tiny"
            } else if rawValue == ColumnType.short.rawValue {
                return "Short"
            } else if rawValue == ColumnType.long.rawValue {
                return "Long"
            } else if rawValue == ColumnType.float.rawValue {
                return "Float"
            } else if rawValue == ColumnType.double.rawValue {
                return "Double"
            } else if rawValue == ColumnType.null.rawValue {
                return "Null"
            } else if rawValue == ColumnType.timestamp.rawValue {
                return "Timestamp"
            } else if rawValue == ColumnType.longLong.rawValue {
                return "Long Long"
            } else if rawValue == ColumnType.int24.rawValue {
                return "Int 24"
            } else if rawValue == ColumnType.date.rawValue {
                return "Date"
            } else if rawValue == ColumnType.time.rawValue {
                return "Time"
            } else if rawValue == ColumnType.dateTime.rawValue {
                return "Date Time"
            } else if rawValue == ColumnType.year.rawValue {
                return "Year"
            } else if rawValue == ColumnType.newDate.rawValue {
                return "New Date"
            } else if rawValue == ColumnType.varchar.rawValue {
                return "Varchar"
            } else if rawValue == ColumnType.bit.rawValue {
                return "Bit"
            } else if rawValue == ColumnType.timestamp2.rawValue {
                return "Timestamp 2"
            } else if rawValue == ColumnType.dateTime2.rawValue {
                return "Date Time 2"
            } else if rawValue == ColumnType.time2.rawValue {
                return "Time 2"
            // JSON 0xf5?

            } else if rawValue == ColumnType.newDecimal.rawValue {
                return "New Decimal"
            } else if rawValue == ColumnType.enumeration.rawValue {
                return "Enumeration"
            } else if rawValue == ColumnType.set.rawValue {
                return "Set"
            } else if rawValue == ColumnType.tinyBlob.rawValue {
                return "Tiny Blob"
            } else if rawValue == ColumnType.mediumBlob.rawValue {
                return "Medium Blob"
            } else if rawValue == ColumnType.longBLob.rawValue {
                return "Long Blob"
            } else if rawValue == ColumnType.blob.rawValue {
                return "Blob"
            } else if rawValue == ColumnType.var_string.rawValue {
                return "Var String"
            } else if rawValue == ColumnType.string.rawValue {
                return "String"
            } else if rawValue == ColumnType.geometry.rawValue {
                return "Geometry"
            } else {
                return "Unknown"
            }
        }

        // MARK: - Lifecycle Functions
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
}
