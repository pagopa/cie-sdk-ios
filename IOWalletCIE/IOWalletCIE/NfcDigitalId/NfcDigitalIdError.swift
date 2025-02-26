//
//  NfcDigitalIdError.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

public enum NfcDigitalIdError: Error, CustomStringConvertible, Equatable {
    case scanNotSupported
    case invalidTag
    case sendCommandForResponse
    case responseError(String)
    
    public var description: String {
        switch self {
        case .scanNotSupported:
            return "This device doesn't support tag scanning"
        case .responseError(let message):
            return message
        case .invalidTag:
            return "Error reading tag"
        case .sendCommandForResponse:
            return "Send command to read response"
        }
    }
}


