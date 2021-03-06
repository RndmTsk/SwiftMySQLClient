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
            static let startTransaction = "START TRANSACTION"
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

        /// A global account of server capabilities - useful when constructing errors
        internal static var serverCapabilities: CapabilityFlag = []

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

         - throws: If the socket is unable to be created, if the connection fails or if authorization fails.
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

        // MARK: - Transactions
        public func startTransaction() -> Result<Transaction> {
            guard socket != nil, state == .connected else {
                    return .failure(ClientError.noConnection)
            }
            if let error = issue(.query, with: Constants.startTransaction) {
                return .failure(error)
            }
            return .success(Transaction(connection: self))
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

        public func delete(_ statement: String) -> Result<ResultSet> {
            return query(statement)
        }

        // MARK: - Statement Functions
        public func createStatement(with query: String) -> Statement {
            return Statement(query: query, connection: self)
        }

        public func prepareStatement(with query: String, cursor: PreparedStatement.Cursor = .none) -> Result<PreparedStatement> {
            do {
                let preparedStatement = try PreparedStatement(template: query, connection: self, cursorType: cursor)
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
                state = .disconnected
                throw ClientError.noConnection
            }
            state = .connecting
            try socket.connect(to: configuration.host, port: Int32(configuration.port))
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
                    try close()
                    throw result.error ?? ServerError.incorrectHandshakeResponseSize
            }
            guard let handshake = Handshake(data: handshakePacket.body)  else {
                throw ClientError.invalidHandshake
            }
            Connection.serverCapabilities = handshake.capabilityFlags
            print("    \(handshake)")
            self.handshake = handshake
            let handshakeResponse = HandshakeResponse(handshake: handshake, configuration: configuration)

            if let writeError = write(handshakeResponse.data) {
                throw writeError
            }

            result = receive()
            guard let packets = result.value,
                let commandPacket = packets.first,
                packets.count == 1 else {
                throw result.error ?? ServerError.incorrectCommandResponseSize
            }
            let parseResult = parseCommandResponse(from: commandPacket.body)
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
         n value of each parameter (value, signed-ness)
         
         *** NOTE ***
         // COM_STMT_EXECUTE, num-fields, field-pos offset == 0
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
            bytes.append(preparedStatement.cursorType.rawValue)
            bytes.append(contentsOf: [1, 0, 0, 0])

            let mapSize = (preparedStatement.parameterCount + 7) / 8
            var nullBitMap = [UInt8](repeatElement(0, count: mapSize))
            var fieldKeys = [UInt8]()
            var fieldValues = [UInt8]()
            if preparedStatement.usingNewValues {
                for (index, value) in preparedStatement.values.enumerated() {
                    guard let representedValue = value as? UInt8LSBArrayMappable else {
                        return ClientError.unsupportedDataType
                    }
                    // TODO: (TL) Support nil / omitted values?
                    if value is NSNull || (value is String && (value as! String).lowercased() == "null") {
                        nullBitMap[(index / 8)] |= UInt8(1 << (index % 8) & 0xff)
                    } else {
                        guard let columnData = preparedStatement.columnData(for: index) else {
                            return ClientError.invalidColumn
                        }
/* TODO: (TL) Interesting?
                        if ((mi.displayStyle == .optional) && (mi.children.count == 0)) || v is NSNull {
                            dataTypeArr += [UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_NULL))
                            continue
                        }
 */
                        fieldKeys.append(contentsOf: columnData)
                        fieldValues.append(contentsOf: representedValue.asUInt8Array)
                        // TODO: (TL) representedValue by columnData type (including restricting to proper size)
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
            let commandResponse = parseCommandResponse(from: packet.body)
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
                return .failure(ServerError.malformedCommandResponse)
            }
            return .success(ResultSet(packets: additionalPackets, columnCount: Int(firstByte)))
        }

        // MARK: - Data Receive

        /**
         A helper function that attempts to parse a raw `Packet` from the socket stream.

         - parameter socket: The socket object previously created.
         - returns: A `Packet` object if successfully parsed. An error otherwise.
         */
        private func receive() -> Result<[Packet]> {
            // TODO: (TL) Verify sequence numbers
            guard let socket = socket else {
                state = .disconnected
                return .failure(ClientError.noConnection)
            }
            var fullData = Data(capacity: Constants.headerSize)
            var result: Result<[Packet]>? = nil
            do {
                var interimData = Data(capacity: Constants.headerSize)
                // Can't base retry on bytes read, the socket will "miss"
                // data if it's busy processing a 0 length response
                while result == nil {
                    let bytesRead = try socket.read(into: &interimData)
                    fullData.append(interimData)
                    // Try to materialize a meaningful response
                    result = chunk(fullData)
                    if let error = result?.error as? ClientError,
                        error == ClientError.couldNotMaterializeResponse,
                        interimData.count > 0 {
                        print("[MySQL][#?]{READ} \(bytesRead) bytes (partial)")
                        result = nil // Keep trying for more
                    }
                    print("[MySQL][#\(result?.value?.first?.number ?? 0)]{READ} \(bytesRead) bytes")
                }
            } catch {
                return .failure(error)
            }
            return result ?? .failure(ClientError.couldNotMaterializeResponse)
        }

        private func chunk(_ data: Data) -> Result<[Packet]> {
            var packets = [Packet]()
            var remaining = data
            repeat {
                guard let packet = Packet(data: remaining) else {
                    return .failure(ClientError.couldNotMaterializeResponse)
                }
                packets.append(packet)
                remaining.droppingFirst(packet.length)
            } while remaining.count > 0
            return .success(packets)
        }

        internal func receiveCommandResponse() -> Result<ResultSet> {
            let result = receive()
            guard let packets = result.value,
                let firstPacket = packets.first else {
                return .failure(result.error ?? ClientError.receivedNoResponse)
            }

            // 1. Verify how many packets were received
            guard packets.count > 1 else {
                return basicResponse(from: firstPacket)
            }
            return response(from: firstPacket,
                            with: packets[1..<packets.count])
        }

        internal func receivePreparedStatementResponse() -> Result<PreparedStatementResponse> {
            let result = receive()
            guard let packets = result.value,
                let firstPacket = packets.first else {
                    return .failure(result.error ?? ClientError.receivedNoResponse)
            }
            // Ensure we have more than 1 packet
            guard packets.count > 1 else {
                return .failure(ServerError.malformedCommandResponse)
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
                state = .disconnected
                return ClientError.noConnection
            }
            if incrementSequenceNumber {
                sequenceNumber = (sequenceNumber + 1) % UInt8.max
            }
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
            print("[MySQL][#\(sequenceNumber)]{WRITE} \(data.count) bytes")
            return nil
        }

        /**
         A helper function that attempts to parse an `OK`, `EOF` or `ERR` packet response.

         - parameter data: The raw data received from the socket.
         - throws: Any errors encountered in constructing the packet response, any errors parsed from the server.
         */
        private func parseCommandResponse(from data: Data) -> Result<CommandPacket> {
            guard let responseFlag = data.first else {
                return .failure(ServerError.emptyResponse)
            }
            let remaining = data.subdata(in: 1..<data.count)
            if responseFlag == MySQL.Constants.ok
                && data.count >= MySQL.Constants.okResponseMinLength {
                return .success(OKPacket(data: remaining))
            } else if responseFlag == MySQL.Constants.eof
                && data.count < MySQL.Constants.eofResponseMaxLength {
                // Properly formatted EOF packet
                return .success(EOFPacket(data: remaining))
            } else if responseFlag == MySQL.Constants.err {
                // Properly formatted error packet
                return .failure(ServerError(data: remaining))
            } else { // Unknown response
                return .failure(ServerError.unknown)
            }
        }
    }
}
