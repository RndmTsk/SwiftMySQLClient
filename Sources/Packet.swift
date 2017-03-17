//
//  Packet.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-16.
//
//

import Foundation

public extension MySQL {
    public struct Packet {
        public final class Constants {
            public static let minLength = 4
        }
        public let length: Int
        public let number: Int
        public let body: Data

        init(data: Data) throws {
            guard data.count > Constants.minLength else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "INCORRECT HEADER SIZE"])
            }
            let length = data.int(of: 3)
            guard (data.count - Constants.minLength) == length else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: ["ERROR" : "INCORRECT BODY SIZE"])
            }
            // Message length takes up the first 3 bytes
            self.length = length
            // Packet number is the 4th byte of the header
            self.number = Int(data[3])
            // Body is remaining data
            self.body = data.subdata(in: Constants.minLength..<data.count)
        }
    }
}
