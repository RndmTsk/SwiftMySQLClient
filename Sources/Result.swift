//
//  Result.swift
//  SwiftMySQLClient
//
//  Created by Terry Latanville on 2017-04-25.
//
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)

    public var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
