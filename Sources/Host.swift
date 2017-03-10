//
//  Host.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-10.
//
//

#if os(macOS)
    import Foundation
#else
    import Glibc
#endif

public extension MySQL {
    public struct Host {
        let name: String
        let ipAddress: String
        
        init?(name: String) {
            guard let hostEntry = gethostbyname(name) else {
                return nil // TODO: (TL) Throw error?
            }
            self.name = ""
            self.ipAddress = "" // TODO: (TL)
        }
    }
}
