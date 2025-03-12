//
//  TDES.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//
import CommonCrypto
import Foundation

class TDES {
    
    @available(iOS 13, macOS 10.15, *)
    public static func encrypt(key:[UInt8], message:[UInt8], iv:[UInt8]) throws -> [UInt8] {
        var fixedKey = key
        if key.count == 16 {
            fixedKey += key[0..<8]
        }
        
        let dataLength = message.count
        
        let cryptLen = message.count + kCCBlockSize3DES
        var cryptData = Data(count: cryptLen)
        
        let keyLength              = size_t(kCCKeySize3DES)
        let operation: CCOperation = UInt32(kCCEncrypt)
        let algorithm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
        let options:   CCOptions   = UInt32(0)
        
        var numBytesEncrypted = 0
        
        let cryptStatus = fixedKey.withUnsafeBytes {keyBytes in
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
            throw  NfcDigitalIdError.commonCryptoError(cryptStatus, "TDES.encrypt")
        }
    }
    
    /// Decrypts a message using DES3 with a specified key and initialisation vector
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
        
        let cryptLen = data.count + kCCBlockSize3DES
        var cryptData = Data(count: cryptLen)
        
        let keyLength              = size_t(kCCKeySize3DES)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algorithm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
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
            throw  NfcDigitalIdError.commonCryptoError(cryptStatus, "TDES.decrypt")
        }
    }
}
