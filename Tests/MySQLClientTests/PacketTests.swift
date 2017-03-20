//
//  PacketTests.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-19.
//
//

import XCTest
@testable import SwiftMySQLClient

class PacketTests: XCTestCase {
    func test01HeaderSizeInvalid() {
        do {
            // Empty payload
            _ = try MySQL.Packet(data: Data())
        } catch {
            guard let clientError = error as? MySQL.PacketError,
                clientError == .incorrectHeaderLength else {
                XCTFail("Encountered unexpected error: \(error)")
                return
            }
            return
        }
        XCTFail("Expected error from empty packet")
    }

    func test02BodySizeInvalid() {
        do {
            // Length = 1, data.count = 2
            let data = Data(bytes: [1, 0, 0, 0, 0, 0])
            _ = try MySQL.Packet(data: data)
        } catch {
            guard let clientError = error as? MySQL.PacketError,
                clientError == .incorrectBodyLength else {
                    XCTFail("Encountered unexpected error: \(error)")
                    return
            }
            return
        }
        XCTFail("Expected error from empty packet")
    }

    func test03ProperPacket() {
        do {
            // https://dev.mysql.com/doc/internals/en/mysql-packet.html
            let data = Data(bytes: [1,
                                    0,
                                    0,
                                    0,
                                    MySQL.Command.quit.rawValue])
            let packet = try MySQL.Packet(data: data)
            guard packet.length == 1, packet.number == 0, packet.body[0] == MySQL.Command.quit.rawValue else {
                XCTFail("Packet not parsed correctly, expected: Length: 1, Number: 0, Body: 1, got: \(packet)")
                return
            }
        } catch {
            XCTFail("Encountered unexpected error: \(error)")
        }
    }
}
