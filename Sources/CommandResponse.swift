//
//  CommandResponse.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-25.
//
//

import Foundation

extension MySQL {
    internal struct CommandResponse {
        internal let firstPacket: Packet
        internal let additionalPackets: ArraySlice<Packet>?

        internal init(firstPacket: Packet, additionalPackets: ArraySlice<Packet>? = nil) {
            self.firstPacket = firstPacket
            self.additionalPackets = additionalPackets
        }
    }
}
