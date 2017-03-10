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
                .clientProtocol41,
                .clientLongFlag,
                .clientTransactions,
                .clientSecureConnection,
                .clientLocalFiles,
                .clientMultiStatements,
                .clientMultiResults,
            ]
        }

        public let host: Host
        public let port: Int // TODO: (TL) Elevated type
        public let database: String? // TODO: (TL) Elevated type
        public let credentials: URLCredential?
        public let capabilities: MySQL.CapabilityFlag

        public init?(host: String,
                     port: Int = 3306,
                     database: String? = nil,
                     credentials: URLCredential? = nil,
                     capabilities: MySQL.CapabilityFlag = ClientConfiguration.Defaults.capabilities) {
            guard let mySQLHost = Host(name: host) else {
                return nil
            }
            self.host = mySQLHost
            self.port = port
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
