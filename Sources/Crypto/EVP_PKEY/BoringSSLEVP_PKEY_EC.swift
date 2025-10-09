//
//  BoringSSLEVP_PKEY_EC.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


internal import CNIOBoringSSL

class BoringSSLEVP_PKEY_EC : BoringSSLEVP_PKEY {
    
    convenience init?(pubKeyData: [UInt8], params: OpaquePointer) {
        var pubKey : OpaquePointer?
        
        let ec = CNIOBoringSSL_EVP_PKEY_get1_EC_KEY(params)
        let group = CNIOBoringSSL_EC_KEY_get0_group(ec);
        let ecp = CNIOBoringSSL_EC_POINT_new(group);
        let key = CNIOBoringSSL_EC_KEY_new();
        
        defer {
            CNIOBoringSSL_EC_KEY_free(ec)
            CNIOBoringSSL_EC_POINT_free(ecp)
            CNIOBoringSSL_EC_KEY_free(key)
        }
        
        // Read EC_Point from public key data
        guard CNIOBoringSSL_EC_POINT_oct2point(group, ecp, pubKeyData, pubKeyData.count, nil) == 1,
              CNIOBoringSSL_EC_KEY_set_group(key, group) == 1,
              CNIOBoringSSL_EC_KEY_set_public_key(key, ecp) == 1 else {
            return nil
        }
        
        pubKey = CNIOBoringSSL_EVP_PKEY_new()
        
        guard CNIOBoringSSL_EVP_PKEY_set1_EC_KEY(pubKey, key) == 1 else {
            return nil
        }
        
        guard let pubKey = pubKey else {
            return nil
        }
        
        self.init(ptr: pubKey)
        
    }
    
    override func getPublicKeyData() -> [UInt8]? {
        var data : [UInt8] = []
        
        guard let ec = CNIOBoringSSL_EVP_PKEY_get0_EC_KEY(ptr),
              let ec_pub = CNIOBoringSSL_EC_KEY_get0_public_key(ec),
              let ec_group = CNIOBoringSSL_EC_KEY_get0_group(ec) else {
            return nil
        }
        
        let form = CNIOBoringSSL_EC_KEY_get_conv_form(ec)
        let len = CNIOBoringSSL_EC_POINT_point2oct(ec_group, ec_pub, form, nil, 0, nil)
        data = [UInt8](repeating: 0, count: Int(len))
        if len == 0 {
            return nil
        }
        _ = CNIOBoringSSL_EC_POINT_point2oct(ec_group, ec_pub, form, &data, len, nil)
        
        return data
    }
    
    override func computeSharedSecret(publicKey: BoringSSLEVP_PKEY) -> [UInt8]? {
        var secret : [UInt8]
        
        let ctx = CNIOBoringSSL_EVP_PKEY_CTX_new(ptr, nil)
        defer{ CNIOBoringSSL_EVP_PKEY_CTX_free(ctx) }
        
        if CNIOBoringSSL_EVP_PKEY_derive_init(ctx) != 1 {
            // error
            return nil
        }
        
        // Set the public key
        if CNIOBoringSSL_EVP_PKEY_derive_set_peer( ctx, publicKey.ptr ) != 1 {
            // error
            return nil
        }
        
        // get buffer length needed for shared secret
        var keyLen = 0
        if CNIOBoringSSL_EVP_PKEY_derive(ctx, nil, &keyLen) != 1 {
            // Error
            return nil
        }
        
        // Derive the shared secret
        secret = [UInt8](repeating: 0, count: keyLen)
        if CNIOBoringSSL_EVP_PKEY_derive(ctx, &secret, &keyLen) != 1 {
            // Error
            return nil
        }
        
        return secret
    }
    
    /// Does the ECDH key Mapping agreement
    /// - Parameter ciePublicKeyData - byte array containing the publick key read from the passport
    /// - Parameter nonce - Pointer to an BIGNUM structure containing the unencrypted nonce
    /// - Returns the EVP_PKEY containing the mapped ephemeral parameters
    override func doMappingAgreement(ciePublicKeyData: [UInt8], nonce: UnsafeMutablePointer<BIGNUM> ) throws -> BoringSSLEVP_PKEY {
        
        let ec_mapping_key = CNIOBoringSSL_EVP_PKEY_get1_EC_KEY(ptr)
        
        guard let group = CNIOBoringSSL_EC_GROUP_dup(CNIOBoringSSL_EC_KEY_get0_group(ec_mapping_key)) else {
            // Error
            throw NfcDigitalIdError.paceError("ECDH - Unable to get EC group" )
        }
        
        defer {
            CNIOBoringSSL_EC_GROUP_free(group)
        }
        
        guard let order = CNIOBoringSSL_BN_new() else {
            // Error
            throw NfcDigitalIdError.paceError("ECDH - Unable to create order bignum" )
        }
        
        defer {
            CNIOBoringSSL_BN_free( order )
        }
        
        guard let cofactor = CNIOBoringSSL_BN_new() else {
            // error
            throw NfcDigitalIdError.paceError("ECDH - Unable to create cofactor bignum" )
        }
        
        defer {
            CNIOBoringSSL_BN_free( cofactor )
        }
        
        guard CNIOBoringSSL_EC_GROUP_get_order(group, order, nil) == 1 ||
                CNIOBoringSSL_EC_GROUP_get_cofactor(group, cofactor, nil) == 1 else {
            // Handle error
            throw NfcDigitalIdError.paceError("ECDH - Unable to get order or cofactor from group" )
        }
        
        // Create the shared secret in the form of a ECPoint
        
        guard let sharedSecretMappingPoint = self.computeECDHMappingKeyPoint(privateKey: ptr, inputKey: ciePublicKeyData) else {
            // Error
            throw NfcDigitalIdError.paceError("ECDH - Failed to compute new shared secret mapping point from mapping key and passport public mapping key" )
        }
        defer { CNIOBoringSSL_EC_POINT_free( sharedSecretMappingPoint ) }
        
        // Map the nonce using Generic mapping to get the new parameters (inc a new generator)
        guard let newGenerater = CNIOBoringSSL_EC_POINT_new(group) else {
            throw NfcDigitalIdError.paceError("ECDH - Unable to create new mapping generator point" )
        }
        defer{ CNIOBoringSSL_EC_POINT_free(newGenerater) }
        
        // g = (generator * nonce) + (sharedSecretMappingPoint * 1)
        guard CNIOBoringSSL_EC_POINT_mul(group, newGenerater, nonce, sharedSecretMappingPoint, CNIOBoringSSL_BN_value_one(), nil) == 1 else {
            throw NfcDigitalIdError.paceError("ECDH - Failed to map nonce to get new generator params" )
        }
        
        // Initialize ephemeral parameters with parameters from the mapping key
        guard let ephemeralParams = CNIOBoringSSL_EVP_PKEY_new() else {
            throw NfcDigitalIdError.paceError("ECDH - Unable to create ephemeral params" )
        }
        
        let ephemeral_key = CNIOBoringSSL_EC_KEY_dup(ec_mapping_key)
        
        defer{
            CNIOBoringSSL_EC_KEY_free(ephemeral_key)
        }
        
        // configure the new EC_KEY
        guard CNIOBoringSSL_EVP_PKEY_set1_EC_KEY(ephemeralParams, ephemeral_key) == 1,
              CNIOBoringSSL_EC_GROUP_set_generator(group, newGenerater, order, cofactor) == 1,
              //CNIOBoringSSL_EC_GROUP_check(group, nil) == 1,
              CNIOBoringSSL_EC_KEY_set_group(ephemeral_key, group) == 1 else {
            // Error
            
            CNIOBoringSSL_EVP_PKEY_free( ephemeralParams )
            throw NfcDigitalIdError.paceError("ECDH - Unable to configure new ephemeral params" )
        }
        
        return try BoringSSLEVP_PKEY.fromParams(params: ephemeralParams)
    }
    
    /// Performs the ECDH PACE GM key agreement protocol by multiplying a private key with a public key
    /// - Parameters:
    ///   - key: an EVP_PKEY structure containng a ECDH private key
    ///   - inputKey: a public key
    /// - Returns: a new EC_POINT
    private func computeECDHMappingKeyPoint( privateKey : OpaquePointer, inputKey : [UInt8] ) -> OpaquePointer? {
        
        let ecdh = CNIOBoringSSL_EVP_PKEY_get1_EC_KEY(privateKey)
        
        defer {
            CNIOBoringSSL_EC_KEY_free(ecdh)
        }
        
        let privateECKey = CNIOBoringSSL_EC_KEY_get0_private_key(ecdh) // BIGNUM
        
        // decode public key
        guard let group = CNIOBoringSSL_EC_KEY_get0_group(ecdh) else {
            return nil
        }
        
        guard let ecp = CNIOBoringSSL_EC_POINT_new(group) else {
            return nil
        }
        
        defer {
            CNIOBoringSSL_EC_POINT_free(ecp)
        }
        
        guard CNIOBoringSSL_EC_POINT_oct2point(group, ecp, inputKey, inputKey.count,nil) != 0 else {
            return nil
        }
        
        // create our output point
        let output = CNIOBoringSSL_EC_POINT_new(group)
        
        // Multiply our private key with the passports public key to get a new point
        CNIOBoringSSL_EC_POINT_mul(group, output, nil, ecp, privateECKey, nil)
        
        return output
    }
}
