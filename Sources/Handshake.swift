//
//  Handshake.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation

internal extension MySQL {
    // https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    // TODO: (TL) Protocol to allow for different versions
    internal struct Handshake: CustomStringConvertible {
        let protocolVersion: Int
        let serverVersion: String
        let connectionID: Int
        let authPluginDataPart1: String
        let capabilityFlags: CapabilityFlag // NOTE: In position 6 & 9
        let characterset: Int
        let statusFlags: StatusFlag
        let authPluginLength: Int
        let authPluginName: String

        var description: String {
            return "[MySQL Handshake V\(protocolVersion)]{MySQL V: \(serverVersion)} CID#\(connectionID) ... TODO: (TL) ..."
        }

        internal init?(data: Data) {
            var result = data
            self.protocolVersion = result.removingInt(of: 1)
            self.serverVersion = result.removingNullEncodedString()

            // connection id is 4 bytes (UNSIGNED!)
            self.connectionID = result.removingInt(of: 4)

            // 2 bytes for auth plugin data -- 8 bytes
            self.authPluginDataPart1 = result.removingString(of: 8)

            // 1 byte of filler (unused at the moment)
            result.droppingFirst(1)

            // Optional pieces after the filler //
            var capFlag1: CapabilityFlag = []
            // 2 bytes for capability flag part 1
            if result.count > 1 {
                capFlag1 = CapabilityFlag(rawValue: UInt32(result.removingInt(of: 2)))
            }

            // 1 byte for character sets
            if result.count > 0 {
                self.characterset = result.removingInt(of: 1)
            } else {
                self.characterset = 0 // TODO: (TL) throw? abort?
            }

            // 2 bytes for status flags
            if result.count > 1 {
                self.statusFlags = StatusFlag(rawValue: UInt16(result.removingInt(of: 2)))
            } else {
                self.statusFlags = []
            }

            // 2 bytes for upper capability flags
            var capFlag2: CapabilityFlag = []
            if result.count > 1 {
                capFlag2 = CapabilityFlag(rawValue: UInt32(result.removingInt(of: 2) << 16))
            }
            self.capabilityFlags = CapabilityFlag.with(upper: capFlag2, lower: capFlag1)

            // TODO: (TL) What do we do with this?
            // 1 byte for plugin length
            self.authPluginLength = result.removingInt(of: 1)
            self.authPluginName = result.removingNullEncodedString()
        }
    }
}
