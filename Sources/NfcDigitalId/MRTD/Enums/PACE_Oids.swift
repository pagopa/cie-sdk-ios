//
//  PACE.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


import Foundation
internal import CNIOBoringSSL
import CryptoKit

enum PACE_Oids {
    case PACE_DH_GM_3DES_CBC_CBC
    
    case PACE_DH_GM_AES_CBC_CMAC_128
    case PACE_DH_GM_AES_CBC_CMAC_192
    case PACE_DH_GM_AES_CBC_CMAC_256
    
    
    case PACE_ECDH_GM_3DES_CBC_CBC
    case PACE_ECDH_GM_AES_CBC_CMAC_128
    case PACE_ECDH_GM_AES_CBC_CMAC_192
    case PACE_ECDH_GM_AES_CBC_CMAC_256
    
    static func from(rawOid: String) -> PACE_Oids? {
        switch(rawOid) {
            
        case PACE_Oids.ID_PACE_DH_GM_3DES_CBC_CBC:
            return .PACE_DH_GM_3DES_CBC_CBC
            
        case PACE_Oids.ID_PACE_DH_GM_AES_CBC_CMAC_128:
            return .PACE_DH_GM_AES_CBC_CMAC_128
        
        case PACE_Oids.ID_PACE_DH_GM_AES_CBC_CMAC_192:
            return .PACE_DH_GM_AES_CBC_CMAC_192

        case PACE_Oids.ID_PACE_DH_GM_AES_CBC_CMAC_256:
            return .PACE_DH_GM_AES_CBC_CMAC_256

        case PACE_Oids.ID_PACE_ECDH_GM_3DES_CBC_CBC:
            return .PACE_ECDH_GM_3DES_CBC_CBC

        case PACE_Oids.ID_PACE_ECDH_GM_AES_CBC_CMAC_128:
            return .PACE_ECDH_GM_AES_CBC_CMAC_128

        case PACE_Oids.ID_PACE_ECDH_GM_AES_CBC_CMAC_192:
            return .PACE_ECDH_GM_AES_CBC_CMAC_192

        case PACE_Oids.ID_PACE_ECDH_GM_AES_CBC_CMAC_256:
            return .PACE_ECDH_GM_AES_CBC_CMAC_256

        default:
            return nil
        }
    }
    
    var rawOid: String {
        switch(self) {
            
            case .PACE_DH_GM_3DES_CBC_CBC:
            return PACE_Oids.ID_PACE_DH_GM_3DES_CBC_CBC
            
            case .PACE_DH_GM_AES_CBC_CMAC_128:
            return PACE_Oids.ID_PACE_DH_GM_AES_CBC_CMAC_128
        
            case .PACE_DH_GM_AES_CBC_CMAC_192:
            return PACE_Oids.ID_PACE_DH_GM_AES_CBC_CMAC_192
        
            case .PACE_DH_GM_AES_CBC_CMAC_256:
            return PACE_Oids.ID_PACE_DH_GM_AES_CBC_CMAC_256
        
            case .PACE_ECDH_GM_3DES_CBC_CBC:
            return PACE_Oids.ID_PACE_ECDH_GM_3DES_CBC_CBC
            
            case .PACE_ECDH_GM_AES_CBC_CMAC_128:
            return PACE_Oids.ID_PACE_ECDH_GM_AES_CBC_CMAC_128
        
            case .PACE_ECDH_GM_AES_CBC_CMAC_192:
            return PACE_Oids.ID_PACE_ECDH_GM_AES_CBC_CMAC_192
        
            case .PACE_ECDH_GM_AES_CBC_CMAC_256:
            return PACE_Oids.ID_PACE_ECDH_GM_AES_CBC_CMAC_256
        }
    }
    
    var keyLength: Int {
        switch(self) {
            case .PACE_DH_GM_3DES_CBC_CBC,
                .PACE_DH_GM_AES_CBC_CMAC_128,
                .PACE_ECDH_GM_3DES_CBC_CBC,
                .PACE_ECDH_GM_AES_CBC_CMAC_128:
            return 128
            
            case .PACE_DH_GM_AES_CBC_CMAC_192,
                .PACE_ECDH_GM_AES_CBC_CMAC_192:
            return 192
            
            case .PACE_DH_GM_AES_CBC_CMAC_256,
                .PACE_ECDH_GM_AES_CBC_CMAC_256:
            return 256
        }
    }
    
    var keyAgreement: PACE_KeyAgreementAlgorithms {
        switch(self) {
            case .PACE_DH_GM_3DES_CBC_CBC,
                .PACE_DH_GM_AES_CBC_CMAC_128,
                .PACE_DH_GM_AES_CBC_CMAC_192,
                .PACE_DH_GM_AES_CBC_CMAC_256:
            return .DH
            
            case .PACE_ECDH_GM_3DES_CBC_CBC,
                .PACE_ECDH_GM_AES_CBC_CMAC_128,
                .PACE_ECDH_GM_AES_CBC_CMAC_192,
                .PACE_ECDH_GM_AES_CBC_CMAC_256:
            return .ECDH
            
        }
    }
    
    var cipherAlgorithm: PACE_CipherAlgorithms {
        switch(self) {
            case .PACE_DH_GM_AES_CBC_CMAC_128,
                .PACE_DH_GM_AES_CBC_CMAC_192,
                .PACE_DH_GM_AES_CBC_CMAC_256,
                .PACE_ECDH_GM_AES_CBC_CMAC_128,
                .PACE_ECDH_GM_AES_CBC_CMAC_192,
                .PACE_ECDH_GM_AES_CBC_CMAC_256:
            return .AES
        case .PACE_DH_GM_3DES_CBC_CBC,
                .PACE_ECDH_GM_3DES_CBC_CBC:
            return .DESede
        }
    }
    
    var digestAlgorithm: PACE_DigestAlgorithms {
        switch(self) {
        case .PACE_DH_GM_3DES_CBC_CBC,
                .PACE_ECDH_GM_3DES_CBC_CBC,
                .PACE_DH_GM_AES_CBC_CMAC_128,
                .PACE_ECDH_GM_AES_CBC_CMAC_128:
            return .SHA1
        case .PACE_DH_GM_AES_CBC_CMAC_192,
                .PACE_DH_GM_AES_CBC_CMAC_256,
                .PACE_ECDH_GM_AES_CBC_CMAC_192,
                .PACE_ECDH_GM_AES_CBC_CMAC_256:
            return .SHA256
        }
    }
    
    var mappingType: PACE_MappingType {
        switch(self) {
        case .PACE_DH_GM_3DES_CBC_CBC,
                .PACE_DH_GM_AES_CBC_CMAC_128,
                .PACE_DH_GM_AES_CBC_CMAC_192,
                .PACE_DH_GM_AES_CBC_CMAC_256,
                .PACE_ECDH_GM_3DES_CBC_CBC,
                .PACE_ECDH_GM_AES_CBC_CMAC_128,
                .PACE_ECDH_GM_AES_CBC_CMAC_192,
                .PACE_ECDH_GM_AES_CBC_CMAC_256:
            return .GM
        }
    }
    
    
    // PACE OIDS
    static let ID_BSI = "0.4.0.127.0.7"
    static let ID_PACE = ID_BSI + ".2.2.4"
    static let ID_PACE_DH_GM = ID_PACE + ".1"
    static let ID_PACE_DH_GM_3DES_CBC_CBC = ID_PACE_DH_GM + ".1"; // 0.4.0.127.0.7.2.2.4.1.1, id-PACE-DH-GM-3DES-CBC-CBC

    static let ID_PACE_DH_GM_AES_CBC_CMAC_128 = ID_PACE_DH_GM + ".2"; // 0.4.0.127.0.7.2.2.4.1.2, id-PACE-DH-GM-AES-CBC-CMAC-128
    static let ID_PACE_DH_GM_AES_CBC_CMAC_192 = ID_PACE_DH_GM + ".3"; // 0.4.0.127.0.7.2.2.4.1.3, id-PACE-DH-GM-AES-CBC-CMAC-192
    static let ID_PACE_DH_GM_AES_CBC_CMAC_256 = ID_PACE_DH_GM + ".4"; // 0.4.0.127.0.7.2.2.4.1.4, id-PACE-DH-GM-AES-CBC-CMAC-256
    
    static let ID_PACE_ECDH_GM = ID_PACE + ".2"
    static let ID_PACE_ECDH_GM_3DES_CBC_CBC = ID_PACE_ECDH_GM + ".1"; // 0.4.0.127.0.7.2.2.4.2.1, id-PACE-ECDH-GM-3DES-CBC-CBC
    
    static let ID_PACE_ECDH_GM_AES_CBC_CMAC_128 = ID_PACE_ECDH_GM + ".2"; // 0.4.0.127.0.7.2.2.4.2.2, id-PACE-ECDH-GM-AES-CBC-CMAC-128
    static let ID_PACE_ECDH_GM_AES_CBC_CMAC_192 = ID_PACE_ECDH_GM + ".3"; // 0.4.0.127.0.7.2.2.4.2.3, id-PACE-ECDH-GM-AES-CBC-CMAC-192
    static let ID_PACE_ECDH_GM_AES_CBC_CMAC_256 = ID_PACE_ECDH_GM + ".4"; // 0.4.0.127.0.7.2.2.4.2.4, id-PACE-ECDH-GM-AES-CBC-CMAC-256
}


extension PACE_Oids {
    /// Caller is required to free the returned EVP_PKEY value
    public func createMappingKey(parameterSpec: Int32) throws -> BoringSSLEVP_PKEY {
        // This will get freed later
        let mappingKey : OpaquePointer = CNIOBoringSSL_EVP_PKEY_new()
        
        switch try self.keyAgreement {
        case .DH:
                var dhKey : OpaquePointer? = nil
                switch parameterSpec {
                    case 0:
                    dhKey = RFC5114.DH_get_1024_160()
                    case 1:
                    dhKey = RFC5114.DH_get_2048_224()
                    case 2:
                    dhKey = RFC5114.DH_get_2048_256()
                    default:
                        // Error
                        break
                }
            
                guard dhKey != nil else {
                    throw NfcDigitalIdError.paceError("Unable to create DH mapping key")
                }
            
                defer{ CNIOBoringSSL_DH_free( dhKey ) }
                
                CNIOBoringSSL_DH_generate_key(dhKey)
                CNIOBoringSSL_EVP_PKEY_set1_DH(mappingKey, dhKey)
            
        case .ECDH:
                guard let ecKey = CNIOBoringSSL_EC_KEY_new_by_curve_name(parameterSpec) else {
                    throw NfcDigitalIdError.paceError("Unable to create EC mapping key")
                 }
                defer{ CNIOBoringSSL_EC_KEY_free( ecKey ) }
                
                CNIOBoringSSL_EC_KEY_generate_key(ecKey)
                CNIOBoringSSL_EVP_PKEY_set1_EC_KEY(mappingKey, ecKey)
        }

        return BoringSSLEVP_PKEY(ptr: mappingKey)
    }
}
