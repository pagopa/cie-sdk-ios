//
//  BoringSSLEVP_PKEY.swift
//  CieSDK
//
//  Created by antoniocaparello on 25/08/25.
//
internal import CNIOBoringSSL

class BoringSSLEVP_PKEY {
    internal var ptr: OpaquePointer!
    
    init(ptr: OpaquePointer) {
        self.ptr = ptr
    }
    
    static func fromParams(params: OpaquePointer) throws -> BoringSSLEVP_PKEY {
        var ephKeyPair : OpaquePointer? = nil
        let pctx = CNIOBoringSSL_EVP_PKEY_CTX_new(params, nil)
        CNIOBoringSSL_EVP_PKEY_keygen_init(pctx)
        CNIOBoringSSL_EVP_PKEY_keygen(pctx, &ephKeyPair)
        CNIOBoringSSL_EVP_PKEY_CTX_free(pctx)
        
        guard let ephemeralKeyPair = ephKeyPair else {
            throw NfcDigitalIdError.paceError("Unable to get create ephermeral key pair")
        }
        
        // We've finished with the ephemeralParams now - we can now free it
        CNIOBoringSSL_EVP_PKEY_free(params)
        
        return BoringSSLEVP_PKEY(ptr: ephemeralKeyPair)
    }
    
    static func from(pubKeyData: [UInt8], params: OpaquePointer) -> BoringSSLEVP_PKEY? {
        
        let keyType = CNIOBoringSSL_EVP_PKEY_base_id(params)
        
        if keyType == EVP_PKEY_DH {
            return BoringSSLEVP_PKEY_DH.init(pubKeyData: pubKeyData, params: params)
        }
        
        if keyType == EVP_PKEY_EC {
            return BoringSSLEVP_PKEY_EC.init(pubKeyData: pubKeyData, params: params)
        }
        
        return nil
    }
    
    func getPublicKeyData() -> [UInt8]? {
        return value?.getPublicKeyData()
    }
    
    func getPrivateKeyData() -> [UInt8]? {
        return value?.getPrivateKeyData()
    }
    
    func computeSharedSecret(publicKey: BoringSSLEVP_PKEY) -> [UInt8]? {
        return value?.computeSharedSecret(publicKey: publicKey)
    }
    
    var keyType: Int32 {
        return CNIOBoringSSL_EVP_PKEY_base_id(ptr)
    }
    
    private var value: BoringSSLEVP_PKEY? {
        if keyType == EVP_PKEY_DH {
            return BoringSSLEVP_PKEY_DH(ptr: ptr)
        }
        
        if keyType == EVP_PKEY_EC {
            return BoringSSLEVP_PKEY_EC(ptr: ptr)
        }
        
        return nil
    }
    
    func free() {
        CNIOBoringSSL_EVP_PKEY_free(ptr)
        ptr = nil
    }
    
    func doMappingAgreement(ciePublicKeyData: [UInt8], nonce: UnsafeMutablePointer<BIGNUM> ) throws -> BoringSSLEVP_PKEY {
        return try value!.doMappingAgreement(ciePublicKeyData: ciePublicKeyData, nonce: nonce)
    }
}
