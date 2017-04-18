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
            try connect()
            try authorize()
        }

        /**
         Attempts to close the currently opened connection to MySQL.

         - throws: If the socket has not been created or if disconnecting fails.
         */
        public func close() throws {
            state = .disconnecting
            do {
                _ = try issue(.quit) // TODO: (TL) Discard the result set?
            } catch where error is PacketError {
                // COM_QUIT can either be EOF _or_ 0 length
                if error as! PacketError != PacketError.noData {
                    throw error
                }
            }
            socket?.close()
            state = .disconnected
            // TODO: (TL) Check other stuff like in transaction
        }

        // MARK: - Common Command Helper Functions
        public func query(_ statement: String) throws -> ResultSet {
            try issue(.query, with: statement)
            let commandResponse = try receiveCommandResponse()
            guard let additionalPackets = commandResponse.additionalPackets else {
                return try basicResponse(from: commandResponse.firstPacket)
            }
            return try response(from: commandResponse.firstPacket, with: additionalPackets)
        }

        public func insert(_ statement: String) throws -> ResultSet {
            return try query(statement)
        }

        public func update(_ statement: String) throws -> ResultSet {
            return try query(statement)
        }

        // MARK: - Statement Functions
        public func createStatement(with query: String) -> Statement {
            return Statement(query: query, connection: self)
        }

        public func prepareStatement(with query: String) throws -> PreparedStatement {
            return try PreparedStatement(template: query, connection: self)
        }
        
        // MARK: - Private Helper Functions

        /**
         A helper function to do the raw socket connection with the host and port supplied in the `configuration`.

         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the connection process.
         */
        private func connect() throws {
            guard let socket = socket else {
                throw ClientError.noConnection // TODO: (TL) Manage state for these
            }
            state = .connecting
            try socket.connect(to: configuration.host, port: configuration.port)
        }

        /**
         A helper function to negotiate the handshake.

         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the authorization process.
         */
        private func authorize() throws {
            state = .authorizing
            var packets = try receive()
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

            try write(handshakeResponse.data)
            packets = try receive()
            // TODO: (TL) Verify sequence number
            guard let commandPacket = packets.first, packets.count == 1 else {
                throw ClientError.receivedExtraPackets
            }
            _ = try parseCommandResponse(from: commandPacket.body, with: handshake.capabilityFlags)
            // TODO: (TL) ...
        }

        // private func issue(_ command: Command, with preparedStatement: PreparedStatement) throws {
        internal func issue(_ command: Command, with statement: String? = nil) throws {
            // https://dev.mysql.com/doc/internals/en/sequence-id.html
            // - Sequence number resets for each command
            sequenceNumber = 0

            var bytes: [UInt8] = [command.rawValue]
            if let text = statement {
                bytes.append(contentsOf: text.utf8)
                bytes.append(0)
            }
            let data = Data(bytes: bytes)
            try write(data, false)
        }

        /* -- SENDING A PREPARED STATEMENT --
         1 [COM_STMT_EXECUTE]
         4 stmt-id
         1 flags [0x00 = CURSOR_TYPE_NO_CURSOR, 0x01 = CURSOR_TYPE_READ_ONLY, 0x02 = CURSOR_TYPE_FOR_UPDATE, 0x04 = CURSOR_TYPE_SCROLLABLE]
         4 iteration-count - ALWAYS 1
         if num-params > 0:
         n NULL-bitmap, length: (num-params+7)/8 *** NOTE ***
         1 new-params-bound-flag
         if new-params-bound-flag == 1:
         n type of each parameter, length: num-params*2
         n value of each parameter
         
         *** NOTE ***
         // Binary Protocol ResultSet Row, num-fields and field-pos offset == 2
         // COM_STMT_EXECUTE, num-fields, field-pos offset == 0
         NULL-bitmap-bytes = (num-fields + 7 + offset) / 8
         To store a NULL bit in the bitmap, you need to calculate the bitmap-byte (starting with 0) and the bitpos (starting with 0) in that byte from the field-index (starting with 0):
         NULL-bitmap-byte = ((field-pos + offset) / 8)
         NULL-bitmap-bit  = ((field-pos + offset) % 8)
         ResultSet Row, 9 fields, 9th field is a NULL
         9th field -> field-index == 8, offset == 2
         nulls -> [00] [00]
         
         byte_pos = (10/8) = 1
         bit_pos = (10%8) = 2
         
         nulls[byte_pos] |= 1 << bit_pos
         nulls[1] |= 1 << 2
         
         nulls -> [00] [04]
         */
        internal func issue(_ preparedStatement: PreparedStatement) throws {
            // https://dev.mysql.com/doc/internals/en/sequence-id.html
            // - Sequence number resets for each command
            sequenceNumber = 0

            var bytes: [UInt8] = [Command.stmtExecute.rawValue]
            bytes.append(contentsOf: preparedStatement.statementID)
            bytes.append(0) // TODO: (TL) Specify cursor type in creation?
            bytes.append(contentsOf: [1, 0, 0, 0])

            let mapSize = (preparedStatement.parameterCount + 7) / 8
            var nullBitMap = [UInt8](repeatElement(0, count: mapSize))
            var fieldMap = [UInt8](repeatElement(0, count: preparedStatement.parameterCount * 2)) // TODO: (TL) should this be * 3?
            if preparedStatement.usingNewValues {
                for value in preparedStatement.values {
                    // TODO: (TL) turn into NULL-bitmap and parameters
                }
            }
            
            bytes.append(contentsOf: nullBitMap)
            if preparedStatement.usingNewValues {
                bytes.append(1)
                bytes.append(contentsOf: fieldMap)
            } else {
                bytes.append(0)
            }
        }

        // MARK: - Command Response
        internal func basicResponse(from packet: Packet) throws -> ResultSet {
            let commandResponse = try parseCommandResponse(from: packet.body, with: handshake?.capabilityFlags)
            if let okPacket = commandResponse as? OKPacket {
                return ResultSet(affectedRows: okPacket.affectedRows, lastInsertID: okPacket.lastInsertID)
            }
            return ResultSet.empty
        }

        internal func response(from firstPacket: Packet, with additionalPackets: ArraySlice<Packet>) throws -> ResultSet {
            guard let firstByte = firstPacket.body.first else {
                throw ClientError.receivedNoResponse // TODO: (TL) new error (likely server?)
            }
            return ResultSet(packets: additionalPackets, columnCount: Int(firstByte))
        }

        // MARK: - Data Receive

        /**
         A helper function that attempts to parse a raw `Packet` from the socket stream.

         - parameter socket: The socket object previously created.
         - returns: A `Packet` object if successfully parsed.
         - throws: Any socket error encountered during the read process, any packet creation error if invalid data is received.
         */
        private func receive() throws -> [Packet] {
            // TODO: (TL) Add logging of bytes read in DEBUG MODE
            // TODO: (TL) see if we need to read more
            // TODO: (TL) Verify sequence numbers
            guard let socket = socket else {
                throw ClientError.noConnection // TODO: (TL) Manage state for these
            }
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
            return packets
        }

        internal func receiveCommandResponse() throws -> (firstPacket: Packet, additionalPackets: ArraySlice<Packet>?) {
            let packets = try receive()
            guard let firstPacket = packets.first else {
                throw ClientError.receivedNoResponse
            }
            
            // 1. Verify how many packets were received
            guard packets.count > 1 else {
                return (firstPacket, nil)
            }
            return (firstPacket, packets[1..<packets.count])
        }

        /**
         A helper function that writes a given set of `data` to the supplied `socket`.

         - parameter data: The raw `Data` to write.
         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the write process.
         */
        private func write(_ data: Data, _ incrementSequenceNumber: Bool = true) throws {
            guard let socket = socket else {
                throw ClientError.noConnection // TODO: (TL) Manage state for these
            }
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
