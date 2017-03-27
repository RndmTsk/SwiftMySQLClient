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
        internal let number: Int
        internal let body: Data
        internal var description: String {
            return "#\(number) - Body: \(body) {L:\(length)}"
        }

        init(data: Data) throws {
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
            self.number = Int(data[3])
            // Body is remaining data
            self.body = data.subdata(in: Constants.minLength..<data.count)
            print("[READ #\(number)] \(length) bytes")
        }
    }
}
