//
//  DiffieHellmanParameters.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import CNIOBoringSSL

struct DiffieHellmanParameters {
    let g: [UInt8]
    let p: [UInt8]
    let q: [UInt8]
}

extension DiffieHellmanParameters {
    
    func DH() -> OpaquePointer? {
        guard let dh = CNIOBoringSSL_DH_new() else {
            return nil
        }
        
        let pBN = CNIOBoringSSL_BN_bin2bn(p, p.count, nil)
        let qBN = CNIOBoringSSL_BN_bin2bn(q, q.count, nil)
        let gBN = CNIOBoringSSL_BN_bin2bn(g, g.count, nil)
        
        if CNIOBoringSSL_DH_set0_pqg(dh, pBN, qBN, gBN) == 0 {
            CNIOBoringSSL_BN_free(pBN)
            CNIOBoringSSL_BN_free(qBN)
            CNIOBoringSSL_BN_free(gBN)
            CNIOBoringSSL_DH_free(dh)
            return nil
        }
        
        return dh
    }
    
}
