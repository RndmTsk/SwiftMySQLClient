//
//  CapabilityFlag.swift
//  MySQLDriver
//
//  Created by Terry Latanville on 2017-03-08.
//
//

import Foundation

public extension MySQL {
    public struct CapabilityFlag: OptionSet {
        public let rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        // https://dev.mysql.com/doc/internals/en/capability-flags.html#packet-Protocol::CapabilityFlag
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
    }
}
