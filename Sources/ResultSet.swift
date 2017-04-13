//
//  ResultSet.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-12.
//
//

import Foundation

/* TODO: (TL):
    - Addressing via [COLUMN_NAME][ROW_ID]
    - Addressing via [COLUMN_NAME] to get full column
    - Addressing via [ROW_ID] to get full row
    - Metadata including # rows, last insert ID
 */

public extension MySQL {
    public struct ResultSet: CustomStringConvertible {
        public let affectedRows: Int
        public let lastInsertID: Int
        // private let columnData: Column // TODO: (TL)
        private let rowData: [[String]] // MySQL returns all strings

        public var description: String {
            return "RESULTSET ... TODO: (TL)"
        }

        internal init(affectedRows: Int = 0, lastInsertID: Int = 0) {
            self.init(packets: [],
                      columnCount: 0,
                      affectedRows: affectedRows,
                      lastInsertID: lastInsertID)
        }
        
        internal init(packets: ArraySlice<Packet>,
                      columnCount: Int,
                      affectedRows: Int = 0,
                      lastInsertID: Int = 0) {
            self.affectedRows = affectedRows
            self.lastInsertID = lastInsertID
            // 2. first N = column definitions, N+1..<COUNT = rows
            guard packets.count >= columnCount else {
                rowData = []
                return // TODO: (TL) Malformed
            }

            // 3. map column definitions
            let endIndex = packets.startIndex.advanced(by: columnCount)
            let columnPackets = packets[packets.startIndex..<endIndex].flatMap {
                ($0.body, false) // TODO: (TL) ...
            }.map(ColumnPacket.init)
            print(columnPackets)
            // 4. Check for EOF (if supported)
            let leftoverRange = endIndex..<packets.count
            // 5. parse rows until EOF packet
            self.rowData = ResultSet.rowPackets(from: packets[leftoverRange])
            print(rowData)
        }

        private static func rowPackets(from leftovers: ArraySlice<Packet>) -> [[String]] {
            var rows = [[String]]()
            for packet in leftovers[leftovers.startIndex..<leftovers.endIndex] {
                var remaining = packet.body
//                if remaining[0] == MySQL.Constants.eof {
//                    // TODO: (TL) Cleanup
//                    let eofPacket = EOFPacket(data: remaining.subdata(in: 1..<remaining.count), serverCapabilities: [])
//                    print("EOF: \(eofPacket)")
//                    return rows
//                }
                while remaining.count > 0 {
                    var row = [String]()
                    if remaining[0] == 0xfb { // NULL
                        remaining.droppingFirst()
                        row.append("NULL")
                    } else {
                        let length = remaining.removingLenencInt()
                        let data = remaining.removingString(of: length)
                        row.append(data)
                    }
                    rows.append(row)
                }
            }
            return rows
        }
    }
}
