//
//  HandshakeResponse.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-14.
//
//

import Foundation

public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    public struct HandshakeResponse {
        let data: Data

        init(handshake: Handshake, configuration: ClientConfiguration) {
            // Capabilities (4 bytes)
            var rawData = MySQL.lsbEncoded(configuration.capabilities.rawValue)
            // Max packet size (4 bytes)
            rawData.append(contentsOf: MySQL.lsbEncoded(UInt32.max))
            rawData.append(UInt8(handshake.characterset))
            // 23 bytes of reserved 0s
            rawData.append(contentsOf: [UInt8](repeating: 0, count: 23))
            if let username = configuration.credentials?.user {
                rawData.append(contentsOf: username.utf8)
            }
            // Always append a NULL to signify end of username
            rawData.append(0)

            // Always send a password?
            let password = configuration.credentials?.native41SecurePassword(with: handshake.authCipher) ?? [UInt8]()
            if handshake.capabilityFlags.contains(.clientPluginAuthLenecClientData) {
                // Encrypted password (Length encoded prefix)
                rawData.append(contentsOf: MySQL.lenenc(password.count))
                rawData.append(contentsOf: password)
            } else if handshake.capabilityFlags.contains(.clientSecureConnection) {
                // Encrypted password (Length prefixed)
                rawData.append(UInt8(password.count & 0xff))
                rawData.append(contentsOf: password)
            } else {
                // Encrypted password (NULL terminated)
                rawData.append(contentsOf: password)
                rawData.append(0)
            }
            if handshake.capabilityFlags.contains(.clientConnectWithDB),
                let database = configuration.database {
                // Database (NULL terminated)
                rawData.append(contentsOf: database.utf8)
                rawData.append(0)
            }

            if handshake.capabilityFlags.contains(.clientPluginAuth) {
                rawData.append(contentsOf: handshake.authPluginName.utf8)
                rawData.append(0)
            }

            if handshake.capabilityFlags.contains(.clientConnectAttrs) {
                // rawData.append(0)
                // TODO: (TL) lenenc-int key-values.count
                // TODO: (TL) lenenc-str key
                // TODO: (TL) lenenc-str value
                // print("clientConnectAttrs")
            }
            self.data = Data(bytes: rawData)
        }
    }
}
