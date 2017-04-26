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
            // TODO: (TL) Check other stuff like in transaction
            state = .disconnecting
            let success = {
                self.socket?.close()
                self.state = .disconnected
            }
            guard let error = issue(.quit) else {
                success()
                return
            }
            // COM_QUIT can either be EOF _or_ 0 length
            if let packetError = error as? PacketError,
                packetError == .noData {
                success()
                return
            }
            throw error
        }

        // MARK: - Common Command Helper Functions
        public func query(_ statement: String) -> Result<ResultSet> {
            if let error = issue(.query, with: statement) {
                return .failure(error)
            }
            return receiveCommandResponse()
        }

        public func insert(_ statement: String) -> Result<ResultSet> {
            return query(statement)
        }

        public func update(_ statement: String) -> Result<ResultSet> {
            return query(statement)
        }

        // MARK: - Statement Functions
        public func createStatement(with query: String) -> Statement {
            return Statement(query: query, connection: self)
        }

        public func prepareStatement(with query: String) -> Result<PreparedStatement> {
            do {
                let preparedStatement = try PreparedStatement(template: query, connection: self)
                return .success(preparedStatement)
            } catch {
                return .failure(error)
            }
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
            var result = receive()
            guard let authPackets = result.value,
                let handshakePacket = authPackets.first,
                authPackets.count == 1 else {
                throw result.error ?? ClientError.receivedExtraPackets // TODO: (TL) is this actually an error??
            }
            // TODO: (TL) Check packet type
            guard let handshake = Handshake(data: handshakePacket.body)  else {
                throw ClientError.invalidHandshake
            }
            print("    \(handshake)")
            self.handshake = handshake
            let handshakeResponse = HandshakeResponse(handshake: handshake, configuration: configuration)

            if let writeError = write(handshakeResponse.data) {
                throw writeError
            }

            // TODO: (TL) Verify sequence number
            result = receive()
            guard let packets = result.value,
                let commandPacket = packets.first,
                packets.count == 1 else {
                throw result.error ?? ClientError.receivedExtraPackets
            }
            let parseResult = parseCommandResponse(from: commandPacket.body, with: handshake.capabilityFlags)
            if let parseError = parseResult.error {
                throw parseError
            }
            // TODO: (TL) Nothing happens with response?
        }

        internal func issue(_ command: Command, with statement: String? = nil) -> Error? {
            // https://dev.mysql.com/doc/internals/en/sequence-id.html
            // - Sequence number resets for each command
            sequenceNumber = 0

            var bytes: [UInt8] = [command.rawValue]
            if let text = statement {
                bytes.append(contentsOf: text.utf8)
                bytes.append(0)
            }
            return write(Data(bytes: bytes), false)
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
        internal func issue(_ preparedStatement: PreparedStatement) -> Error? {
            // https://dev.mysql.com/doc/internals/en/sequence-id.html
            // - Sequence number resets for each command
            sequenceNumber = 0

            var bytes: [UInt8] = [Command.stmtExecute.rawValue]
            bytes.append(contentsOf: preparedStatement.statementID)
            bytes.append(0) // TODO: (TL) Specify cursor type in creation?
            bytes.append(contentsOf: [1, 0, 0, 0])

            let mapSize = (preparedStatement.parameterCount + 7) / 8
            var nullBitMap = [UInt8](repeatElement(0, count: mapSize))
            var fieldKeys = [UInt8]()
            var fieldValues = [UInt8]()
            if preparedStatement.usingNewValues {
                for (index, value) in preparedStatement.values.enumerated() {
                    guard let representedValue = value as? UInt8LSBArrayMappable else {
                        return ClientError.noConnection // TODO: (TL) New error type for "unsupported data type"
                    }

                    // TODO: (TL) turn into NULL-bitmap and parameters
                    if value is NSNull || (value is String && (value as! String).lowercased() == "null") {
                        nullBitMap[0] |= 1 // <<
                    } else {
                        guard let columnType = preparedStatement.columnType(for: index) else {
                            return ClientError.invalidHandshake // TODO: (TL) New error type for prepared statement column index
                        }
                        fieldKeys.append(columnType.rawValue)
                        fieldValues.append(contentsOf: representedValue.asUInt8Array)
                    }
                }
            }
            
            bytes.append(contentsOf: nullBitMap)
            if preparedStatement.usingNewValues {
                bytes.append(1)
                bytes.append(contentsOf: fieldKeys)
                bytes.append(contentsOf: fieldValues)
            } else {
                bytes.append(0)
            }
            return write(Data(bytes: bytes), false)
        }

        // MARK: - Command Response
        internal func basicResponse(from packet: Packet) -> Result<ResultSet> {
            let commandResponse = parseCommandResponse(from: packet.body,
                                                       with: handshake?.capabilityFlags)
            if let okPacket = commandResponse.value as? OKPacket {
                let resultSet = ResultSet(affectedRows: okPacket.affectedRows, lastInsertID: okPacket.lastInsertID)
                return .success(resultSet)
            } else if let error = commandResponse.error {
                return .failure(error)
            } else {
                return .success(ResultSet.empty) // Deprecated EOF Packet
            }
        }

        internal func response(from firstPacket: Packet,
                               with additionalPackets: ArraySlice<Packet>) -> Result<ResultSet> {
            guard let firstByte = firstPacket.body.first else {
                return .failure(ClientError.receivedNoResponse) // TODO: (TL) new error (likely server?)
            }
            return .success(ResultSet(packets: additionalPackets, columnCount: Int(firstByte)))
        }

        // MARK: - Data Receive

        /**
         A helper function that attempts to parse a raw `Packet` from the socket stream.

         - parameter socket: The socket object previously created.
         - returns: A `Packet` object if successfully parsed.
         - throws: Any socket error encountered during the read process, any packet creation error if invalid data is received.
         */
        private func receive() -> Result<[Packet]> {
            // TODO: (TL) Add logging of bytes read in DEBUG MODE
            // TODO: (TL) see if we need to read more
            // TODO: (TL) Verify sequence numbers
            guard let socket = socket else {
                return .failure(ClientError.noConnection) // TODO: (TL) Manage state for these
            }
            var data = Data(capacity: Constants.headerSize)
            do {
                _ = try socket.read(into: &data)
                return .success(try chunk(data))
            } catch {
                return .failure(error)
            }
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

        internal func receiveCommandResponse() -> Result<ResultSet> {
            let result = receive()
            guard let packets = result.value,
                let firstPacket = packets.first else {
                return .failure(result.error ?? ClientError.receivedNoResponse)
            }

            // 1. Verify how many packets were received
            guard packets.count > 1 else {
                return response(from: firstPacket,
                                with: packets[1..<packets.count])
            }
            return basicResponse(from: firstPacket)
        }

        internal func receivePreparedStatementResponse() -> Result<PreparedStatementResponse> {
            let result = receive()
            guard let packets = result.value,
                let firstPacket = packets.first else {
                    return .failure(result.error ?? ClientError.receivedNoResponse)
            }
            // Ensure we have more than 1 packet
            guard packets.count > 1 else {
                return .failure(ClientError.receivedNoResponse) // TODO: (TL) New error type
            }
            do {
                let response = try PreparedStatementResponse(firstPacket: firstPacket,
                                                             additionalPackets: packets[1..<packets.count])
                return .success(response)
            } catch {
                return .failure(error)
            }
        }

        /**
         A helper function that writes a given set of `data` to the supplied `socket`.

         - parameter data: The raw `Data` to write.
         - parameter socket: The socket object previously created.
         - throws: Any socket error encountered during the write process.
         */
        private func write(_ data: Data, _ incrementSequenceNumber: Bool = true) -> Error? {
            guard let socket = socket else {
                return ClientError.noConnection // TODO: (TL) Manage state for these
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
            do {
                try socket.write(from: packetData)
            } catch {
                return error
            }
            // TODO: (TL) Add logging of bytes read in DEBUG MODE
            print("[#\(sequenceNumber)]{WRITE} \(data.count) bytes")
            return nil
        }

        /**
         A helper function that attempts to parse an `OK`, `EOF` or `ERR` packet response.

         - parameter data: The raw data received from the socket.
         - throws: Any errors encountered in constructing the packet response, any errors parsed from the server.
         */
        private func parseCommandResponse(from data: Data, with capabilities: CapabilityFlag? = nil) -> Result<CommandPacket> {
            guard let responseFlag = data.first else {
                return .failure(ServerError.emptyResponse(with: capabilities))
            }
            let remaining = data.subdata(in: 1..<data.count)
            if responseFlag == MySQL.Constants.ok
                && data.count >= MySQL.Constants.okResponseMinLength {
                return .success(OKPacket(data: remaining, serverCapabilities: capabilities))
            } else if responseFlag == MySQL.Constants.eof
                && data.count < MySQL.Constants.eofResponseMaxLength {
                // Properly formatted EOF packet
                return .success(EOFPacket(data: remaining, serverCapabilities: capabilities))
            } else if responseFlag == MySQL.Constants.err {
                // Properly formatted error packet
                return .failure(ServerError(data: remaining, capabilities: capabilities))
            } else { // Unknown response
                return .failure(ServerError.unknown(with: capabilities))
            }
        }
    }
}
