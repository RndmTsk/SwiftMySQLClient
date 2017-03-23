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
    // SHA1( password ) XOR SHA1( "20-bytes random data from server" <concat> SHA1( SHA1( password ) ) )
    internal func native41SecurePassword(with salt: String) -> [UInt8] {
        guard let password = password else {
            return []
        }
        let sha1Password = password.sha1()
        let scramble = salt.appending(sha1Password.sha1()).sha1()

        var result = [UInt8]()

        // Both are the same length
        let utf8Password = Array(sha1Password.utf8)
        let utf8Scramble = Array(scramble.utf8)

        for (index, character) in utf8Password.enumerated() {
            result.append(character ^ utf8Scramble[index])
        }
        return result
    }
}
