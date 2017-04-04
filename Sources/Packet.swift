//
//  Packet.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-16.
//
//

import Foundation

internal extension MySQL {
    // https://dev.mysql.com/doc/internals/en/mysql-packet.html
    internal struct Packet: CustomStringConvertible {
        internal final class Constants {
            internal static let minLength = 4
        }
        internal let length: Int
        internal let number: UInt8
        internal let body: Data
        internal var description: String {
            return "[#\(number)]{READ} \(length) bytes"
        }

        init(data: Data) throws {
            guard data.count > 0 else {
                throw PacketError.noData
            }
            guard data.count > Constants.minLength else {
                throw PacketError.incorrectHeaderLength
            }
            let length = data.int(of: 3)
            guard (data.count - Constants.minLength) == length else {
                throw PacketError.incorrectBodyLength
            }
            // Message length takes up the first 3 bytes
            self.length = length
            // Packet number is the 4th byte of the header
            self.number = data[3]
            // Body is remaining data
            self.body = data.subdata(in: Constants.minLength..<data.count)
        }
    }
}
