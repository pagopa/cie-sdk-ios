//
//  DERObject.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import SwiftASN1

class DERObject {
    let node: ASN1Node
    
    init(data: [UInt8]) throws {
        self.node = try DER.parse(data.removeTrailingZeros())
    }
    
    func getPrimitive(from node: ASN1Node) throws -> [UInt8] {
        switch(node.content) {
            case .primitive(let value) :
                return value.map({$0})
            default:
                throw ASN1Error.invalidASN1Object(reason: "no primitive value")
        }
    }
}
