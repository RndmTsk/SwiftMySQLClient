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
            static let emptyResponse = 0
            static let emtpyMessage = "Response length was zero, no data was received."
            static let unknown = 1
            static let unknownMessage = "An unknown error occurred attempting to receive data from the server."
            static let invalidSequenceNumber = 2
            static let invalidSequenceNumberMessage = "Received a packet out of order."
            static let malformedCommand = 3
            static let malformedCommandMessage = "Command response packet was malformed."
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

        public init(data: Data, capabilities: CapabilityFlag? = nil) {
            var remaining = data
            let serverCapabilities = capabilities ?? []
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

        private init(capabilities: CapabilityFlag? = nil,
                     code: Int = Constants.unknown,
                     marker: String = Constants.standardMarker,
                     state: String = String(Constants.unknown),
                     message: String = Constants.unknownMessage) {
            // TODO: (TL) Not using capabilities
            self.code = code
            self.marker = marker
            self.state = state
            self.message = message
        }

        public static func unknown(with capabilities: CapabilityFlag? = nil) -> ServerError {
            return ServerError(capabilities: capabilities)
        }

        public static func emptyResponse(with capabilities: CapabilityFlag? = nil) -> ServerError {
            return ServerError(capabilities: capabilities,
                               code: Constants.emptyResponse,
                               marker: Constants.standardMarker,
                               state: String(Constants.emptyResponse),
                               message: Constants.emtpyMessage)
        }

        public static func invalidSequenceNumber(with capabilities: CapabilityFlag? = nil) -> ServerError {
            return ServerError(capabilities: capabilities,
                               code: Constants.invalidSequenceNumber,
                               marker: Constants.standardMarker,
                               state: String(Constants.invalidSequenceNumber),
                               message: Constants.invalidSequenceNumberMessage)
        }

        public static func malformedCommandResponse(with capabilities: CapabilityFlag? = nil) -> ServerError {
            return ServerError(capabilities: capabilities,
                               code: Constants.malformedCommand,
                               marker: Constants.standardMarker,
                               state: String(Constants.malformedCommand),
                               message: Constants.malformedCommandMessage)
        }
    }

    public enum ClientError: Error {
        case noConnection
        case invalidHandshake
        case receivedNoResponse
        case receivedExtraPackets
    }

    public enum PacketError: Error {
        case noData
        case incorrectHeaderLength
        case incorrectBodyLength
    }
}
