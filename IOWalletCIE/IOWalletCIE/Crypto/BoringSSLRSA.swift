//
//  BoringSSLRSA.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import CNIOBoringSSL

class BoringSSLRSA {
    
    var modulus: [UInt8]
    var exponent: [UInt8]
    var keyPriv: OpaquePointer!
    
    
    init(modulus: [UInt8], exponent: [UInt8]) {
        self.modulus = modulus
        self.exponent = exponent
        
        let keySize = modulus.count
        keyPriv = CNIOBoringSSL_RSA_new()
        
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
        
        CNIOBoringSSL_RSA_set0_key(keyPriv, n, e, d)
    }
    
    func free() {
        CNIOBoringSSL_RSA_free(keyPriv)
    }
    
    func pure(_ data: [UInt8]) -> [UInt8] {
        let outSize = CNIOBoringSSL_RSA_size(keyPriv)
        
        let out = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(outSize))
        
        return [UInt8](data.withUnsafeBytes({
            dataPtr in
            let signSize = CNIOBoringSSL_RSA_public_encrypt(data.count, dataPtr.baseAddress, out, keyPriv, RSA_NO_PADDING)
            
            if (signSize != modulus.count) {
                print("error?")
            }
            
            return Data.init(bytes: out, count: Int(outSize))
        }))
    }
}
