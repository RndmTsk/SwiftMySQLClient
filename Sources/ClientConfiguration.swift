//
//  ClientConfiguration.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

import Foundation

public extension MySQL {
    public struct ClientConfiguration {
        public class Defaults {
            public static let capabilities: CapabilityFlag = [
                .clientLongPassword, // TODO: (TL) Dig into capabilities more
                .clientProtocol41,
                .clientTransactions,
                .clientSecureConnection
            ]
        }

        public let host: String
        public let port: Int32
        public let database: String? // TODO: (TL) Elevated type
        public let credentials: URLCredential?
        public let capabilities: MySQL.CapabilityFlag

        public init(host: String,
                    port: Int = 3306,
                    database: String? = nil,
                    credentials: URLCredential? = nil,
                    capabilities: MySQL.CapabilityFlag = ClientConfiguration.Defaults.capabilities) {
            self.host = host
            self.port = Int32(port)
            self.database = database
            self.credentials = credentials

            if database != nil && !capabilities.contains(.clientConnectWithDB) {
                self.capabilities = [capabilities, .clientConnectWithDB]
            } else {
                self.capabilities = capabilities
            }
        }
    }
}
