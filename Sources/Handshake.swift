//
//  Handshake.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation

public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    public struct Handshake {
        let protocolVersion: UInt8
        let serverVersion: String
        let connectionID: UUID
        let authPluginDataPart1: UInt16
        let filler1: UInt8
        let capabilityFlags: CapabilityFlag // NOTE: In position 6 & 9
        let characterset: UInt8
        let statusFlags: StatusFlag
        let authPluginDataLength: UInt8
        let authPluginName: String
/*
        public init?(data: [UInt8]) {
            
        }
 */
    }
}
