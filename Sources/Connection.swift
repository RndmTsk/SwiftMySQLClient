//
//  Connection.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation
import Socket

/// Namespace everything with MySQL - the PostgreSQL driver does this.
public extension MySQL {

    /// A single connection to the database.
    public final class Connection {

        // MARK: - Constants
        private struct Constants {
            static let headerSize = 4
        }

        // MARK: - Enums

        /// A representation of the current state of the connection.
        public enum State {
            /// The client is disconnected
            case disconnected
            /// The client is in the process of connecting to the server.
            case connecting
            /// The client has received the server's handshake.
            case authorizing
            /// The client has successfully negotiated a connection.
            case connected
            /// The client has issued a `COM_QUIT` command.
            case disconnecting
        }

        // MARK: - Properties

        /// The `State` of this connection.
        var state: State

        /// The `StatusFlag` of the last communication with the server.
        var status: StatusFlag

        /// The current configuration of this client
        private var configuration: ClientConfiguration

        /// The packet number last sent to or received from the server
        private var sequenceNumber: UInt8

        /// The raw OS `Socket` used to communicate with MySQL.
        private var socket: Socket? = nil

        /// The `Handshake` received from the initial connection.
        private var handshake: Handshake? = nil
        
        // MARK: - Lifecycle Functions

        /**
         Constructs a `Connection` with the given `ClientConfiguration`.

         - parameter configuration: The configuration to use when connecting to MySQL.
         */
        public init(configuration: ClientConfiguration) {
            self.configuration = configuration
            self.state = .disconnected
            self.status = []
            self.sequenceNumber = 0
        }

        // MARK: - Open / Close

        /**
         Attempts to open a connection to MySQL and authorize with the supplied `configuration`.

         - throws: If the socket is unable to be created, if the connection fails or if authorization fails. - TODO: (TL) Use Result<T> instead?
         */
        public func open() throws {
            if socket == nil {
                socket = try Socket.create()
            }
            guard let socket = socket else {
                throw ClientError.socketUnavailable
            }
            try connect(with: socket)
            try authorize(socket)
        }

        /**
         Attempts to close the currently opened connection to MySQL.

         - throws: If the socket has not been created or if disconnecting fails.
         */
        public func close() throws {
            guard let socket = socket else {
                throw ClientError.socketUnavailable
            }
            try disconnect(from: socket)
            // TODO: (TL) Check other stuff like in transaction
        }

        // MARK: - Issue Command
        // TODO: (TL) Do we need more than one parameter? - seems like deprecated commands need this
        public func issue(_ command: Command, with text: String? = nil) throws -> ResultSet {
            // https://dev.mysql.com/doc/internals/en/sequence-id.html
            // - Sequence number resets for each command
            sequenceNumber = 0

            guard let socket = socket else {
                throw ClientError.socketUnavailable
            }
            var bytes: [UInt8] = [command.rawValue]
            if let text = text {
                bytes.append(contentsOf: text.utf8)
                bytes.append(0)
            }
            let data = Data(bytes: bytes)
            try write(data, to: socket, false)
            let packets = try receive(from: socket)
            guard let firstPacket = packets.first else {
                throw ClientError.receivedNoResponse
            }

            // 1. Verify how many packets were received
            guard packets.count > 1 else {
                let commandResponse = try parseCommandResponse(from: firstPacket.body, with: handshake?.capabilityFlags ?? [])
                return ResultSet.empty
            }
            let columnCount = Int(firstPacket.body[0])
            let resultSet = ResultSet(packets: packets[1..<packets.count],
                                      columnCount: columnCount,
                                      affectedRows: 0,
                                      lastInsertID: 0) // TODO: (TL) ...
            return resultSet
        }
        
        // MARK: - Private Helper Functions

        /**
         A helper function to do the raw socket connection with the host and port supplied in the `configuration`.

         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the connection process.
         */
        private func connect(with socket: Socket) throws {
            state = .connecting
            try socket.connect(to: configuration.host, port: configuration.port)
        }

        /**
         A helper function to negotiate the handshake.

         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the authorization process.
         */
        private func authorize(_ socket: Socket) throws {
            state = .authorizing
            var packets = try receive(from: socket)
            guard let handshakePacket = packets.first, packets.count == 1 else {
                throw ClientError.receivedExtraPackets // TODO: (TL) is this actually an error??
            }
            // TODO: (TL) Check packet type
            guard let handshake = Handshake(data: handshakePacket.body)  else {
                throw ClientError.invalidHandshake
            }
            print("    \(handshake)")
            self.handshake = handshake
            let handshakeResponse = HandshakeResponse(handshake: handshake, configuration: configuration)

            try write(handshakeResponse.data, to: socket)
            packets = try receive(from: socket)
            // TODO: (TL) Verify sequence number
            guard let commandPacket = packets.first, packets.count == 1 else {
                throw ClientError.receivedExtraPackets
            }
            _ = try parseCommandResponse(from: commandPacket.body, with: handshake.capabilityFlags)
            // TODO: (TL) ...
        }

        /**
         A helper function to issue the `COM_QUIT` packet to MySQL.

         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the disconnect process.
         */
        private func disconnect(from socket: Socket) throws {
            state = .disconnecting
            do {
                _ = try issue(.quit) // TODO: (TL) Discard the result set?
            } catch where error is PacketError {
                // COM_QUIT can either be EOF _or_ 0 length
                if error as! PacketError != PacketError.noData {
                    throw error
                }
            }
            socket.close()
            state = .disconnected
        }

        /**
         A helper function that attempts to parse a raw `Packet` from the socket stream.

         - parameter socket: The socket object previously created.
         - returns: A `Packet` object if successfully parsed.
         - throws: Any socket error encountered during the read process, any packet creation error if invalid data is received.
         */
        private func receive(from socket: Socket) throws -> [Packet] {
            // TODO: (TL) Add logging of bytes read in DEBUG MODE
            // TODO: (TL) see if we need to read more
            // TODO: (TL) Verify sequence numbers
            var data = Data(capacity: Constants.headerSize)
            _ = try socket.read(into: &data)
            return try chunk(data)
        }

        private func chunk(_ data: Data) throws -> [Packet] {
            var packets = [Packet]()
            var remaining = data
            repeat {
                let packet = try Packet(data: remaining)
                packets.append(packet)
                remaining.droppingFirst(packet.totalLength)
            } while remaining.count > 0
            print("--- PARSED \(packets.count) PACKETS -> \(remaining.count) bytes leftover ---")
            return packets
        }

        /**
         A helper function that writes a given set of `data` to the supplied `socket`.

         - parameter data: The raw `Data` to write.
         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the write process.
         */
        private func write(_ data: Data, to socket: Socket, _ incrementSequenceNumber: Bool = true) throws {
            if incrementSequenceNumber {
                sequenceNumber = (sequenceNumber + 1) % UInt8.max
            }
            // TODO: (TL) This needs to be accounted for by what we've received from the server as well.
            let encodedLength = MySQL.lsbEncoded(data.count, to: 3)

            // Construct the packet:
            // [LENGTH     =      3 bytes]
            // [SEQUENCE # =      1 byte ]
            // [RAW DATA   = LENGTH bytes]
            var packetData = Data(bytes: encodedLength)
            packetData.append(sequenceNumber)
            packetData.append(data)
            try socket.write(from: packetData)
            // TODO: (TL) Add logging of bytes read in DEBUG MODE
            print("[#\(sequenceNumber)]{WRITE} \(data.count) bytes")
        }

        /**
         A helper function that attempts to parse an `OK`, `EOF` or `ERR` packet response.

         - parameter data: The raw data received from the socket.
         - throws: Any errors encountered in constructing the packet response, any errors parsed from the server.
         */
        private func parseCommandResponse(from data: Data, with capabilities: CapabilityFlag? = nil) throws -> CommandPacket {
            guard let responseFlag = data.first else {
                throw ServerError.emptyResponse(with: capabilities)
            }
            let remaining = data.subdata(in: 1..<data.count)
            if responseFlag == MySQL.Constants.ok
                && data.count >= MySQL.Constants.okResponseMinLength {
                return OKPacket(data: remaining, serverCapabilities: capabilities)
            } else if responseFlag == MySQL.Constants.eof
                && data.count < MySQL.Constants.eofResponseMaxLength {
                // Properly formatted EOF packet
                return EOFPacket(data: remaining, serverCapabilities: capabilities)
            } else if responseFlag == MySQL.Constants.err {
                // Properly formatted error packet
                throw ServerError(data: remaining, capabilities: capabilities)
            } else { // Unknown response
                throw ServerError.unknown(with: capabilities)
            }
        }
    }
}
