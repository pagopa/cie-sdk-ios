//
//  DiffieHellmanParameterDER.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//



internal import SwiftASN1

class DiffieHellmanParameterDER : DERObject {
    var value: [UInt8] {
        get throws {
            return try DER.explicitlyTagged(node, tagNumber: Constants.rootId.tagNumber, tagClass: Constants.rootId.tagClass) {
                root in
                
                return try DER.explicitlyTagged(root, tagNumber: Constants.containerId.tagNumber, tagClass: Constants.containerId.tagClass) {
                    container in
                    
                    return try DER.explicitlyTagged(container, tagNumber: Constants.valueContainerId.tagNumber, tagClass: Constants.valueContainerId.tagClass) {
                        valueContainer in
                        
                        return try getPrimitive(from: valueContainer)
                    }
                    
                }
            }
        }
    }
    
}
