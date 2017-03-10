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
/*
            if socket == nil {
                socket = try Socket(host: configuration.host, port: configuration.port)
            }
            try connect()
            try authorize()
            // TODO: (TL) Pieces missing
 */
        }
        
        public func close() throws {
            // TODO: (TL) Check other stuff like in transaction
//            try disconnect()
            // TODO: (TL) Pieces missing
        }
        
        // MARK: - Private Helper Functions
        private func connect() throws {
            guard let socket = socket else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
//            try socket.open()
            // Store mysql_handshake
            state = .connecting
            // TODO: (TL) Pieces missing
        }

        private func authorize() throws {
            guard let socket = socket else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "UNIMPLEMENTED"])
            }
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
    }
}
