//
//  ColumnPacket.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-04.
//
//

import Foundation

extension MySQL {

    public struct ColumnPacket: CustomStringConvertible {
        public let catalog: String
        public let schema: String
        public let table: String
        public let originalTable: String
        public let columnName: String
        public let originalColumnName: String
        public let characterSet: Int
        public let columnLength: Int
        public let dataType: Int
        public let flags: Int // TODO: (TL) Map to one of our OptionSets
        public let decimals: Int
        public let length: Int

        public var description: String {
            return "CATALOG: \(catalog)\nSCHEMA: \(schema)\nTABLE: \(table)\nORIGINAL TABLE: \(originalTable)\nCOLUMN NAME: \(columnName)\nORIGINAL COLUMN NAME: \(originalColumnName)\nCHARACTER SET: \(characterSet)\nCOLUMN LENGTH: \(columnLength)\nDATA TYPE: \(dataType)\nFLAGS: \(flags)\nDECIMALS: \(decimals)\nLENGTH: \(length)"
        }

        init(data: Data, command: Command) {
            print(">>>COLUMN PACKET<<<")
            var remaining = data
            // Catalog
            let catalogLength = remaining.removingLenencInt()
            self.catalog = remaining.removingString(of: catalogLength)

            // Schema (Database)
            let schemaLength = remaining.removingLenencInt()
            self.schema = remaining.removingString(of: schemaLength)

            // Table
            let tableLength = remaining.removingLenencInt()
            self.table = remaining.removingString(of: tableLength)

            // Original Table (different if renamed)
            let orgTableLength = remaining.removingLenencInt()
            self.originalTable = remaining.removingString(of: orgTableLength)

            // Column Name
            let nameLength = remaining.removingLenencInt()
            self.columnName = remaining.removingString(of: nameLength)

            // Original Column Name (different if renamed)
            let orgNameLength = remaining.removingLenencInt()
            self.originalColumnName = remaining.removingString(of: orgNameLength)

            // ???
            _ = remaining.removingLenencInt() // Fixed field length?

            // Character Set
            self.characterSet = remaining.removingInt(of: 2)

            // Column Length - TODO: (TL) ??
            self.columnLength = remaining.removingInt(of: 4)

            // Type ??
            self.dataType = remaining.removingInt(of: 1)

            // Flags
            self.flags = remaining.removingInt(of: 2)

            // Decimals ??
            self.decimals = remaining.removingInt(of: 1)

            _ = remaining.removingInt(of: 2) // 2 bytes of filler [0, 0]

            /* TODO: (TL) ...
            if command was COM_FIELD_LIST {
                lenenc_int length of default-values
                string[$len] default values
            }
             */
            print("IN: \(data.count), LEFTOVER: \(remaining.count)")
            self.length = data.count - remaining.count
            print(self)
            print(">>>COLUMN PACKET<<<")
        }
    }
}