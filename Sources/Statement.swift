//
//  Statement.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-15.
//
//

import Foundation

public extension MySQL {
    public struct Statement {
        public let query: String

        weak internal var connection: Connection?

        internal init(query: String, connection: Connection) {
            self.query = query
            self.connection = connection
        }

        public func execute() -> Result<ResultSet> {
            guard let connection = connection else {
                return .failure(ClientError.noConnection)
            }
            return connection.query(query)
        }
    }
}
