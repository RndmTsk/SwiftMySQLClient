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
    public struct Handshake { // TODO: (TL) Should detect protocol version and adjust
        private class Constants {
            static let bitsPerByte = 8
        }

        let protocolVersion: UInt8
        let serverVersion: String
        let connectionID: Int
        let authPluginDataPart1: String
        let capabilityFlags: CapabilityFlag // NOTE: In position 6 & 9
        let characterset: UInt8
        let statusFlags: StatusFlag
        let authPluginName: String

        public init?(data: Data) {
            var index = 0
            self.protocolVersion = data[index] // TODO: (TL) Sliding window extension or something?
            index += 1

            guard let serverVersionString = data.nullEncodedString(at: index) else {
                return nil
            }
            self.serverVersion = serverVersionString
            index += serverVersionString.utf8.count + 1 // advance past end of string

            // Actually this is unsigned
            self.connectionID = data.int(of: 4, at: index)
            index += 4 // connection id is 4 bytes

            self.authPluginDataPart1 = String(data: data.subdata(in: index..<index+1), encoding: .utf8) ?? ""
            index += 2 // 2 bytes for auth plugin data
            index += 1 // 1 byte of filler (unused at the moment)

            // Optional pieces after the filler //

            var capFlag1: CapabilityFlag = []
            if index + 1 < data.count {
                capFlag1 = CapabilityFlag(rawValue: UInt32(data[index]) << 8 | UInt32(data[index + 1]))
            }
            index += 2 // 2 bytes for capability flags

            self.characterset = index < data.count ? data[index] : 0
            index += 1 // 1 byte for character set

            if index + 1 < data.count {
                self.statusFlags = StatusFlag(rawValue: UInt16(data[index]) << 8 | UInt16(data[index + 1]))
            } else {
                self.statusFlags = []
            }
            index += 2 // 2 bytes for status flags

            var capFlag2: CapabilityFlag = []
            if index + 1 < data.count {
                capFlag2 = CapabilityFlag(rawValue: UInt32(data[index]) << 24 | UInt32(data[index + 1]) << 16)
            }
            index += 2 // 2 bytes for upper capability flags
            self.capabilityFlags = CapabilityFlag.with(upper: capFlag2, lower: capFlag1)

            // What do we do with this?
            let length: Int = index < data.count ? Int(data[index]) : 0
            index += 1 // 1 for plugin length

            self.authPluginName = data.nullEncodedString(at: index) ?? ""
        }
    }
}
