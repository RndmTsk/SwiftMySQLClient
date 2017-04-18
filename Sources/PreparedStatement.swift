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

            try self.prepare()
        }

        internal mutating func prepare() throws {
            guard let connection = connection else {
                throw ClientError.noConnection
            }
            try connection.issue(.stmtPrepare, with: template)
            let commandResponse = try connection.receiveCommandResponse()
            guard let additionalPackets = commandResponse.additionalPackets else {
                throw ClientError.receivedNoResponse // TODO: (TL) New error type
            }
            let response = try PreparedStatementResponse(firstPacket: commandResponse.firstPacket, additionalPackets: additionalPackets)
            print("[PREPARED STATEMENT] \(response)")
            statementID = response.statementID
            parameterCount = response.parameterCount
            columns = response.columns
        }

        // .stmtFetch ??
        // .stmtSendLongData ??

        public mutating func reExecute() throws -> ResultSet {
            usingNewValues = false
            return try execute()
        }

        public mutating func execute(with values: [Any]) throws -> ResultSet {
            self.usingNewValues = true
            self.values = values
            return try execute()
        }

        private func execute() throws -> ResultSet {
            guard let connection = connection else {
                throw ClientError.noConnection
            }
            guard parameterCount == values.count else {
                throw ClientError.receivedNoResponse // TODO: (TL) New error type
            }
            try connection.issue(self)
            // TODO: (TL) ...
            return ResultSet.empty
        }

        public func reset() throws {
            let resultSet = try issueSimpleCommand(.stmtReset)
            print("[PREPARED STATEMENT] \(resultSet)")
        }

        public func close() throws {
            let resultSet = try issueSimpleCommand(.stmtClose)
            print("[PREPARED STATEMENT] \(resultSet)")
        }

        private func issueSimpleCommand(_ command: Command) throws -> ResultSet {
            guard let connection = connection else {
                throw ClientError.noConnection
            }
            try connection.issue(command)
            let commandResponse = try connection.receiveCommandResponse()
            return try connection.basicResponse(from: commandResponse.firstPacket)
        }
    }
}
