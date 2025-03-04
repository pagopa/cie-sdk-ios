//
//  DES.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//
import CommonCrypto
import Foundation

class DES {
    @available(iOS 13, macOS 10.15, *)
    public static func encrypt(key:[UInt8], message:[UInt8], iv:[UInt8], options:UInt32 = 0) throws -> [UInt8] {
        
        let dataLength = message.count
        
        let cryptLen = message.count + kCCBlockSizeDES
        var cryptData = Data(count: cryptLen)
        
        let keyLength              = size_t(kCCKeySizeDES)
        let operation: CCOperation = UInt32(kCCEncrypt)
        let algorithm:  CCAlgorithm = UInt32(kCCAlgorithmDES)
        let options:   CCOptions   = options
        
        var numBytesEncrypted = 0
        
        let cryptStatus = key.withUnsafeBytes {keyBytes in
            message.withUnsafeBytes{ dataBytes in
                iv.withUnsafeBytes{ ivBytes in
                    cryptData.withUnsafeMutableBytes{ cryptBytes in
                        CCCrypt(operation,
                                algorithm,
                                options,
                                keyBytes.baseAddress,
                                keyLength,
                                ivBytes.baseAddress,
                                dataBytes.baseAddress,
                                dataLength,
                                cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                                cryptLen,
                                &numBytesEncrypted)
                        
                    }
                }
            }
        }
        
        if cryptStatus == kCCSuccess {
            cryptData.count = Int(numBytesEncrypted)
            
            return [UInt8](cryptData)
        } else {
            throw NfcDigitalIdError.commonCryptoError(cryptStatus, "DES.encrypt")
        }
    }
    
    @available(iOS 13, macOS 10.15, *)
    public static func decrypt(key:[UInt8], message:[UInt8], iv:[UInt8], options:UInt32 = 0) throws -> [UInt8] {
        
        let dataLength = message.count
        
        let cryptLen = message.count + kCCBlockSizeDES
        var cryptData = Data(count: cryptLen)
        
        let keyLength              = size_t(kCCKeySizeDES)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algorithm:  CCAlgorithm = UInt32(kCCAlgorithmDES)
        let options:   CCOptions   = options
        
        var numBytesEncrypted = 0
        
        let cryptStatus = key.withUnsafeBytes {keyBytes in
            message.withUnsafeBytes{ dataBytes in
                iv.withUnsafeBytes{ ivBytes in
                    cryptData.withUnsafeMutableBytes{ cryptBytes in
                        CCCrypt(operation,
                                algorithm,
                                options,
                                keyBytes.baseAddress,
                                keyLength,
                                nil,
                                dataBytes.baseAddress,
                                dataLength,
                                cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                                cryptLen,
                                &numBytesEncrypted)
                        
                    }
                }
            }
        }
        
        if cryptStatus == kCCSuccess {
            cryptData.count = Int(numBytesEncrypted)
            
            return [UInt8](cryptData)
        } else {
            throw NfcDigitalIdError.commonCryptoError(cryptStatus, "DES.decrypt")
        }
    }
}
