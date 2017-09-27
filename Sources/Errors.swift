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
            static let unknownErrorMessage = "An unknown error occurred attempting to receive data from the server."
        }

        public let code: Int
        public let marker: String
        public let state: String
        public let message: String
 
        public static var unknown: ServerError {
            return ServerError()
        }
        
        public static var emptyResponse: ServerError {
            let errorCode = 1
            return ServerError(code: errorCode,
                               marker: Constants.standardMarker,
                               state: String(errorCode),
                               message: "Response length was zero, no data was received.")
        }
        
        public static var invalidSequenceNumber: ServerError {
            let errorCode = 2
            return ServerError(code: errorCode,
                               marker: Constants.standardMarker,
                               state: String(errorCode),
                               message: "Received a packet out of order.")
        }
        
        public static var malformedCommandResponse: ServerError {
            let errorCode = 3
            return ServerError(code: errorCode,
                               marker: Constants.standardMarker,
                               state: String(errorCode),
                               message: "Command response packet was malformed.")
        }

        public static var incorrectCommandResponseSize: ServerError {
            let errorCode = 4
            return ServerError(code: errorCode,
                               marker: Constants.standardMarker,
                               state: String(errorCode),
                               message: "Received incorrect number of command packets.")
        }

        public static var malformedHandshake: ServerError {
            let errorCode = 5
            return ServerError(code: errorCode,
                               marker: Constants.standardMarker,
                               state: String(errorCode),
                               message: "Handshake was malformed.")
        }
        
        public static var incorrectHandshakeResponseSize: ServerError {
            let errorCode = 6
            return ServerError(code: errorCode,
                               marker: Constants.standardMarker,
                               state: String(errorCode),
                               message: "Received incorrect number of command packets.")
        }

        public var description: String {
            let cp41Message: String
            if marker.isEmpty && state.isEmpty {
                cp41Message = ""
            } else {
                cp41Message = marker.appending(state).appending(": ")
            }
            return "[MySQL Error #\(code)] \(cp41Message)\(message)"
        }

        public init(data: Data) {
            var remaining = data
            self.code = remaining.removingInt(of: 2)
            if Connection.serverCapabilities.contains(.clientProtocol41) {
                self.marker = remaining.removingString(of: 1)
                self.state = remaining.removingString(of: 5)
            } else {
                self.marker = ""
                self.state = ""
            }
            self.message = remaining.removingEOFEncodedString()
        }

        private init(code: Int = 0,
                     marker: String = Constants.standardMarker,
                     state: String = String(0),
                     message: String = Constants.unknownErrorMessage) {
            self.code = code
            self.marker = marker
            self.state = state
            self.message = message
        }
    }

    public enum ClientError: Error {
        case noConnection
        case invalidHandshake
        case couldNotMaterializeResponse
        case receivedNoResponse
        case receivedExtraPackets
        case unsupportedDataType
        case invalidColumn
        case invalidParameterList
    }

    public enum PacketError: Error {
        case noData
        case incorrectHeaderLength
        case incorrectBodyLength
    }
}
