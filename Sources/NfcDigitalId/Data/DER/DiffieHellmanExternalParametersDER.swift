//
//  DiffieHellmanExternalParametersDER.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//



internal import SwiftASN1

class DiffieHellmanExternalParametersDER : DERObject {
    var value: DiffieHellmanExternalParameters {
        get throws {
            return try DER.explicitlyTagged(node, tagNumber: Constants.rootId.tagNumber, tagClass: Constants.rootId.tagClass) {
                root in
                
                return try DER.explicitlyTagged(root, tagNumber: Constants.securityContainer.tagNumber, tagClass: Constants.securityContainer.tagClass) {
                    container in
                    
                    return try DER.set(container, identifier: Constants.keyManagementContainer) {
                        values in
                        
                        var modulus: [UInt8] = []
                        var exp: [UInt8] = []
                        var certificateHolderAuth: [UInt8] = []
                        var certificateHolderRef: [UInt8] = []
                        
                        
                        var value = values.next()
                        
                        while(value != nil) {
                            if let _value = value {
                                if _value.identifier == Constants.modulus {
                                    modulus = try getPrimitive(from: _value)
                                }
                                else if _value.identifier == Constants.exponent {
                                    exp = try getPrimitive(from: _value)
                                }
                                else if _value.identifier == Constants.certificateHolderAuthorization {
                                    certificateHolderAuth = try getPrimitive(from: _value)
                                }
                                else if _value.identifier == Constants.certificateHolderReference {
                                    certificateHolderRef = try getPrimitive(from: _value)
                                }
                            }
                            value = values.next()
                        }
                        
                        modulus = modulus.removeLeadingZeros().map({$0})
                        exp = exp.removeLeadingZeros().map({$0})
                        
                        return DiffieHellmanExternalParameters(modulus: modulus, exponent: exp, certificateHolderAuthorization: certificateHolderAuth, certificateHolderReference: certificateHolderRef)
                    }
                }
            }
        }
    }
}
