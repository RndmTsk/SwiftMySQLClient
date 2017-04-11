//
//  CapabilityFlag.swift
//  MySQLDriver
//
//  Created by Terry Latanville on 2017-03-08.
//
//

import Foundation

/// Namespace everything with MySQL - the PostgreSQL driver does this.
public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/capability-flags.html#packet-Protocol::CapabilityFlag

    /// A structure representing the various capabilities supported by the client or server.
    public struct CapabilityFlag: OptionSet, CustomStringConvertible {
        // MARK: - Convenience Constants
        public static let clientLongPassword              = CapabilityFlag(rawValue: 0x00000001)
        public static let clientFoundRows                 = CapabilityFlag(rawValue: 0x00000002)
        public static let clientLongFlag                  = CapabilityFlag(rawValue: 0x00000004)
        public static let clientConnectWithDB             = CapabilityFlag(rawValue: 0x00000008)
        public static let clientNoSchema                  = CapabilityFlag(rawValue: 0x00000010)
        public static let clientCompress                  = CapabilityFlag(rawValue: 0x00000020)
        public static let clientODBC                      = CapabilityFlag(rawValue: 0x00000040)
        public static let clientLocalFiles                = CapabilityFlag(rawValue: 0x00000080)
        public static let clientIgnoreSpace               = CapabilityFlag(rawValue: 0x00000100)
        public static let clientProtocol41                = CapabilityFlag(rawValue: 0x00000200)
        public static let clientInteractive               = CapabilityFlag(rawValue: 0x00000400)
        public static let clientSSL                       = CapabilityFlag(rawValue: 0x00000800)
        public static let clientIgnoreSigpipe             = CapabilityFlag(rawValue: 0x00001000)
        public static let clientTransactions              = CapabilityFlag(rawValue: 0x00002000)
        public static let clientReserved                  = CapabilityFlag(rawValue: 0x00004000)
        public static let clientSecureConnection          = CapabilityFlag(rawValue: 0x00008000)
        public static let clientMultiStatements           = CapabilityFlag(rawValue: 0x00010000)
        public static let clientMultiResults              = CapabilityFlag(rawValue: 0x00020000)
        public static let clientPSMultiResults            = CapabilityFlag(rawValue: 0x00040000)
        public static let clientPluginAuth                = CapabilityFlag(rawValue: 0x00080000)
        public static let clientConnectAttrs              = CapabilityFlag(rawValue: 0x00100000)
        public static let clientPluginAuthLenecClientData = CapabilityFlag(rawValue: 0x00200000)
        public static let clientCanHandleExpiredPasswords = CapabilityFlag(rawValue: 0x00400000)
        public static let clientSessionTrack              = CapabilityFlag(rawValue: 0x00800000)
        public static let clientDeprecateEOF              = CapabilityFlag(rawValue: 0x01000000)

        // MARK: - Properties

        /// The raw `UInt32` value of the flags.
        public let rawValue: UInt32

        /// A string describing the flags that are set
        public var description: String {
            var capabilityStrings = [String]()
            if contains(.clientLongPassword) {
                capabilityStrings.append("Long Password")
            }
            if contains(.clientFoundRows) {
                capabilityStrings.append("Found Rows")
            }
            if contains(.clientLongFlag) {
                capabilityStrings.append("Long Flag")
            }
            if contains(.clientConnectWithDB) {
                capabilityStrings.append("Connect with Database")
            }
            if contains(.clientNoSchema) {
                capabilityStrings.append("No Schema")
            }
            if contains(.clientCompress) {
                capabilityStrings.append("Compress")
            }
            if contains(.clientODBC) {
                capabilityStrings.append("ODBC")
            }
            if contains(.clientLocalFiles) {
                capabilityStrings.append("Local Files")
            }
            if contains(.clientIgnoreSpace) {
                capabilityStrings.append("Ignore Space")
            }
            if contains(.clientProtocol41) {
                capabilityStrings.append("Client Protocol 41")
            }
            if contains(.clientInteractive) {
                capabilityStrings.append("Interactive")
            }
            if contains(.clientSSL) {
                capabilityStrings.append("SSL")
            }
            if contains(.clientIgnoreSigpipe) {
                capabilityStrings.append("Ignore Sigpipe")
            }
            if contains(.clientTransactions) {
                capabilityStrings.append("Transactions")
            }
            if contains(.clientReserved) {
                capabilityStrings.append("Reserved - ERROR")
            }
            if contains(.clientSecureConnection) {
                capabilityStrings.append("Secure Connection")
            }
            if contains(.clientMultiStatements) {
                capabilityStrings.append("Multi Statements")
            }
            if contains(.clientMultiResults) {
                capabilityStrings.append("Multi Results")
            }
            if contains(.clientPSMultiResults) {
                capabilityStrings.append("PS Multi Results")
            }
            if contains(.clientPluginAuth) {
                capabilityStrings.append("Plugin: AUTH")
            }
            if contains(.clientConnectAttrs) {
                capabilityStrings.append("Connection Attributes")
            }
            if contains(.clientPluginAuthLenecClientData) {
                capabilityStrings.append("Plugin: AUTH Length Encoded Client Data")
            }
            if contains(.clientCanHandleExpiredPasswords) {
                capabilityStrings.append("Can Handle Expired Passwords")
            }
            if contains(.clientSessionTrack) {
                capabilityStrings.append("Session Tracking")
            }
            if contains(.clientDeprecateEOF) {
                capabilityStrings.append("Deprecate EOF")
            }
            var desc = "Capabilities: \(rawValue)"
            for string in capabilityStrings {
                desc.append("\n    -- \(string)")
            }
            return desc
        }

        // MARK: - Lifecycle Functions

        /**
         Constructs a `CapabilityFlag` with the given raw `UInt32` value.

         - parameter rawValue: The raw `UInt32` value of the flags (bitwise OR'ed).
         */
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        // MARK: - Static Helper Functions

        /**
         A helper function to build a `CapabilityFlag` given a separate lower 16 bits and upper 16 bits.

         - parameter upper: The upper 16 bits of the `CapabilityFlag`.
         - parameter lower: The lower 16 bits of the `CapabilityFlag`.
         - returns: A `CapabilityFlag` where the upper bits are shifted and bitwise OR'ed with the lower bits.
         */
        public static func with(upper: CapabilityFlag, lower: CapabilityFlag) -> CapabilityFlag {
            return CapabilityFlag(rawValue: upper.rawValue | lower.rawValue)
        }
    }
}
