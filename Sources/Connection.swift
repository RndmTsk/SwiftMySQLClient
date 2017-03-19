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
        var serverCapabilities: CapabilityFlag
        var state: State
        var status: MySQL.StatusFlag
        var socket: Socket? = nil
        var sequenceNumber: UInt8
        
        // MARK: - Lifecycle Functions
        public init(configuration: ClientConfiguration) {
            self.configuration = configuration
            self.state = .disconnected
            self.serverCapabilities = []
            self.status = []
            self.sequenceNumber = 0
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
            let packet = try receive(from: socket)
            // TODO: (TL) Check packet type
            guard let handshake = Handshake(data: packet.body)  else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "INVALID HANDSHAKE"])
            }
            print("Handshake received: \(handshake)")
            serverCapabilities = handshake.capabilityFlags

            // TODO: (TL) Check handshake capabilities available
            let handshakeResponse = HandshakeResponse(handshake: handshake, configuration: configuration)

            try write(handshakeResponse.data, to: socket)

            let response = try receive(from: socket)
            // TODO: (TL) Verify sequence number
            try parseSimpleResponse(from: response.body)
        }

        private func disconnect(from socket: Socket) throws {
            // try write(packet: MySQL.Command.quit)
//            try socket.close()
            state = .disconnecting
            // TODO: (TL) Pieces missing
        }

        private func receive(from socket: Socket) throws -> Packet {
            var data = Data(capacity: Constants.headerSize)
            let bytesRead = try socket.read(into: &data)
            print("[\(bytesRead)] Data: \(data)")
            // TODO: (TL) see if we need to read more
            return try Packet(data: data)
        }

        private func write(_ data: Data, to socket: Socket) throws {
            sequenceNumber = (sequenceNumber + 1) % UInt8.max
            let encodedLength = MySQL.lsbEncoded(data.count, to: 3)
            var packetData = Data(bytes: encodedLength)
            packetData.append(sequenceNumber)
            packetData.append(data)
            try socket.write(from: packetData)
        }

        private func parseSimpleResponse(from data: Data) throws {
            guard let responseFlag = data.first else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "RESPONSE LENGTH IS ZERO"])
            }
            var remaining = data.subdata(in: 1..<data.count)
            if responseFlag == MySQL.Constants.ok
                && remaining.count > MySQL.Constants.okResponseMinLength {
                // Properly formatted OK
                print("[RESPONSE] OK")
                let affectedRows: Int
                (affectedRows, remaining) = remaining.lenencInt
                print("affectedRows: \(affectedRows)")

                let lastInsertID: Int
                (lastInsertID, remaining) = remaining.lenencInt
                print("lastInsertID: \(lastInsertID)")

                status = StatusFlag(rawValue: remaining.uInt16)
                remaining.droppingFirst(2)
                print("Status Flags: \(status)")
                if serverCapabilities.contains(.clientProtocol41) {
                    // TODO: (TL) ...
                    let numberOfWarnings = remaining.int(of: 2)
                    print("Number of warnings: \(numberOfWarnings)")
                    remaining.droppingFirst(2)
                }
 /*
                if capabilities & CLIENT_SESSION_TRACK {
                    string<lenenc>	info	human readable status information
                    if status_flags & SERVER_SESSION_STATE_CHANGED {
                        string<lenenc>	session_state_changes	session state info
                    }
                } else {
                    string<EOF>	info	human readable status information
                }
 */
            } else if responseFlag == MySQL.Constants.eof
                && data.count < MySQL.Constants.eofResponseMaxLength { // Properly formatted EOF
                print("[RESPONSE] EOF")
            } else if responseFlag == MySQL.Constants.err { // Properly formatted error
                print("[RESPONSE] ERR")
                let errorCode = remaining.int(of: 2)
                remaining.droppingFirst(2)
                if configuration.capabilities.contains(.clientProtocol41) {
                    // TODO: (TL) ...
                    // string[1]	sql_state_marker	# marker of the SQL State
                    let sqlStateMarker = String(remaining[1])
                    remaining.droppingFirst(1)
                    print("State Marker: \(sqlStateMarker)")
                    // string[5]	sql_state	SQL State
                    let sqlState = String(data: remaining.subdata(in: 0..<5), encoding: .utf8)
                    remaining.droppingFirst(5)
                    print("State: \(sqlState)")
                }
                var errorEnd = remaining.startIndex
                repeat {
                    errorEnd += 1
                } while errorEnd < remaining.endIndex && remaining[errorEnd] != MySQL.Constants.eof
                
                let error: String?
                (error, remaining) = remaining.removeEOFEncodedString()
                guard let unwrappedError = error else {
                    throw NSError(domain: "TODO: (TL)", code: errorCode, userInfo: ["ERROR" : "UNKNOWN"])
                }
                throw NSError(domain: "TODO: (TL)", code: errorCode, userInfo: ["ERROR" : unwrappedError])
            } else { // Unknown response
                print("[RESPONSE] ??")
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "RESPONSE = ???"])
            }
        }
    }
}
