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
        // MARK: - Constants
        internal static let empty = ResultSet(packets: [], columnCount: 0)

        // MARK: - Properties
        public let affectedRows: Int
        public let lastInsertID: Int
        private let columns: [Column]
        private let rows: [[String]] // MySQL returns all strings

        public var description: String {
            return "RESULTSET ... TODO: (TL)"
        }

        // MARK: - Lifecycle Functions
        internal init(packets: ArraySlice<Packet>,
                      columnCount: Int,
                      affectedRows: Int = 0,
                      lastInsertID: Int = 0) {
            self.affectedRows = affectedRows
            self.lastInsertID = lastInsertID
            // 2. first N = column definitions, N+1..<COUNT = rows
            guard packets.count >= columnCount else {
                columns = []
                rows = []
                return // TODO: (TL) Malformed
            }

            // 3. map column definitions
            let endIndex = packets.startIndex.advanced(by: columnCount)
            self.columns = packets[packets.startIndex..<endIndex].flatMap {
                ($0.body, false) // TODO: (TL) ...
            }.map(Column.init)
            print(columns) // TODO: (TL) ...
            // 4. Check for EOF (if supported)
            let leftoverRange = endIndex..<packets.count
            // 5. parse rows until EOF packet
            self.rows = ResultSet.rowPackets(from: packets[leftoverRange])
            print(rows)
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
