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
        fileprivate struct Constants {
            static let null: UInt8 = 0xfb
        }
        internal static let empty = ResultSet()

        // MARK: - Properties
        public let affectedRows: Int
        public let lastInsertID: Int
        public let statementID: Int
        public let columnNames: [String]
        public let data: [[String : String]]
        private let columns: [Column] // TODO: (TL) Maybe expose this?
        private let rows: [[String]] // TODO: (TL) MySQL returns all strings - save as Any instead?

        public var description: String {
            var desc = "Result Set"
            var detailStrings = [
                "Affected Rows: \(affectedRows)",
                "Last Insert ID: \(lastInsertID)",
            ]
            if columns.count > 0 {
                let columnNames = columns.flatMap {
                    $0.columnName
                }.joined(separator: ", ")
                detailStrings.append(columnNames)
            }
            for row in rows {
                detailStrings.append(row.joined(separator: ", "))
            }
            for string in detailStrings {
                desc.append("\n    - \(string)")
            }
            return desc
        }

        // MARK: - Lifecycle Functions
        internal init(packets: ArraySlice<Packet> = [],
                      columnCount: Int = 0,
                      affectedRows: Int = 0,
                      lastInsertID: Int = 0,
                      statementID: Int = 0) {
            self.affectedRows = affectedRows
            self.lastInsertID = lastInsertID
            self.statementID = statementID
            // 1. first N = column definitions, N+1..<COUNT = rows
            guard columnCount > 0, packets.count >= columnCount else {
                self.columnNames = []
                self.columns = []
                self.rows = []
                self.data = []
                return
            }

            // 2. map column definitions
            let endIndex = packets.startIndex.advanced(by: columnCount)
            let columns = packets[packets.startIndex..<endIndex].flatMap {
                ($0.body, false)
            }.map(Column.init)
            // 3. Check for EOF (if supported)
            let leftoverRange = endIndex..<packets.count
            // 4. parse rows until EOF packet
            let rows = ResultSet.rowPackets(from: packets[leftoverRange])
            self.columnNames = columns.flatMap { $0.columnName }
            self.columns = columns
            self.rows = rows

            // 5. Compose the data once so it's easily addressable
            // TODO: (TL) Likely can be improved
            var mappedData = [[String : String]]()
            for (rowIndex, row) in rows.enumerated() {
                var columnData = [String : String]()
                for (columnIndex, column) in columns.enumerated() {
                    columnData[column.columnName] = row[columnIndex]
                }
                mappedData.append(columnData)
            }
            self.data = mappedData
        }

        // MARK: - Access Functions
        public subscript(index: Int) -> [String : String] {
            return data[index]
        }

        public subscript(columnName: String) -> [String] {
            guard let columnIndex = columns.index(where: { $0.columnName == columnName }) else {
                return []
            }
            return rows.flatMap {
                $0[columnIndex]
            }
        }

        // MARK: - Helper Functions
        private static func rowPackets(from leftovers: ArraySlice<Packet>) -> [[String]] {
            var rows = [[String]]()
            for packet in leftovers[leftovers.startIndex..<leftovers.endIndex] {
                var remaining = packet.body
                // TODO: (TL) Check capabilities
//                if remaining[0] == MySQL.Constants.eof {
//                    // TODO: (TL) Cleanup
//                    let eofPacket = EOFPacket(data: remaining.subdata(in: 1..<remaining.count), serverCapabilities: [])
//                    print("EOF: \(eofPacket)")
//                    return rows
//                }
                var row = [String]()
                while remaining.count > 0 {
                    if remaining[0] == Constants.null {
                        remaining.droppingFirst()
                        row.append("NULL")
                    } else {
                        let length = remaining.removingLenencInt()
                        let data = remaining.removingString(of: length)
                        row.append(data)
                    }
                }
                rows.append(row)
            }
            return rows
        }
    }
}
