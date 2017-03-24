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
        let authCipher: [UInt8]
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
            var authCipher = result.removingFirstBytes(8)

            // 1 byte of filler (unused at the moment)
            result.droppingFirst(1)

            // Optional pieces after the filler //

            // 2 bytes for capability flag part 1
            var capabilityFlags = CapabilityFlag(rawValue: UInt32(result.removingInt(of: 2)))

            // 1 byte for character sets
            self.characterset = result.removingInt(of: 1)

            // 2 bytes for status flags
            self.statusFlags = StatusFlag(rawValue: UInt16(result.removingInt(of: 2)))

            // 2 bytes for upper capability flags
            capabilityFlags.insert(CapabilityFlag(rawValue: UInt32(result.removingInt(of: 2) << 16)))
            self.capabilityFlags = capabilityFlags

            // TODO: (TL) What do we do with this?
            // 1 byte for plugin length (non-zero if CLIENT_PLUGIN_AUTH)
            let authPluginLength = result.removingInt(of: 1)

            // 10 bytes are reserved
            result.droppingFirst(10)

            if capabilityFlags.contains(.clientSecureConnection) {
                // According to the Python and golang drivers
                // the other half is 12 bytes
                // This seems to agree with authPluginLength (21) - first bytes (8) - \0 (1)
                if authPluginLength > 8 {
                    authCipher.append(contentsOf: result.removingFirstBytes(authPluginLength - 9))
                    result.droppingFirst()
                } else {
                    authCipher.append(contentsOf: result.removingNullEncodedString().utf8)
                }
            }
            self.authCipher = authCipher

            if capabilityFlags.contains(.clientPluginAuth) {
                self.authPluginName = result.removingNullEncodedString()
            } else {
                self.authPluginName = ""
            }
        }
    }
}
