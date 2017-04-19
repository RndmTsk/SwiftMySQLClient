//
//  PreparedStatementResponse.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-18.
//
//

import Foundation

extension MySQL {
    internal struct PreparedStatementResponse {
        let statementID: [UInt8]
        let columnCount: Int
        let parameterCount: Int
        let warningCount: Int
        let columns: [Column]
        init(firstPacket: Packet, additionalPackets: ArraySlice<Packet>) throws {
            var remaining = firstPacket.body
            let status = remaining.removingInt(of: 1)
            guard status == 0 else {
                throw ServerError(data: remaining, capabilities: []) // TODO: (TL)
            }
            // Since we pass it back, might as well not manipulate it every time
            self.statementID = remaining.removingFirstBytes(4)
            let columnCount = remaining.removingInt(of: 2)
            self.columnCount = columnCount
            self.parameterCount = remaining.removingInt(of: 2)
            remaining.droppingFirst() // 1 byte of filler
            self.warningCount = remaining.removingInt(of: 2)

            guard additionalPackets.count >= columnCount else {
                throw ClientError.receivedNoResponse // TODO: (TL) Server error instead (at least different client error)
            }
            let endIndex = additionalPackets.startIndex.advanced(by: columnCount)
            self.columns = additionalPackets[additionalPackets.startIndex..<endIndex].flatMap {
                ($0.body, false) // TODO: (TL) ...
                }.map(Column.init)
            // TODO: (TL) Is there more stuff - EOF maybe?
        }
    }
}
