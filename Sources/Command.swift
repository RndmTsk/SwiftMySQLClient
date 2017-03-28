//
//  Command.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-08.
//
//

import Foundation

/// Namespace everything with MySQL - the PostgreSQL driver does this.
public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/command-phase.html

    /// A structure representing the various commands supported by MySQL.
    public struct Command: OptionSet { // TODO: (TL) Should this be an OptionSet or an enum?
        // MARK: - Convenience Constants
        public static let sleep            = Command(rawValue: 0x00)
        public static let quit             = Command(rawValue: 0x01)
        public static let initDB           = Command(rawValue: 0x02)
        public static let query            = Command(rawValue: 0x03)
        public static let fieldList        = Command(rawValue: 0x04)
        public static let createDB         = Command(rawValue: 0x05)
        public static let dropDB           = Command(rawValue: 0x06)
        public static let refresh          = Command(rawValue: 0x07)
        public static let shutdown         = Command(rawValue: 0x08)
        public static let statistics       = Command(rawValue: 0x09)
        public static let processInfo      = Command(rawValue: 0x0a)
        public static let connect          = Command(rawValue: 0x0b)
        public static let processKill      = Command(rawValue: 0x0c)
        public static let debug            = Command(rawValue: 0x0d)
        public static let ping             = Command(rawValue: 0x0e)
        public static let time             = Command(rawValue: 0x0f)
        public static let delayedInsert    = Command(rawValue: 0x10)
        public static let changeUser       = Command(rawValue: 0x11)
        public static let binLogDump       = Command(rawValue: 0x12)
        public static let tableDump        = Command(rawValue: 0x13)
        public static let connectOut       = Command(rawValue: 0x14)
        public static let registerSlave    = Command(rawValue: 0x15)
        public static let stmtPrepare      = Command(rawValue: 0x16)
        public static let stmtExecute      = Command(rawValue: 0x17)
        public static let stmtSendLongData = Command(rawValue: 0x18)
        public static let stmtClose        = Command(rawValue: 0x19)
        public static let stmtReset        = Command(rawValue: 0x1a)
        public static let setOption        = Command(rawValue: 0x1b)
        public static let stmtFetch        = Command(rawValue: 0x1c)
        public static let daemon           = Command(rawValue: 0x1d)
        public static let binlogDumpGTID   = Command(rawValue: 0x1e)
        public static let resetConnection  = Command(rawValue: 0x1f)

        // MARK: - Properties

        /// The raw `UInt8` value of the column type.
        public let rawValue: UInt8

        /**
         Constructs a `Command` with the given `UInt8` value.
         
         - parameter rawValue: The raw `UInt8` value of the command (bitwise OR'ed) - TODO: (TL) Do we need this type of support - NO?
         */
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
}
