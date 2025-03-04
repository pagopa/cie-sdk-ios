//
//  NfcDigitalIdError.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CommonCrypto

public enum NfcDigitalIdError: Error, CustomStringConvertible, Equatable {
    case missingAuthenticationUrl
    case emptyPin
    case missingDeepLinkParameters
    case errorBuildingApdu
    case errorDecodingAsn1
    case secureMessagingHashMismatch
    case secureMessagingRequired
    case chipAuthenticationFailed
    case commonCryptoError(CCCryptorStatus, String)
    case tlsUnsupportedAlgorithm
    case tlsHashingFailed
    case idpEmptyBody
    case idpCodeNotFound
    case scanNotSupported
    case invalidTag
    case sendCommandForResponse
    case responseError(UInt8, UInt8)
    case genericError
    case wrongPin(Int)
    case cardBlocked
    
    public var description: String {
        switch self {
            case .scanNotSupported:
                return "This device doesn't support tag scanning"
            case .responseError(let sw1, let sw2):
                return APDUResponse.decodeError(sw1: sw1, sw2: sw2)
            case .invalidTag:
                return "Error reading tag"
            case .sendCommandForResponse:
                return "Send command to read response"
            case .missingAuthenticationUrl:
                return "Missing authentication url"
            case .emptyPin:
                return "Empty pin"
            case .missingDeepLinkParameters:
                return "Missing deeplink parameters"
            case .errorBuildingApdu:
                return "Error building apdu"
            case .errorDecodingAsn1:
                return "Error decoding asn1"
            case .secureMessagingHashMismatch:
                return "Secure messaging hash mismatch"
            case .secureMessagingRequired:
                return "Secure messaging required"
            case .chipAuthenticationFailed:
                return "Chip authentication failed"
            case .commonCryptoError(let status, let functionName):
                return "Error in \(functionName) \(status)"
            case .tlsUnsupportedAlgorithm:
                return "TLS Unsupported Algorithm"
            case .tlsHashingFailed:
                return "Failed to hash"
            case .idpEmptyBody:
                return "Idp Empty response"
            case .idpCodeNotFound:
                return "Idp Code not found"
            case .wrongPin(let remainingTries):
                return "Wrong pin, \(remainingTries)"
            case .cardBlocked:
                return "Card blocked"
            case .genericError:
                return "Generic error"
        }
    }
}


