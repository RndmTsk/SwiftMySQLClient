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
        let parameters: [Column] // TODO: (TL) Likely it's own data structure
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
            let parameterCount = remaining.removingInt(of: 2)
            self.parameterCount = parameterCount
            remaining.droppingFirst() // 1 byte of filler
            self.warningCount = remaining.removingInt(of: 2)

            guard additionalPackets.count >= parameterCount + columnCount else {
                throw ServerError.malformedCommandResponse()
            }
            var endIndex = additionalPackets.startIndex.advanced(by: parameterCount)
            self.parameters = additionalPackets[additionalPackets.startIndex..<endIndex].flatMap {
                ($0.body, false)
            }.map(Column.init)
            let columnStartIndex = additionalPackets.startIndex.advanced(by: endIndex - additionalPackets.startIndex)
            endIndex = endIndex.advanced(by: columnCount)
            self.columns = additionalPackets[columnStartIndex..<endIndex].flatMap {
                ($0.body, false)
            }.map(Column.init)
            print("[PreparedStatementResponse] \(additionalPackets.count - endIndex) packets left.")
        }
    }
}
