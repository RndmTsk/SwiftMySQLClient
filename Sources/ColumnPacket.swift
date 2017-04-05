//
//  ColumnPacket.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-04.
//
//

import Foundation

public struct ColumnPacket: CustomStringConvertible {
    public let length: Int

    public var description: String {
        return "TODO: (TL)"
    }

    init(data: Data) {
        var remaining = data
        print(">>>COLUMN PACKET<<<")
        var oldLength = remaining.count
        let catalogLength = remaining.removingLenencInt()
        print("Catalog Length: \(catalogLength) [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let catalog = remaining.removingString(of: catalogLength)
        print("Catalog: \(catalog) [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let schemaLength = remaining.removingLenencInt()
        print("Schema length: \(schemaLength) [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let schema = remaining.removingString(of: schemaLength)
        print("Schema: \(schema) [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let tableLength = remaining.removingLenencInt()
        print("Table Length: \(tableLength)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let table = remaining.removingString(of: tableLength)
        print("Table: \(table)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let orgTableLength = remaining.removingLenencInt()
        print("Org Table Length: \(orgTableLength)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let orgTable = remaining.removingString(of: orgTableLength)
        print("Org Table: \(orgTable)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let nameLength = remaining.removingLenencInt()
        print("Name Length: \(nameLength)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let name = remaining.removingString(of: nameLength)
        print("Name: \(name)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let orgNameLength = remaining.removingLenencInt()
        print("Org Name Length: \(orgNameLength)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let orgName = remaining.removingString(of: orgNameLength)
        print("Org Name: \(orgName)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let fixedLengthFieldLength = remaining.removingLenencInt()
        print("Fixed Length Field Length: \(fixedLengthFieldLength)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let characterSet = remaining.removingInt(of: 2)
        print("Character Set: \(characterSet)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let columnLength = remaining.removingInt(of: 4)
        print("Column Length: \(columnLength)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let type = remaining.removingInt(of: 1)
        print("Type: \(type)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let flags = remaining.removingInt(of: 2)
        print("Flags: \(flags)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let decimals = remaining.removingInt(of: 1)
        print("Decimals: \(decimals)  [R: \(oldLength - remaining.count)]")
        oldLength = remaining.count
        let filler = remaining.removingInt(of: 2)
        print("Filler: \(filler)  [R: \(oldLength - remaining.count)]")
        /* TODO: (TL)
        if command was COM_FIELD_LIST {
            lenenc_int length of default-values
            string[$len] default values
        }
         */
        print("D: \(data.count), R: \(remaining.count)")
        self.length = data.count - remaining.count
        
        print(">>>COLUMN PACKET<<<")
    }
}
