//
//  Errors.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-18.
//
//

import Foundation

public extension MySQL {
    public struct ServerError: Error, CustomStringConvertible {
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
            self.code = remaining.removingInt(of: 2)
            if capabilities.contains(.clientProtocol41) {
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
    }

    public struct ClientError: Error {
        
    }

    public enum PacketError: Error {
        case incorrectHeaderLength
        case incorrectBodyLength
    }
}
