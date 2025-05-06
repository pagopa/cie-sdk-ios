//
//  UInt16+.swift
//  CieSDK
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
    
    init(low: UInt8, high: UInt8) {
        self = (UInt16(high) << 8) | UInt16(low);
    }
}
