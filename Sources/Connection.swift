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
            static let headerSize = 81
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
            // TODO: (TL) Check other stuff like in transaction
//            try disconnect()
            // TODO: (TL) Pieces missing
        }
        
        // MARK: - Private Helper Functions
        private func connect(with socket: Socket) throws {
            state = .connecting
            try socket.connect(to: configuration.host, port: configuration.port)
        }

        private func authorize(_ socket: Socket) throws {
            guard let handshake = try parseHandshake(from: socket) else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
            print("Handshake received: \(handshake)")
            // TODO: (TL) Dynamic capabilities via plugins?
            // configuration.capabilities ...
            // TODO: (TL) Password stuff
//            let handshakeData = socket.read()
        }

        private func disconnect() throws {
            guard let socket = socket else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
            // try write(packet: MySQL.Command.quit)
//            try socket.close()
            state = .disconnecting
            // TODO: (TL) Pieces missing
        }

        private func parseHandshake(from socket: Socket) throws -> Handshake? {
            var data = Data(capacity: Constants.headerSize)
            let bytesRead = try socket.read(into: &data)
            print("[\(bytesRead)] Data: \(data)")
            // TODO: (TL) Verify bytesRead to ensure handshake size
            let (messageLength, sequenceNumber) = try parseHandshakeHeader(from: data)
            print("[\(sequenceNumber)] Message Length: \(messageLength)")
            let body = data.subdata(in: data.startIndex.advanced(by: 4)..<data.endIndex)
            return Handshake(data: body)
        }

        private func parseHandshakeHeader(from header: Data) throws -> (messageLength: UInt32, sequenceNumber: Int) {
            if header.count < 3 {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
            let messageLength = UInt32(header[2]) << 16 | UInt32(header[1]) << 8 | UInt32(header[0])
            let sequenceNumber = Int(header[3])

            return (messageLength, sequenceNumber)
        }
    }
}
