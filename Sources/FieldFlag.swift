//
//  FieldFlag.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-08.
//
//

import Foundation

public extension MySQL {
    public struct FieldFlag: OptionSet {
        public let rawValue: UInt16
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        // TODO: (TL) Reference?
        public static let notNull       = FieldFlag(rawValue: 0x0001)
        public static let priKey        = FieldFlag(rawValue: 0x0002)
        public static let uniqueKey     = FieldFlag(rawValue: 0x0004)
        public static let multipleKey   = FieldFlag(rawValue: 0x0008)
        public static let blob          = FieldFlag(rawValue: 0x0010)
        public static let unsigned      = FieldFlag(rawValue: 0x0020)
        public static let zeroFill      = FieldFlag(rawValue: 0x0040)
        public static let binary        = FieldFlag(rawValue: 0x0080)
        public static let enumeration   = FieldFlag(rawValue: 0x0100)
        public static let autoIncrement = FieldFlag(rawValue: 0x0200)
        public static let timestamp     = FieldFlag(rawValue: 0x0400)
        public static let set           = FieldFlag(rawValue: 0x0800)
    }
}
