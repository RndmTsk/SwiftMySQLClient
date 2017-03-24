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
            print("[WRITE #\(sequenceNumber)] \(data.count) bytes")
        }

        private func parseSimpleResponse(from data: Data) throws {
            guard let responseFlag = data.first else {
                throw ServerError.emptyResponse(with: serverCapabilities)
            }
            var remaining = data.subdata(in: 1..<data.count)
            if responseFlag == MySQL.Constants.ok
                && data.count >= MySQL.Constants.okResponseMinLength {
                // Properly formatted OK packet
                print("[RESPONSE] OK")
                let affectedRows = remaining.removingLenencInt()
                print("affectedRows: \(affectedRows)")

                let lastInsertID = remaining.removingLenencInt()
                print("lastInsertID: \(lastInsertID)")

                status = StatusFlag(rawValue: remaining.uInt16)
                remaining.droppingFirst(2)
                print("Status Flags: \(status)")
                if serverCapabilities.contains(.clientProtocol41) {
                    // TODO: (TL) ...
                    let numberOfWarnings = remaining.removingInt(of: 2)
                    print("Number of warnings: \(numberOfWarnings)")
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
                && data.count < MySQL.Constants.eofResponseMaxLength {
                // Properly formatted EOF packet
                print("[RESPONSE] EOF")
                if serverCapabilities.contains(.clientProtocol41) {
                    let numberOfWarnings = remaining.removingInt(of: 2)
                    let statusFlags = remaining.removingInt(of: 2)
                    print("Number of warnings: \(numberOfWarnings)")
                    print("Status Flags: \(statusFlags)")
                }
            } else if responseFlag == MySQL.Constants.err {
                // Properly formatted error packet
                throw ServerError(data: remaining, capabilities: serverCapabilities)
            } else { // Unknown response
                throw ServerError.unknown(with: serverCapabilities)
            }
        }
    }
}
