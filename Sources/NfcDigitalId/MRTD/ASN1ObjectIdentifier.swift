//
//  ASN1ObjectIdentifier.swift
//  CieSDK
//
//  Created by antoniocaparello on 26/08/25.
//

import Foundation
internal import CNIOBoringSSL
import CryptoKit


class ASN1ObjectIdentifier {
    private var _rawOid: String
    private var _oid: [UInt8]
    
    init(oid: String) {
        self._rawOid = oid
        let obj = CNIOBoringSSL_OBJ_txt2obj( oid.cString(using: .utf8), 1)
        let payloadLen = CNIOBoringSSL_i2d_ASN1_OBJECT(obj, nil)
        
        var data  = [UInt8](repeating: 0, count: Int(payloadLen))
        
        let _ = data.withUnsafeMutableBytes { (ptr) in
            var newPtr = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self)
            _ = CNIOBoringSSL_i2d_ASN1_OBJECT(obj, &newPtr)
        }
        
        self._oid = data
    }
    
    var oid: [UInt8] {
        return self._oid
    }
}
