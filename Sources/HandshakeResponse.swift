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
            // TODO: (TL) Dynamic capabilities via plugins?
            var rawData = MySQL.lsbEncoded(configuration.capabilities.rawValue)
            // Max packet size (4 bytes)
            rawData.append(contentsOf: MySQL.lsbEncoded(UInt32.max))
            rawData.append(UInt8(handshake.characterset)) // TODO: (TL) ...
            // 23 bytes of reserved 0s
            rawData.append(contentsOf: [UInt8](repeating: 0, count: 23))
            if let username = configuration.credentials?.user {
                // TODO: (TL) Fixed length - include size first?
                rawData.append(contentsOf: username.utf8)
                rawData.append(0)
            }
            if let password = configuration.credentials?.password {
                if handshake.capabilityFlags.contains(.clientPluginAuthLenecClientData) {
                    rawData.append(contentsOf: MySQL.lenenc(password.utf8.count))
                    rawData.append(contentsOf: password.utf8)
                } else if handshake.capabilityFlags.contains(.clientSecureConnection) {
                    rawData.append(contentsOf: MySQL.lsbEncoded(password.utf8.count, to: 1))
                    rawData.append(contentsOf: password.utf8)
                } else {
                    rawData.append(contentsOf: password.utf8)
                    rawData.append(0)
                }
            }
            // Database (NULL terminated)
            if handshake.capabilityFlags.contains(.clientConnectWithDB),
                let database = configuration.database {
                rawData.append(contentsOf: database.utf8)
                rawData.append(0)
            }

/* TODO: (TL) auth-plugin-name (NULL terminated)
            if capabilities & CLIENT_PLUGIN_AUTH {
                string[NUL]    auth plugin name
            }
 */
/* TODO: (TL) lenec-connect-attrs
            if capabilities & CLIENT_CONNECT_ATTRS {
                lenenc-int     length of all key-values
                lenenc-str     key
                lenenc-str     value
                if-more data in 'length of all key-values', more keys and value pairs
            }
 */
            self.data = Data(bytes: rawData)
        }
    }
}
