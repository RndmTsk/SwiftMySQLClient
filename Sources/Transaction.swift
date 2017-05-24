//
//  Transaction.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-05-24.
//
//

import Foundation

public extension MySQL {
    public struct Transaction {
        // MARK: - Constants
        private struct Constants {
            static let commit = "COMMIT"
            static let rollback = "ROLLBACK"
        }

        // MARK: - Properties
        private var connection: Connection?

        // MARK: - Lifecycle Functions
        internal init(connection: Connection) {
            self.connection = connection
        }

        public mutating func commit() -> Error? {
            // TODO: (TL) Other return values?
            guard let connection = connection,
                connection.state == .connected else {
                return ClientError.noConnection
            }
            if let error = connection.issue(.query, with: Constants.commit) {
                return error
            }
            self.connection = nil // Done w/ this transaction
            return nil
        }

        public mutating func rollback() -> Error? {
            guard let connection = connection,
                connection.state == .connected else {
                    return ClientError.noConnection
            }
            if let error = connection.issue(.query, with: Constants.rollback) {
                return error
            }
            self.connection = nil // Done with this transaction
            return nil
        }
    }
}
