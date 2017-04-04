//
//  StatusPackets.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-24.
//
//

import Foundation

internal extension MySQL {
    // https://dev.mysql.com/doc/internals/en/packet-OK_Packet.html
    internal struct OKPacket: CustomStringConvertible {
        // MARK: - Properties
        let affectedRows: Int
        let lastInsertID: Int
        let status: StatusFlag
        let info: String
        let numberOfWarnings: Int
        let stateInfo: String?

        // MARK: - <CustomStringConvertible>
        var description: String {
            var response = "R: \(affectedRows), INS: \(lastInsertID), STATUS: \(status)"
            response.append(", WARN: \(numberOfWarnings), INFO: \(info).")
            if let stateInfo = stateInfo {
                response.append(", STATE: \(stateInfo)")
            }
            return response
        }

        init(data: Data, serverCapabilities: CapabilityFlag) {
            var remaining = data
            self.affectedRows = remaining.removingLenencInt()
            self.lastInsertID = remaining.removingLenencInt()

            let status: StatusFlag
            if serverCapabilities.contains(.clientProtocol41) {
                status = StatusFlag(rawValue: remaining.uInt16)
                remaining.droppingFirst(2)
                self.numberOfWarnings = remaining.removingInt(of: 2)
            } else {
                if serverCapabilities.contains(.clientTransactions) {
                    status = StatusFlag(rawValue: remaining.uInt16)
                    remaining.droppingFirst(2)
                } else {
                    status = []
                }
                self.numberOfWarnings = 0
            }

            if serverCapabilities.contains(.clientSessionTrack) {
                let infoLength = remaining.removingLenencInt()
                self.info = remaining.removingString(of: infoLength)
                if status.contains(.sessionStateChanged) {
                    let stateInfoLength = remaining.removingLenencInt()
                    self.stateInfo = remaining.removingString(of: stateInfoLength)
                } else {
                    self.stateInfo = nil
                }
            } else {
                self.info = remaining.removingEOFEncodedString()
                self.stateInfo = nil
            }
            self.status = status
        }
    }

    // https://dev.mysql.com/doc/internals/en/packet-EOF_Packet.html
    internal struct EOFPacket: CustomStringConvertible { // NOTE: This type of packet is deprecated
        let numberOfWarnings: Int
        let status: StatusFlag

        var description: String {
            return "WARN: \(numberOfWarnings), STATUS: \(status)"
        }

        init(data: Data, serverCapabilities: CapabilityFlag) {
            var remaining = data
            if serverCapabilities.contains(.clientProtocol41) {
                self.numberOfWarnings = remaining.removingInt(of: 2)
                self.status = StatusFlag(rawValue: UInt16(remaining.removingInt(of: 2) & 0xffff))
            } else {
                self.numberOfWarnings = 0
                self.status = []
            }
        }
    }
}
