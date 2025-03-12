//
//  DiffieHellmanExternalParameters.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

struct DiffieHellmanExternalParameters {
    let modulus: [UInt8]
    let exponent: [UInt8]
    let certificateHolderAuthorization: [UInt8]
    let certificateHolderReference: [UInt8]
    
    var publicKey: RSAKeyValue {
        return RSAKeyValue(modulus: modulus, exponent: exponent)
    }
    
    var privateKey: RSAKeyValue {
        return RSAKeyValue(modulus: modulus, exponent: Constants.DH_EXT_AUTH_PRIVATE_EXP)
    }
}
