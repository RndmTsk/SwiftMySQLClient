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
        let numberOfWarnings: Int?
        let stateInfo: String?

        // MARK: - <CustomStringConvertible>
        var description: String {
            var response = "R: \(affectedRows), INS: \(lastInsertID), STATUS: \(status)"
            if let numberOfWarnings = numberOfWarnings {
                response.append(", WARN: \(numberOfWarnings)")
            }
            response.append(", INFO: \(info)")
            if let stateInfo = stateInfo {
                response.append(", STATE: \(stateInfo)")
            }
            return response
        }

        init(data: Data, serverCapabilities: CapabilityFlag?) {
            var remaining = data
            self.affectedRows = remaining.removingLenencInt()
            self.lastInsertID = remaining.removingLenencInt()
            let status = StatusFlag(rawValue: remaining.uInt16)
            remaining.droppingFirst(2)

            if let serverCapabilities = serverCapabilities,
                serverCapabilities.contains(.clientProtocol41) {
                self.numberOfWarnings = remaining.removingInt(of: 2)
            } else {
                self.numberOfWarnings = nil
            }
        if let serverCapabilities = serverCapabilities,
            serverCapabilities.contains(.clientSessionTrack) {
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
    internal struct EOFPacket {
        init?(data: Data) {
            
        }
    }

    // https://dev.mysql.com/doc/internals/en/packet-ERR_Packet.html
    internal struct ERRPacket {
        init?(data: Data) {
            
        }
    }
}
