//
//  Statement.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-15.
//
//

import Foundation

public extension MySQL {
    public struct Statement: CustomStringConvertible {
        private struct Constants {
            static let placeholder = "?"
        }
        private let queryComponents: [String]
        private var lastValuesUsed: [Any]?
        weak internal var connection: Connection?

        public var description: String {
            if queryComponents.count > 1, let lastValuesUsed = lastValuesUsed {
                return zip(queryComponents, lastValuesUsed).reduce("") {
                    $0.appending($1.0).appending(String(describing: $1.1))
                }
            }
            return queryComponents.joined(separator: "?")
        }

        internal init(query: String, connection: Connection) {
            self.queryComponents = query.components(separatedBy: Constants.placeholder)
            self.connection = connection
            self.lastValuesUsed = nil
        }

        public mutating func execute(with values: [Any]? = nil) -> Result<ResultSet> {
            guard let connection = connection else {
                return .failure(ClientError.noConnection)
            }
            lastValuesUsed = values
            if queryComponents.count == 1 {
                return connection.query(queryComponents[0]) // Simple query
            }
            guard let values = values,
                values.count == (queryComponents.count - 1) else {
                return .failure(ClientError.invalidParameterList)
            }
            let query = zip(queryComponents, values).reduce("") {
                $0.appending($1.0).appending(String(describing: $1.1))
            }
            return connection.query(query)
        }
    }
}
