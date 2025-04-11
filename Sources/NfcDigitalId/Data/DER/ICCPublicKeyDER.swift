//
//  ICCPublicKeyDER.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//


internal import SwiftASN1

class ICCPublicKeyDER : DERObject {
    var value: RSAKeyValue {
        get throws {
            let modulus = try DER.explicitlyTagged(node, tagNumber: Constants.iccRootId.tagNumber, tagClass: Constants.iccRootId.tagClass) {
                root in
                
                return try getPrimitive(from: root)
            }
            return RSAKeyValue(modulus: modulus, exponent: nil)
        }
    }
}
