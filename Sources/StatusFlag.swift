//
//  StatusFlag.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation

public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/status-flags.html

    public struct StatusFlag: OptionSet, CustomStringConvertible {
        // MARK: - Convenience Constants
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

        // MARK: - Properties

        /// The raw `UInt16` value of the flags.
        public let rawValue: UInt16

        /// A string describing the flags that are set
        public var description: String {
            var statusStrings = [String]()
            if contains(.inTransaction) {
                statusStrings.append("In Transaction")
            }
            if contains(.autoCommit) {
                statusStrings.append("Auto Commit")
            }
            if rawValue & 0x4 == 0x4 {
                statusStrings.append("UNDOCUMENTED")
            }
            if contains(.moreResultsExists) {
                statusStrings.append("More Results Exist")
            }
            if contains(.noGoodIndexUsed) {
                statusStrings.append("No Good Index Used")
            }
            if contains(.noIndexUsed) {
                statusStrings.append("No Index Used")
            }
            if contains(.cursorExists) {
                statusStrings.append("Cursor Exists")
            }
            if contains(.lastRowSent) {
                statusStrings.append("Last Row Sent")
            }
            if contains(.dbDropped) {
                statusStrings.append("Database Dropped")
            }
            if contains(.noBackslashEscapes) {
                statusStrings.append("No Backslash Escapes")
            }
            if contains(.metadataChanged) {
                statusStrings.append("Metadata Changed")
            }
            if contains(.queryWasSlow) {
                statusStrings.append("Query Was Slow")
            }
            if contains(.psOutParams) {
                statusStrings.append("PS Out Parameters")
            }
            if contains(.statusInTransactionReadOnly) {
                statusStrings.append("In Readonly Transaction")
            }
            if contains(.sessionStateChanged) {
                statusStrings.append("Session State Changed")
            }
            var desc = "Status Flags: \(rawValue)"
            for string in statusStrings {
                desc.append("\n    -- \(string)")
            }
            return desc
        }

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }
}
