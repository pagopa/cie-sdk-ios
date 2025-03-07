//
//  BoringSSLRSA.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import CNIOBoringSSL
import Foundation

class BoringSSLRSA {
    
    var modulus: [UInt8]
    var exponent: [UInt8]
    var keyPriv: OpaquePointer!
    
    
    init(modulus: [UInt8], exponent: [UInt8]) throws {
        self.modulus = modulus
        self.exponent = exponent
        
        let keySize = modulus.count
        
        var n = CNIOBoringSSL_BN_new()
        var e = CNIOBoringSSL_BN_new()
        let d = CNIOBoringSSL_BN_new()
        
        modulus.withUnsafeBytes({
            modulusPtr in
            
            n = CNIOBoringSSL_BN_bin2bn(modulusPtr.baseAddress, modulus.count, n)
        })
        
        exponent.withUnsafeBytes({
            exponentPtr in
            
            e = CNIOBoringSSL_BN_bin2bn(exponentPtr.baseAddress, exponent.count, e)
        })
        
       
        keyPriv = CNIOBoringSSL_RSA_new_public_key_large_e(n, e)
        
        let sslError = CNIOBoringSSL_ERR_get_error()
        
        if (sslError != 0) {
            throw NfcDigitalIdError.sslError(sslError, "RSA")
        }
        
    }
    
    func free() {
        CNIOBoringSSL_RSA_free(keyPriv)
    }
    
    func pure(_ data: [UInt8]) throws -> [UInt8] {
        let outSize = CNIOBoringSSL_RSA_size(keyPriv)
        
        let out = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(outSize))
        
        return try [UInt8](data.withUnsafeBytes({
            dataPtr in
            let signSize = CNIOBoringSSL_RSA_public_encrypt(data.count, dataPtr.baseAddress, out, keyPriv, RSA_NO_PADDING)
            
            if (signSize != modulus.count) {
                let sslError = CNIOBoringSSL_ERR_get_error()
                
                if (sslError != 0) {
                    throw NfcDigitalIdError.sslError(sslError, "RSA")
                }
            }
            
            return Data.init(bytes: out, count: Int(outSize))
        }))
    }
}
