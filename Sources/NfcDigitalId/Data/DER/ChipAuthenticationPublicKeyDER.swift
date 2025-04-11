//
//  ChipAuthenticationPublicKeyDER.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//



internal import SwiftASN1

class ChipAuthenticationPublicKeyDER : DERObject {
    var value: RSAKeyValue {
        get throws {
            return try DER.sequence(node, identifier: .sequence) {
                sequence in
                
                let exponentValue: [UInt8]
                let modulusValue: [UInt8]
                
                let modulus = sequence.next()
                
                guard let modulus = modulus else {
                    throw ASN1Error.invalidASN1Object(reason: "no modulus")
                }
                
                modulusValue = try getPrimitive(from: modulus)
                
                let exponent = sequence.next()
                
                guard let exponent = exponent else {
                    throw ASN1Error.invalidASN1Object(reason: "no exponent")
                }
                
                exponentValue = try getPrimitive(from: exponent)
                
                
                return RSAKeyValue(modulus: modulusValue.removeLeadingZeros().map({$0}), exponent: exponentValue.removeLeadingZeros().map({$0}))
            }
        }
    }
}
