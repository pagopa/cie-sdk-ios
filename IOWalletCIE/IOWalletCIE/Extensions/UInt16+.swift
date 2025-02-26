//
//  UInt16+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

extension UInt16 {
    
    var low: UInt8 {
        UInt8(self & 0xFF)
    }
    
    var high: UInt8 {
        UInt8((self >> 8) & 0xFF)
    }
}
