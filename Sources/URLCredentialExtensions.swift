//
//  URLCredentialExtensions.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-03-23.
//
//

import Foundation
import CryptoSwift

internal extension URLCredential {
    // TODO: (TL) Link to docs
    // SHA1( password ) XOR SHA1( "20-bytes random data from server" <concat> SHA1( SHA1( password ) ) )
    internal func native41SecurePassword(with salt: [UInt8]) -> [UInt8] {
        guard let password = password else {
            return []
        }
        let sha1Password = Array(password.utf8).sha1()
        let scramble = (salt + sha1Password.sha1()).sha1()

        var result = [UInt8]()

        // Both are the same length
        for (index, character) in sha1Password.enumerated() {
            result.append(character ^ scramble[index])
        }
        return result
    }
}
