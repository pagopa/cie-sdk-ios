//
//  PACE.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


import Foundation
internal import CNIOBoringSSL
import CryptoKit

enum PACE_DigestAlgorithms {
    case SHA1
    case SHA256
    
    
    func computeHash(dataElements: [Data]) -> [UInt8] {
        var hash : [UInt8]
        
        switch(self) {
        case .SHA1:
            var hasher = Insecure.SHA1()
            for d in dataElements {
                hasher.update( data:d )
            }
            hash = Array(hasher.finalize())
            break
        case .SHA256:
            var hasher = CryptoKit.SHA256()
            for d in dataElements {
                hasher.update( data:d )
            }
            hash = Array(hasher.finalize())
            break
        }
        
        return hash
    }
}