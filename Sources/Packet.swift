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
            internal static let headerLength = 4
        }
        internal let number: UInt8
        internal let bodyLength: Int
        internal var length: Int {
            return bodyLength + Constants.headerLength
        }
        internal let body: Data

        internal var description: String {
            return "[#\(number)]{READ} \(length) bytes"
        }

        init?(data: Data) {
            guard data.count > 0 else {
                return nil
            }
            guard data.count > Constants.headerLength else {
                return nil
            }
            let bodyLength = data.int(of: 3)
            guard data.count - Constants.headerLength >= bodyLength else {
                return nil
            }
            // Message bodyLength takes up the first 3 bytes
            self.bodyLength = bodyLength
            // Packet number is the 4th byte of the header
            self.number = data[3]
            // Body is remaining data
            self.body = data.subdata(in: Constants.headerLength..<Constants.headerLength + bodyLength)
        }
    }
}
