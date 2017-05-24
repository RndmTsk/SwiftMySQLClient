//
//  ClientConfiguration.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation

/// Namespace everything with MySQL - the PostgreSQL driver does this.
public extension MySQL {
    /// A structure representing the client configuration.
    public struct ClientConfiguration {
        /// The host IP or name of the MySQL instance.
        public let host: String
        /// The port on which to connect to the MySQL instance.
        public let port: Int
        /// An optional property representing the name of the database to use by default.
        public let database: String?
        /// An optional property representing the credentials to be used when connecting to the database.
        public let credentials: URLCredential?
        /// The configured capabilities of this client.
        public let capabilities: CapabilityFlag

        /// The default capabilities of this client.
        public static let baseCapabilities: CapabilityFlag = [
            .clientLongPassword,
            .clientProtocol41,
            .clientTransactions,
            .clientSecureConnection,
            .clientDeprecateEOF
        ]

        /**
         Constructs a `ClientConfiguration` with the specified `host`, `port`, `database`, `credentials` and `capabilities`.

         - parameter host: The host IP or name of the MySQL instance.
         - parameter port: The port on which to connect to the MySQL instance - defaults to 3306
         - parameter database: An optional property representing the credentials to be used when connecting to the database.
         - parameter credentials: An optional property representing the credentials to be used when connecting to the database.
         */
        public init(host: String,
                    port: Int = 3306,
                    database: String? = nil,
                    credentials: URLCredential? = nil) {
            self.host = host
            self.port = port
            self.database = database
            self.credentials = credentials

            if database == nil {
                self.capabilities = ClientConfiguration.baseCapabilities
            } else { // If a DB is specified, add the flag.
                self.capabilities = [
                    ClientConfiguration.baseCapabilities,
                    .clientConnectWithDB
                ]
            }
        }
    }
}
