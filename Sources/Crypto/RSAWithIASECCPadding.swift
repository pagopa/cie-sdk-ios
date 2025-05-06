//
//  RSAWithIASECCPadding.swift
//  CieSDK
//
//  Created by Antonio Caparello on 07/03/25.
//


struct RSAWithIASECCPadding {
    
    static func decrypt(keyValue: RSAKeyValue, data: [UInt8], hashSize: Int) throws -> IASECCPadding {
        return try decrypt(modulus: keyValue.modulus, exponent: keyValue.exponent!, data: data, hashSize: hashSize)
    }
    
    private static func decrypt(modulus: [UInt8], exponent: [UInt8], data: [UInt8], hashSize: Int) throws -> IASECCPadding {
        let rsa = try BoringSSLRSA(
            modulus: modulus, exponent: exponent)
        
        defer {
            rsa.free()
        }
        
        return try IASECCPadding(blob: rsa.pure(data), hashSize: hashSize)
    }
    
    static func encrypt(keyValue: RSAKeyValue, blob: IASECCPadding) throws -> [UInt8] {
        return try encrypt(modulus: keyValue.modulus, exponent: keyValue.exponent!, blob: blob)
    }
    
    private static func encrypt(modulus: [UInt8], exponent: [UInt8], blob: IASECCPadding) throws -> [UInt8] {
        let rsa = try BoringSSLRSA(
            modulus: modulus, exponent: exponent)
        
        defer {
            rsa.free()
        }
        
        return try rsa.pure(blob.encode())
    }
}
