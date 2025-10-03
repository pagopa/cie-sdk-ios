//
//  BoringSSLEVP_PKEY_DH.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


internal import CNIOBoringSSL

class BoringSSLEVP_PKEY_DH : BoringSSLEVP_PKEY {
    
    override init(ptr: OpaquePointer) {
        super.init(ptr: ptr)
    }
    
    convenience init?(pubKeyData: [UInt8], params: OpaquePointer) {
        var pubKey : OpaquePointer?
        
        let dhKey = CNIOBoringSSL_DH_new()
        
        defer {
            CNIOBoringSSL_DH_free(dhKey)
        }
        
        // We don't free this as its part of the key!
        let bn = CNIOBoringSSL_BN_bin2bn(pubKeyData, pubKeyData.count, nil)
        CNIOBoringSSL_DH_set0_key(dhKey, bn, nil)
        
        pubKey = CNIOBoringSSL_EVP_PKEY_new()
        guard CNIOBoringSSL_EVP_PKEY_set1_DH(pubKey, dhKey) == 1 else {
            return nil
        }
        
        guard let pubKey = pubKey else {
            return nil
        }
        
        
        self.init(ptr: pubKey)
    }
    
    override func getPrivateKeyData() -> [UInt8]? {
        var data : [UInt8] = []
        
        guard let dh = CNIOBoringSSL_EVP_PKEY_get0_DH(ptr) else {
            return nil
        }
        
        
        var dhPrivKey : UnsafePointer<BIGNUM>?
        CNIOBoringSSL_DH_get0_key(dh, nil, &dhPrivKey)
        
        let nrBytes = (CNIOBoringSSL_BN_num_bits(dhPrivKey)+7)/8
        data = [UInt8](repeating: 0, count: Int(nrBytes))
        _ = CNIOBoringSSL_BN_bn2bin(dhPrivKey, &data)
        
        return data
    }
    
    override func getPublicKeyData() -> [UInt8]? {
        var data : [UInt8] = []
        
        guard let dh = CNIOBoringSSL_EVP_PKEY_get0_DH(ptr) else {
            return nil
        }
        
        var dhPubKey : UnsafePointer<BIGNUM>?
        CNIOBoringSSL_DH_get0_key(dh, &dhPubKey, nil)
        
        let nrBytes = (CNIOBoringSSL_BN_num_bits(dhPubKey)+7)/8
        data = [UInt8](repeating: 0, count: Int(nrBytes))
        _ = CNIOBoringSSL_BN_bn2bin(dhPubKey, &data)
        
        return data
    }
    
    override func computeSharedSecret(publicKey: BoringSSLEVP_PKEY) -> [UInt8]? {
        var secret : [UInt8]
        // Get bn for public key
        let dh = CNIOBoringSSL_EVP_PKEY_get1_DH(ptr);
        
        let dh_pub = CNIOBoringSSL_EVP_PKEY_get1_DH(publicKey.ptr)
        var bn = UnsafePointer(CNIOBoringSSL_BN_new())
        CNIOBoringSSL_DH_get0_key( dh_pub, &bn, nil )
        
        secret = [UInt8](repeating: 0, count: Int(CNIOBoringSSL_DH_size(dh)))
        
        let _ = CNIOBoringSSL_DH_compute_key(&secret, bn, dh);
        
        return secret
    }
    
    
    /// Does the DH key Mapping agreement
    /// - Parameter ciePublicKeyData - byte array containing the publick key read from the passport
    /// - Parameter nonce - Pointer to an BIGNUM structure containing the unencrypted nonce
    /// - Returns the EVP_PKEY containing the mapped ephemeral parameters
    override func doMappingAgreement(ciePublicKeyData: [UInt8], nonce: UnsafeMutablePointer<BIGNUM> ) throws -> BoringSSLEVP_PKEY {
        guard let dh_mapping_key = CNIOBoringSSL_EVP_PKEY_get1_DH(ptr) else {
            // Error
            throw NfcDigitalIdError.paceError("DH - Unable to get DH mapping key" )
        }
        
        // Compute the shared secret using the mapping key and the passports public mapping key
        let bn = CNIOBoringSSL_BN_bin2bn(ciePublicKeyData, ciePublicKeyData.count, nil)
        defer { CNIOBoringSSL_BN_free( bn ) }
        
        var secret = [UInt8](repeating: 0, count: Int(CNIOBoringSSL_DH_size(dh_mapping_key)))
        CNIOBoringSSL_DH_compute_key( &secret, bn, dh_mapping_key)
        
        // Convert the secret to a bignum
        let bn_h = CNIOBoringSSL_BN_bin2bn(secret, secret.count, nil)
        defer { CNIOBoringSSL_BN_clear_free(bn_h) }
        
        // Initialize ephemeral parameters with parameters from the mapping key
        guard let ephemeral_key = CNIOBoringSSL_DHparams_dup(dh_mapping_key) else {
            // Error
            throw NfcDigitalIdError.paceError("DH - Unable to get initialise ephemeral parameters from DH mapping key")
        }
        
        defer {
            CNIOBoringSSL_DH_free(ephemeral_key)
        }
        
        var p : UnsafePointer<BIGNUM>? = nil
        var q : UnsafePointer<BIGNUM>? = nil
        var g : UnsafePointer<BIGNUM>? = nil
        CNIOBoringSSL_DH_get0_pqg(dh_mapping_key, &p, &q, &g)
        
        // map to new generator
        guard let bn_g = CNIOBoringSSL_BN_new() else {
            throw NfcDigitalIdError.paceError("DH - Unable to create bn_g" )
        }
        
        defer {
            CNIOBoringSSL_BN_free(bn_g)
        }
        
        guard let new_g = CNIOBoringSSL_BN_new() else {
            throw NfcDigitalIdError.paceError("DH - Unable to create new_g" )
        }
        
        defer {
            CNIOBoringSSL_BN_free(new_g)
        }
        
        // bn_g = g^nonce mod p
        // ephemeral_key->g = bn_g mod p * h  => (g^nonce mod p) * h mod p
        let bn_ctx = CNIOBoringSSL_BN_CTX_new()
        guard CNIOBoringSSL_BN_mod_exp(bn_g, g, nonce, p, bn_ctx) == 1,
              CNIOBoringSSL_BN_mod_mul(new_g, bn_g, bn_h, p, bn_ctx) == 1 else {
            // Error
            throw NfcDigitalIdError.paceError("DH - Failed to generate new parameters" )
        }
        
        guard CNIOBoringSSL_DH_set0_pqg(ephemeral_key, CNIOBoringSSL_BN_dup(p), CNIOBoringSSL_BN_dup(q), CNIOBoringSSL_BN_dup(new_g)) == 1 else {
            // Error
            throw NfcDigitalIdError.paceError("DH - Unable to set DH pqg paramerters" )
        }
        
        // Set the ephemeral params
        guard let ephemeralParams = CNIOBoringSSL_EVP_PKEY_new() else {
            throw NfcDigitalIdError.paceError("DH - Unable to create ephemeral params" )
        }
        
        guard CNIOBoringSSL_EVP_PKEY_set1_DH(ephemeralParams, ephemeral_key) == 1 else {
            // Error
            CNIOBoringSSL_EVP_PKEY_free( ephemeralParams )
            throw NfcDigitalIdError.paceError("DH - Unable to set ephemeral parameters" )
        }
        
        return try BoringSSLEVP_PKEY.fromParams(params: ephemeralParams)
    }
}
