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
    public enum Command: UInt8, CustomStringConvertible {
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

        public var description: String {
            switch self {
            case .sleep:
                return "COM_SLEEP"
            case .quit:
                return "COM_QUIT"
            case .initDB:
                return "COM_INIT_DB"
            case .query:
                return "COM_QUERY"
            case .fieldList:
                return "COM_FIELD_LIST"
            case .createDB:
                return "COM_CREATE_DB"
            case .dropDB:
                return "COM_DROP_DB"
            case .refresh:
                return "COM_REFRESH"
            case .shutdown:
                return "COM_SHUTDOWN"
            case .statistics:
                return "COM_STATISTICS"
            case .processInfo:
                return "COM_PROCESS_INFO"
            case .connect:
                return "COM_CONNECT"
            case .processKill:
                return "COM_PROCESS_KILL"
            case .debug:
                return "COM_DEBUG"
            case .ping:
                return "COM_PING"
            case .time:
                return "COM_TIME"
            case .delayedInsert:
                return "COM_DELAYED_INSERT"
            case .changeUser:
                return "COM_CHANGE_USER"
            case .binLogDump:
                return "COM_BIN_LOG_DUMP"
            case .tableDump:
                return "COM_TABLE_DUMP"
            case .connectOut:
                return "COM_CONNECT_OUT"
            case .registerSlave:
                return "COM_REGISTER_SLAVE"
            case .stmtPrepare:
                return "COM_STMT_PREPARE"
            case .stmtExecute:
                return "COM_STMT_EXECUTE"
            case .stmtSendLongData:
                return "COM_STMT_SEND_LONG_DATA"
            case .stmtClose:
                return "COM_STMT_CLOSE"
            case .stmtReset:
                return "COM_STMT_RESET"
            case .setOption:
                return "COM_SET_OPTION"
            case .stmtFetch:
                return "COM_STMT_FETCH"
            case .daemon:
                return "COM_DAEMON"
            case .binlogDumpGTID:
                return "COM_BIN_LOG_DUMP_GTID"
            case .resetConnection:
                return "COM_RESET_CONNECTION"
            }
        }
    }
}
