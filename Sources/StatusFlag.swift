//
//  StatusFlag.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation

public extension MySQL {
    public struct StatusFlag: OptionSet {
        public let rawValue: UInt16
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        // https://dev.mysql.com/doc/internals/en/status-flags.html
        public static let inTransaction               = StatusFlag(rawValue: 0x0001)
        public static let autoCommit                  = StatusFlag(rawValue: 0x0002)
        // 0x0004 is undocumented
        public static let moreResultsExists           = StatusFlag(rawValue: 0x0008)
        public static let noGoodIndexUsed             = StatusFlag(rawValue: 0x0010)
        public static let noIndexUsed                 = StatusFlag(rawValue: 0x0020)
        public static let cursorExists                = StatusFlag(rawValue: 0x0040)
        public static let lastRowSent                 = StatusFlag(rawValue: 0x0080)
        public static let dbDropped                   = StatusFlag(rawValue: 0x0100)
        public static let noBackslashEscapes          = StatusFlag(rawValue: 0x0200)
        public static let metadataChanged             = StatusFlag(rawValue: 0x0400)
        public static let queryWasSlow                = StatusFlag(rawValue: 0x0800)
        public static let psOutParams                 = StatusFlag(rawValue: 0x1000)
        public static let statusInTransactionReadOnly = StatusFlag(rawValue: 0x2000)
        public static let sessionStateChanged         = StatusFlag(rawValue: 0x4000)
    }
}
