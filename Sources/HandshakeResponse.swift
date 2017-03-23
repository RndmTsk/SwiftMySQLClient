//
//  HandshakeResponse.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-14.
//
//

import Foundation

/*
4              capability flags, CLIENT_PROTOCOL_41 always set
4              max-packet size
1              character set
string[23]     reserved (all [0])
string[NUL]    username
if capabilities & CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA {
    lenenc-int     length of auth-response
    string[n]      auth-response
} else if capabilities & CLIENT_SECURE_CONNECTION {
    1              length of auth-response
    string[n]      auth-response
} else {
    string[NUL]    auth-response
}
if capabilities & CLIENT_CONNECT_WITH_DB {
    string[NUL]    database
}
if capabilities & CLIENT_PLUGIN_AUTH {
    string[NUL]    auth plugin name
}
if capabilities & CLIENT_CONNECT_ATTRS {
    lenenc-int     length of all key-values
    lenenc-str     key
    lenenc-str     value
    if-more data in 'length of all key-values', more keys and value pairs
}
 */

public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    public struct HandshakeResponse {
        let data: Data

        init(handshake: Handshake, configuration: ClientConfiguration) {
            // TODO: (TL) Dynamic capabilities via plugins?
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
                // TODO: (TL) lenenc-int auth-response.count
                // TODO: (TL) auth-response
                let lenenc = MySQL.lenenc(password.count)
                rawData.append(contentsOf: lenenc)
                rawData.append(contentsOf: password)
                
                print("clientPluginAuthLenencClientData")
            } else if handshake.capabilityFlags.contains(.clientSecureConnection) {
                
                // TODO: (TL) auth-response.count (1 byte)
                // TODO: (TL) auth-response
                print("clientSecureConnection")
            } else {
                // TODO: (TL) auth-response
                rawData.append(0)
                print("none")
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
                rawData.append(0)
                // TODO: (TL) lenenc-int key-values.count
                // TODO: (TL) lenenc-str key
                // TODO: (TL) lenenc-str value
                print("clientConnectAttrs")
            }
            self.data = Data(bytes: rawData)
        }
    }
}
