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
        let connectionID: UInt32
        let authPluginDataPart1: String

        let capabilityFlags: CapabilityFlag // NOTE: In position 6 & 9
        let characterset: UInt8
        let statusFlags: StatusFlag
        let authPluginName: String

        public init?(data: Data) {
            print("Data: \(data)")
            guard let serverVersionString = Handshake.parseVersionString(from: data) else {
                return nil
            }

            var index = 0
            self.protocolVersion = data[index] // TODO: (TL) Sliding window extension or something?
            self.serverVersion = serverVersionString
            index += serverVersionString.utf8.count + 1 // advance past end of string

            self.connectionID = Handshake.parseConnectionID(from: data, at: index)
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

            let length: Int = index < data.count ? Int(data[index]) : 0
            index += 1 // 1 for plugin length

            if index + length < data.count {
                self.authPluginName = String(data: data.subdata(in: index..<index+length), encoding: .utf8) ?? ""
            } else {
                self.authPluginName = ""
            }
        }

        // MARK: - Helper Functions

        /**
         Version String is 1 byte after the protocol version and is NULL (0) terminated.

         - parameter data: The response from the MySQL server.
         - returns: A `String` representing the version number if successfully parsed, `nil` otherwise.
         */
        private static func parseVersionString(from data: Data) -> String? {
            var versionEnd = data.startIndex.advanced(by: 1) // Need to increment by at least 1 to get by the version string.
            repeat {
                versionEnd += 1
            } while versionEnd < data.endIndex && data[versionEnd] != 0

            let versionStart = data.startIndex.advanced(by: 1) // Version starts 1 byte after protocol version
            return String(data: data.subdata(in: versionStart..<versionEnd), encoding: .utf8)
        }

        /**
         Connection ID comes from the first 4 bytes of data after the version string
         */
        private static func parseConnectionID(from data: Data, at offset: Int) -> UInt32 {
            return UInt32(data[offset + 3]) << 24 | UInt32(data[offset + 2]) << 16 | UInt32(data[offset + 1]) << 8 | UInt32(data[offset])
        }
    }
}
