//
//  CommandPacket.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-12.
//
//

import Foundation

internal enum CommandPacketType {
    case ok
    case eof
    case err
}

internal protocol CommandPacket {
    var packetType: CommandPacketType { get }
    var length: Int { get }
}
