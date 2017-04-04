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
    public enum Command: UInt8 {
        case sleep            = 0x00
        case quit             = 0x01
        case initDB           = 0x02
        case query            = 0x03
        case fieldList        = 0x04
        case createDB         = 0x05
        case dropDB           = 0x06
        case refresh          = 0x07
        case shutdown         = 0x08
        case statistics       = 0x09
        case processInfo      = 0x0a
        case connect          = 0x0b
        case processKill      = 0x0c
        case debug            = 0x0d
        case ping             = 0x0e
        case time             = 0x0f
        case delayedInsert    = 0x10
        case changeUser       = 0x11
        case binLogDump       = 0x12
        case tableDump        = 0x13
        case connectOut       = 0x14
        case registerSlave    = 0x15
        case stmtPrepare      = 0x16
        case stmtExecute      = 0x17
        case stmtSendLongData = 0x18
        case stmtClose        = 0x19
        case stmtReset        = 0x1a
        case setOption        = 0x1b
        case stmtFetch        = 0x1c
        case daemon           = 0x1d
        case binlogDumpGTID   = 0x1e
        case resetConnection  = 0x1f
    }
}
