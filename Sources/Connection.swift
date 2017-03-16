//
//  Connection.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation
import Socket

public extension MySQL {
    public final class Connection {
        // MARK: - Constants
        private struct Constants {
            static let headerSize = 4
        }

        // MARK: - Enums
        public enum State {
            case disconnected
            case connecting
            case authorizing
            case connected
            case disconnecting
        }

        // MARK: - Properties
        let connectionID = UUID()
        var configuration: ClientConfiguration
        var state: State
        var status: MySQL.StatusFlag
        var socket: Socket? = nil
        
        // MARK: - Lifecycle Functions
        public init(configuration: ClientConfiguration) {
            self.configuration = configuration
            self.state = .disconnected
            self.status = []
            // TODO: (TL) Pieces missing
        }

        // MARK: - Open / Close
        public func open() throws {
            if socket == nil {
                socket = try Socket.create()
            }
            guard let socket = socket else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
            try connect(with: socket)
            try authorize(socket)
        }
        
        public func close() throws {
            guard let socket = socket else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
            // TODO: (TL) Pieces missing
            try disconnect(from: socket)
            // TODO: (TL) Check other stuff like in transaction
//            try disconnect()
        }
        
        // MARK: - Private Helper Functions
        private func connect(with socket: Socket) throws {
            state = .connecting
            try socket.connect(to: configuration.host, port: configuration.port)
        }

        private func authorize(_ socket: Socket) throws {
            guard let handshake = try receiveHandshake(from: socket) else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
            print("Handshake received: \(handshake)")

            // TODO: (TL) Check handshake capabilities available
            let handshakeResponse = HandshakeResponse(handshake: handshake, configuration: configuration)

            try socket.write(from: handshakeResponse.data)
            var response = Data(capacity: Constants.headerSize)
            let bytesRead = try socket.read(into: &response)
            print("[\(bytesRead)] \(response)")
            let (messageLength, sequenceNumber) = try parseHeader(from: response)
            print("[\(sequenceNumber)] Message Length: \(messageLength)")
            if (response.count - Constants.headerSize) < messageLength {
                // TODO: (TL) ...
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "NEED TO GET MORE DATA"])
            }
            try parseSimpleResponse(from: response.subdata(in: Constants.headerSize..<response.count))
        }

        private func disconnect(from socket: Socket) throws {
            // try write(packet: MySQL.Command.quit)
//            try socket.close()
            state = .disconnecting
            // TODO: (TL) Pieces missing
        }

        // TODO: (TL) read_packet (header + verify body length, fetch more if needed?)
        private func receiveHandshake(from socket: Socket) throws -> Handshake? {
            var data = Data(capacity: Constants.headerSize)
            let bytesRead = try socket.read(into: &data)
            print("[\(bytesRead)] Data: \(data)")
            // TODO: (TL) Verify bytesRead to ensure handshake size
            let (messageLength, sequenceNumber) = try parseHeader(from: data)
            print("[\(sequenceNumber)] Message Length: \(messageLength)")
            if (data.count - Constants.headerSize) < messageLength {
                // TODO: (TL) ...
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "NEED TO GET MORE DATA"])
            }
            let range: Range<Data.Index> = data.startIndex.advanced(by: Constants.headerSize)..<data.endIndex
            let body = data.subdata(in: range)
            return Handshake(data: body)
        }

        private func parseHeader(from header: Data) throws -> (messageLength: Int, sequenceNumber: Int) {
            if header.count < Constants.headerSize {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "INCORRECT HEADER SIZE"])
            }
            let messageLength = header.int(of: 3) // Message length is 3 bytes
            let sequenceNumber = Int(header[3]) // Sequence number is 1 byte

            return (messageLength, sequenceNumber)
        }

        private func parseSimpleResponse(from data: Data) throws {
            guard let responseFlag = data.first else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "RESPONSE LENGTH IS ZERO"])
            }
            var remaining = data.subdata(in: 1..<data.count)
            if responseFlag == MySQL.Constants.ok &&
                remaining.count > MySQL.Constants.okResponseMinLength {
                // Properly formatted OK
                print("[RESPONSE] OK")
                let affectedRows: Int
                (affectedRows, remaining) = remaining.lenencInt
                print("affectedRows: \(affectedRows)")

                let lastInsertID: Int
                (lastInsertID, remaining) = remaining.lenencInt
                print("lastInsertID: \(lastInsertID)")

                // TODO: (TL) Capture server capabilities
 /*
                if capabilities & CLIENT_PROTOCOL_41 {
                    int<2>	status_flags	Status Flags
                    int<2>	warnings	number of warnings
                } elseif capabilities & CLIENT_TRANSACTIONS {
                    int<2>	status_flags	Status Flags
                }
                if capabilities & CLIENT_SESSION_TRACK {
                    string<lenenc>	info	human readable status information
                    if status_flags & SERVER_SESSION_STATE_CHANGED {
                        string<lenenc>	session_state_changes	session state info
                    }
                } else {
                    string<EOF>	info	human readable status information
                }
 */
            } else if data[0] == MySQL.Constants.eof && data.count < MySQL.Constants.eofResponseMaxLength { // Properly formatted EOF
                print("[RESPONSE] EOF")
            } else if data[0] == MySQL.Constants.err { // Properly formatted error
                print("[RESPONSE] ERR")
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "RESPONSE = ERR"])
            } else { // Unknown response
                print("[RESPONSE] ??")
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "RESPONSE = ???"])
            }
        }
    }
}
