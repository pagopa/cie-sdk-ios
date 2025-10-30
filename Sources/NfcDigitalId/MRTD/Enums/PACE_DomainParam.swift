//
//  PACE.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


import Foundation
import OSLog
internal import CNIOBoringSSL

enum PACE_DomainParam : Int {
    // Standardized domain parameters. Based on Table 6.
    
    case PARAM_ID_GFP_1024_160 = 0
    case PARAM_ID_GFP_2048_224 = 1
    case PARAM_ID_GFP_2048_256 = 2
    case PARAM_ID_ECP_NIST_P192_R1 = 8
    case PARAM_ID_ECP_BRAINPOOL_P192_R1 = 9
    case PARAM_ID_ECP_NIST_P224_R1 = 10
    case PARAM_ID_ECP_BRAINPOOL_P224_R1 = 11
    case PARAM_ID_ECP_NIST_P256_R1 = 12
    case PARAM_ID_ECP_BRAINPOOL_P256_R1 = 13
    case PARAM_ID_ECP_BRAINPOOL_P320_R1 = 14
    case PARAM_ID_ECP_NIST_P384_R1 = 15
    case PARAM_ID_ECP_BRAINPOOL_P384_R1 = 16
    case PARAM_ID_ECP_BRAINPOOL_P512_R1 = 17
    case PARAM_ID_ECP_NIST_P521_R1 = 18
    
    func toParameterSpec() -> Int32 {
        switch (self) {
        case .PARAM_ID_GFP_1024_160:
                return 0 // "rfc5114_1024_160";
        case .PARAM_ID_GFP_2048_224:
                return 1 // "rfc5114_2048_224";
        case .PARAM_ID_GFP_2048_256:
                return 2 // "rfc5114_2048_256";
        case .PARAM_ID_ECP_NIST_P192_R1:
                return NID_X9_62_prime192v1 // "secp192r1";
        case .PARAM_ID_ECP_NIST_P224_R1:
                return NID_secp224r1 // "secp224r1";
        case .PARAM_ID_ECP_NIST_P256_R1:
                return NID_X9_62_prime256v1 //"secp256r1";
        case .PARAM_ID_ECP_NIST_P384_R1:
                return NID_secp384r1 // "secp384r1";
        case .PARAM_ID_ECP_BRAINPOOL_P192_R1:
                return NID_brainpoolP192r1 //"brainpoolp192r1";
        case .PARAM_ID_ECP_BRAINPOOL_P224_R1:
                return NID_brainpoolP224r1 // "brainpoolp224r1";
        case .PARAM_ID_ECP_BRAINPOOL_P256_R1:
                return NID_brainpoolP256r1 // "brainpoolp256r1";
        case .PARAM_ID_ECP_BRAINPOOL_P320_R1:
                return NID_brainpoolP320r1 //"brainpoolp320r1";
        case .PARAM_ID_ECP_BRAINPOOL_P384_R1:
                return NID_brainpoolP384r1 //"brainpoolp384r1";
        case .PARAM_ID_ECP_BRAINPOOL_P512_R1:
                return NID_brainpoolP512r1 //"";
        case .PARAM_ID_ECP_NIST_P521_R1:
                return NID_secp521r1 //"secp224r1";
        }
    }
}
