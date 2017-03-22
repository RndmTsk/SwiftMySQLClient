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
        let authCipher: String
        let capabilityFlags: CapabilityFlag // NOTE: In position 6 & 9
        let characterset: Int
        let statusFlags: StatusFlag
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
            var authCipher = result.removingString(of: 8)

            // 1 byte of filler (unused at the moment)
            result.droppingFirst(1)

            // Optional pieces after the filler //

            // 2 bytes for capability flag part 1
            let capLower = CapabilityFlag(rawValue: UInt32(result.removingInt(of: 2)))

            // 1 byte for character sets
            self.characterset = result.removingInt(of: 1)

            // 2 bytes for status flags
            self.statusFlags = StatusFlag(rawValue: UInt16(result.removingInt(of: 2)))

            // 2 bytes for upper capability flags
            let capUpper = CapabilityFlag(rawValue: UInt32(result.removingInt(of: 2) << 16))
            self.capabilityFlags = CapabilityFlag.with(upper: capUpper, lower: capLower)

            // TODO: (TL) What do we do with this?
            // 1 byte for plugin length
            let authPluginLength = result.removingInt(of: 1)

            // 10 bytes are reserved
            result.droppingFirst(10)

            // According to the Python and golang drivers
            // the other half is 12 bytes
            // This seems to agree with authPluginLength (21) - first bytes (8) - \0 (1)
            authCipher.append(result.removingString(of: authPluginLength - 9))

            self.authCipher = authCipher
            self.authPluginName = result.removingNullEncodedString()
        }
    }
}
