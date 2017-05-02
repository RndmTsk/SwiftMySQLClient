//
//  PreparedStatement.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-15.
//
//

import Foundation

public extension MySQL {
    public struct PreparedStatement {
        private struct Constants {
            static let unsignedMarker: UInt8 = 0x80
        }

        public let template: String
        public private(set) var statementID = [UInt8]()
        public private(set) var parameterCount = 0
        public private(set) var values = [Any]()
        public private(set) var columns = [Column]()

        internal private(set) var usingNewValues = false

        weak internal var connection: Connection?

        internal init(template: String, connection: Connection) throws {
            self.template = template
            self.connection = connection

            if let error = self.prepare() {
                throw error
            }
        }

        internal mutating func prepare() -> Error? {
            guard let connection = connection else {
                return ClientError.noConnection
            }
            if let error = connection.issue(.stmtPrepare, with: template) {
                return error
            }
            switch connection.receivePreparedStatementResponse() {
            case .failure(let error):
                return error
            case .success(let response):
                // TODO: (TL) WIP
                print("[PREPARED STATEMENT] \(response)")
                statementID = response.statementID
                parameterCount = response.parameterCount
                columns = response.columns
            }
            return nil
        }

        // .stmtFetch ??
        // .stmtSendLongData ??

        public mutating func reExecute() -> Result<ResultSet> {
            usingNewValues = false
            return execute()
        }

        public mutating func execute(with values: [Any]) -> Result<ResultSet> {
            self.usingNewValues = true
            self.values = values
            return execute()
        }

        private func execute() -> Result<ResultSet> {
            guard let connection = connection else {
                return .failure(ClientError.noConnection)
            }
            guard parameterCount == values.count else {
                // TODO: (TL) New error type
                return .failure(ClientError.receivedNoResponse)
            }
            if let error = connection.issue(self) {
                return .failure(error)
            }
            return connection.receiveCommandResponse()
        }

        public func reset() -> Result<ResultSet> {
            let resultSet = issueSimpleCommand(.stmtReset)
            print("[PREPARED STATEMENT] \(resultSet)")
            return resultSet
        }

        public func close() -> Result<ResultSet> {
            let resultSet = issueSimpleCommand(.stmtClose)
            print("[PREPARED STATEMENT] \(resultSet)")
            return resultSet
        }

        private func issueSimpleCommand(_ command: Command) -> Result<ResultSet> {
            guard let connection = connection else {
                return .failure(ClientError.noConnection)
            }
            if let error = connection.issue(command) {
                return .failure(error)
            }
            return connection.receiveCommandResponse()
        }

        internal func columnData(for index: Int) -> [UInt8]? {
            guard index < columns.count else {
                return nil
            }
            /*
             It sends the values for the placeholders of the prepared statement (if it contained any) in Binary Protocol Value form. The type of each parameter is made up of two bytes:
             
             the type as in Protocol::ColumnType
             
             a flag byte which has the highest bit set if the type is unsigned [80]
             */
            let firstByte = columns[index].flags.contains(.unsigned) ? Constants.unsignedMarker : 0
            return [firstByte, columns[index].columnType.rawValue]
        }
    }
}
