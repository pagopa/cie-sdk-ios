//
//  CardAccessDER.swift
//  CieSDK
//
//  Created by antoniocaparello on 25/08/25.
//

internal import SwiftASN1


class CardAccessDER : DERObject {
    
    var paceInfo: PACEInfo? {
        get {
            return try? DER.sequence(node, identifier: Constants.publicKeyInfoId) {
                sequence in
                
                while(true) {
                    guard let item = sequence.next() else {
                        break
                    }
                    
                    guard let paceInfo = try PACEInfoDER(node: item).paceInfo else {
                        continue
                    }
                    
                    return paceInfo
                }
                
                return nil
            }
        }
    }
    
    // SecurityInfos ::= SET of SecurityInfo
    // SecurityInfo ::= SEQUENCE {
    //    protocol OBJECT IDENTIFIER,
    //    requiredData ANY DEFINED BY protocol,
    //    optionalData ANY DEFINED BY protocol OPTIONAL
}

class PACEInfoDER : DERObject {
    
    var paceInfo: PACEInfo? {
        get throws {
            let items = try {
                return try DER.set(node, identifier: Constants.algorithmId) {
                    algorithm in
                    
                    var algorithmItems = [[UInt8]]()
                    
                    while(true) {
                        guard let algorithmItem = algorithm.next() else {
                            break
                        }
                        
                        algorithmItems.append(try DERObject.getPrimitive(from: algorithmItem))
                    }
                    
                    return algorithmItems
                }
            }();
            
            let oidBytes = items[0]
            
            let required = items[1]
            let requiredData = required.hexEncodedString
            
            let optionalData = (items.count > 2 ? items[2] : nil)?.hexEncodedString
            
            var oid = oidBytes.map({"\($0)"}).joined(separator: ".")
            
            if (!oid.starts(with: "0.")) {
                oid = "0." + oid
            }
            
            if let paceOid = PACE_Oids.from(rawOid: oid) {
                let version = Int(requiredData) ?? -1
                var parameterId : Int? = nil
                
                if let optionalData = optionalData {
                    parameterId = Int(optionalData, radix:16)
                }
                return PACEInfo(version: version, parameterId: parameterId, paceOid: paceOid);
            }
            else {
                throw NfcDigitalIdError.paceError("Not supported PACE OID: \(oid)")
            }
            
        }
    }
    
}





//
//class CardAccess {
//    public private(set) var securityInfos : [SecurityInfo] = [SecurityInfo]()
//    
//    var paceInfo : PACEInfo? {
//        get {
//            return (securityInfos.filter { ($0 as? PACEInfo) != nil }).first as? PACEInfo
//        }
//    }
//    
//    required init( _ data : [UInt8] ) throws {
//        let node = try DER.parse(data)
//        
//        try DER.sequence(node, identifier: Constants.publicKeyInfoId) {
//            sequence in
//            
//            while(true) {
//                guard let item = sequence.next() else {
//                    break
//                }
//                
//                guard let securityInfo = try SecurityInfo.parse(node: item) else {
//                    break
//                }
//                
//                securityInfos.append(securityInfo)
//            }
//        }
//    }
//}



class NonceDER : DERObject {
    var value: [UInt8] {
        get throws {
            return try DER.explicitlyTagged(node, tagNumber: Constants.nonceContainer.tagNumber, tagClass: Constants.nonceContainer.tagClass) {
                root in
                
                return try getPrimitive(from: root)
            }
        }
    }
}

class GeneralAuthenticationDER : DERObject {
    var value: [UInt8] {
        get throws {
            return try DER.explicitlyTagged(node, tagNumber: Constants.nonceContainer.tagNumber, tagClass: Constants.nonceContainer.tagClass) {
                root in
                
                return try getPrimitive(from: root)
            }
        }
    }
}

