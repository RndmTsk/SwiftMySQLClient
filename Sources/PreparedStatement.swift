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
        public var statementID: Int?
        public let template: String

        weak internal var connection: Connection?

        internal init(template: String, connection: Connection) throws {
            self.template = template
            self.connection = connection
            self.statementID = nil

            try self.prepare()
        }

        internal mutating func prepare() throws {
            guard let connection = connection else {
                throw ClientError.noConnection
            }
            let resultSet = try connection.issue(.stmtPrepare, with: template)
            print("[PREPARED STATEMENT] \(resultSet)")
            statementID = resultSet.statementID
        }

        // .stmtFetch ??
        // .stmtSendLongData ??

        public func execute(with values: [Any]) throws -> ResultSet {
            guard let connection = connection else {
                throw ClientError.noConnection
            }
            return try connection.issue(.stmtExecute, with: self)
            // TODO: (TL) issue prepared statement w/ values
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
            return try connection.issue(command)
        }
    }
}
