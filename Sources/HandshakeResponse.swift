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
            var rawData = configuration.capabilities.rawValue.uint8Array
            // Max packet size (4 bytes)
            rawData.append(contentsOf: UInt32.max.uint8Array)
            rawData.append(handshake.characterset)
            if let username = configuration.credentials?.user {
                // TODO: (TL) Fixed length - include size first?
                rawData.append(contentsOf: username.utf8)
            }
            // TODO: (TL) auth-response (NULL terminated)
            // TODO: (TL) database (NULL terminated)
            // TODO: (TL) auth-plugin-name (NULL terminated)

            self.data = Data(bytes: rawData)
        }
    }
}
