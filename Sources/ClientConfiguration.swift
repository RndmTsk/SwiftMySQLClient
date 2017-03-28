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
        /// A structure that contains convenience default values.
        public struct Defaults {
            /// The default capabilities of this client - TODO: (TL) Add dynamic plugin capabilities
            public static let capabilities: CapabilityFlag = [
                .clientLongPassword,
                .clientProtocol41,
                .clientTransactions,
                .clientSecureConnection,
                .clientDeprecateEOF
            ]
        }

        /// The host IP or name of the MySQL instance.
        public let host: String
        /// The port on which to connect to the MySQL instance.
        public let port: Int32
        /// An optional property representing the name of the database to use by default.
        public let database: String?
        /// An optional property representing the credentials to be used when connecting to the database.
        public let credentials: URLCredential?
        /// The capabilities of this client. - TODO: (TL) Add dynamic plugin capabilities.
        public let capabilities: CapabilityFlag

        /**
         Constructs a `ClientConfiguration` with the specified `host`, `port`, `database`, `credentials` and `capabilities`.

         - parameter host: The host IP or name of the MySQL instance.
         - parameter port: The port on which to connect to the MySQL instance - defaults to 3306
         - parameter database: An optional property representing the credentials to be used when connecting to the database.
         - parameter credentials: An optional property representing the credentials to be used when connecting to the database.
         - parameter capabilities: The capabilities of this client. - TODO: (TL) Add dynamic plugin capabilities.
         */
        public init(host: String,
                    port: Int = 3306,
                    database: String? = nil,
                    credentials: URLCredential? = nil,
                    capabilities: MySQL.CapabilityFlag = ClientConfiguration.Defaults.capabilities) {
            self.host = host
            self.port = Int32(port)
            self.database = database
            self.credentials = credentials

            if database != nil && !capabilities.contains(.clientConnectWithDB) { // If a DB is specified, add the flag.
                self.capabilities = [capabilities, .clientConnectWithDB]
            } else if database == nil && capabilities.contains(.clientConnectWithDB) { // Remove the flag if no DB is specified.
                self.capabilities = CapabilityFlag(rawValue: capabilities.rawValue & ~CapabilityFlag.clientConnectWithDB.rawValue)
            } else {
                self.capabilities = capabilities
            }
        }
    }
}
