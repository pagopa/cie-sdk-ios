//
//  AES.swift
//  CieSDK
//
//  Created by antoniocaparello on 26/08/25.
//

import Foundation
import OSLog
import CommonCrypto

class AES {
    /// Encrypts a message using AES/CBC/NOPADDING with a specified key and initialisation vector
    /// - Parameter key: Key use to encrypt
    /// - Parameter message: Message to encrypt
    /// - Parameter iv: Initialisation vector
    @available(iOS 13, macOS 10.15, *)
    public static func encrypt(key:[UInt8], message:[UInt8], iv:[UInt8]) throws -> [UInt8] {
        
        let dataLength = message.count
        
        let cryptLen = message.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLen)

        let keyLength              = size_t(key.count)
        let operation: CCOperation = CCOperation(kCCEncrypt)
        let algorithm:  CCAlgorithm = CCAlgorithm(kCCAlgorithmAES)
        let options:   CCOptions   = CCOptions(0)
        
        var numBytesEncrypted = 0
        
        var cryptStatus: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
        key.withUnsafeBytes {keyBytes in
            message.withUnsafeBytes{ dataBytes in
                iv.withUnsafeBytes{ ivBytes in
                    cryptData.withUnsafeMutableBytes{ cryptBytes in

                        cryptStatus = CCCrypt(operation,
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
            throw  NfcDigitalIdError.commonCryptoError(cryptStatus, "AES.encrypt")
        }
        return []
    }

    /// Decrypts a message using AES/CBC/NOPADDING with a specified key and initialisation vector
    /// - Parameter key: Key use to decrypt
    /// - Parameter message: Message to decrypt
    /// - Parameter iv: Initialisation vector
    @available(iOS 13, macOS 10.15, *)
    public static func decrypt(key:[UInt8], message:[UInt8], iv:[UInt8]) throws -> [UInt8] {
        var fixedKey = key
        if key.count == 16 {
            fixedKey += key[0..<8]
        }
        
        let data = Data(message)
        let dataLength = message.count
        
        let cryptLen = data.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLen)
        
        let keyLength              = size_t(key.count)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algorithm:  CCAlgorithm = UInt32(kCCAlgorithmAES)
        let options:   CCOptions   = UInt32(0)
        
        var numBytesEncrypted = 0
        
        let cryptStatus = fixedKey.withUnsafeBytes {keyBytes in
            message.withUnsafeBytes{ dataBytes in
                cryptData.withUnsafeMutableBytes{ cryptBytes in
                    CCCrypt(operation,
                            algorithm,
                            options,
                            keyBytes.baseAddress,
                            keyLength,
                            iv,
                            dataBytes.baseAddress,
                            dataLength,
                            cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                            cryptLen,
                            &numBytesEncrypted)
                    
                }
            }
        }
        
        if cryptStatus == kCCSuccess {
            cryptData.count = Int(numBytesEncrypted)
            
            return [UInt8](cryptData)
        } else {
            throw  NfcDigitalIdError.commonCryptoError(cryptStatus, "AES.decrypt")
        }
        return []
    }

    /// Decrypts a message using AES/ECB/NOPADDING with a specified key and initialisation vector
    /// - Parameter key: Key use to decrypt
    /// - Parameter message: Message to decrypt
    /// - Parameter iv: Initialisation vector
    @available(iOS 13, macOS 10.15, *)
    public static func encryptECB(key:[UInt8], message:[UInt8]) throws -> [UInt8] {

        let dataLength = message.count
        
        let cryptLen = message.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLen)
        
        let keyLength              = size_t(key.count)
        let operation: CCOperation = CCOperation(kCCEncrypt)
        let algorithm:  CCAlgorithm = CCAlgorithm(kCCAlgorithmAES)
        let options:   CCOptions   = CCOptions(kCCOptionECBMode)
        
        var numBytesEncrypted = 0
        
        let cryptStatus = key.withUnsafeBytes {keyBytes in
            message.withUnsafeBytes{ dataBytes in
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
        
        if cryptStatus == kCCSuccess {
            cryptData.count = Int(numBytesEncrypted)
            
            return [UInt8](cryptData)
        } else {
            throw  NfcDigitalIdError.commonCryptoError(cryptStatus, "AESECB.encrypt")
        }
        return []
    }
}
