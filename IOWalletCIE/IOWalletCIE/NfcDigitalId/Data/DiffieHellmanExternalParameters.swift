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
}
