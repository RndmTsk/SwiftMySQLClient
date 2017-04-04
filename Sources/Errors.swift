//
//  Errors.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-18.
//
//

import Foundation

public extension MySQL {
    // https://dev.mysql.com/doc/internals/en/packet-ERR_Packet.html
    public struct ServerError: Error, CustomStringConvertible {
        private struct Constants {
            static let standardMarker = "#"
            static let emptyResponseState = "00000"
            static let emtpyMessage = "Response length was zero, no data was received."
            static let unknownState = "00001"
            static let unknownMessage = "An unknown error occurred attempting to receive data from the server."
            static let invalidSequenceNumberState = "00002"
            static let invalidSequenceNumberMessage = "Received a packet out of order."
        }

        public let code: Int
        public let marker: String
        public let state: String
        public let message: String
 
        public var description: String {
            let cp41Message: String
            if marker.isEmpty && state.isEmpty {
                cp41Message = ""
            } else {
                cp41Message = marker.appending(state).appending(": ")
            }
            return "[MySQL Error #\(code)] \(cp41Message)\(message)"
        }

        public init(data: Data, capabilities: CapabilityFlag) {
            var remaining = data
            let serverCapabilities = capabilities
            self.code = remaining.removingInt(of: 2)
            if serverCapabilities.contains(.clientProtocol41) {
                // TODO: (TL) ...
                // string[1]	sql_state_marker	# marker of the SQL State
                self.marker = remaining.removingString(of: 1)
                // string[5]	sql_state	SQL State
                self.state = remaining.removingString(of: 5)
            } else {
                // TODO: (TL) ...
                self.marker = ""
                self.state = ""
            }
            self.message = remaining.removingEOFEncodedString()
        }

        private init(capabilities: CapabilityFlag,
                     code: Int = Int.max,
                     marker: String = Constants.standardMarker,
                     state: String = Constants.unknownState,
                     message: String = Constants.unknownMessage) {
            // TODO: (TL) Not using capabilities
            self.code = code
            self.marker = marker
            self.state = state
            self.message = message
        }

        public static func unknown(with capabilities: CapabilityFlag = []) -> ServerError {
            return ServerError(capabilities: capabilities)
        }

        public static func emptyResponse(with capabilities: CapabilityFlag = []) -> ServerError {
            return ServerError(capabilities: capabilities,
                               code: Int.max - 1,
                               marker: Constants.standardMarker,
                               state: Constants.emptyResponseState,
                               message: Constants.emtpyMessage)
        }

        public static func invalidSequenceNumber(with capabilities: CapabilityFlag = []) -> ServerError {
            return ServerError(capabilities: capabilities,
                               code: Int.max - 2,
                               marker: Constants.standardMarker,
                               state: Constants.invalidSequenceNumberState,
                               message: Constants.invalidSequenceNumberMessage)
        }
    }

    public enum ClientError: Error {
        case socketUnavailable
        case invalidHandshake
    }

    public enum PacketError: Error {
        case noData
        case incorrectHeaderLength
        case incorrectBodyLength
    }
}
